# Runtime Specification

> The runtime and executor extension specification for the EPIC.md Standard.
> **Version 0.5.0**

`EPIC-RUNTIME.md` defines the parts of EPIC that require executor support:
`hooks/`, `cron.d/`, `policy.yml`, and `runtime/`.

This document is normative. If a runtime feature is present in an epic, a
compliant executor MUST either honor it according to this document or surface
that it does not support that feature. It MUST NOT silently reinterpret runtime
features as mere advisory prose.

## Runtime Scope

This document covers:

* recurring execution through `cron.d/`
* event-triggered execution through `hooks/`
* autonomous-operation constraints in `policy.yml`
* non-portable executor metadata in `runtime/`
* lifecycle triggers that depend on executor behavior

Core file precedence, reserved fields, and resumption are defined in
`EPIC-STANDARD.md`.

## Runtime Compatibility Rules

* `state/core.json` is authoritative over `state.json` whenever `state/` exists.
* Agents MUST read `policy.yml` at activation time when it exists and treat it
  as hard constraints.
* SKILL.md instructions MAY guide interactive work and MAY emulate the spirit of
  a runtime reaction when no runtime feature exists, but they MUST NOT replace,
  mask, or override configured runtime features.
* If an executor does not support a runtime feature used by the epic, it SHOULD
  surface that limitation explicitly rather than silently skipping it.

## cron.d/ — Recurring Tasks

Each file in `cron.d/` defines a recurring invocation. Jobs may run a script, a
prompt, or both.

```yaml
name: daily-metrics-check
schedule: "0 9 * * *"
timezone: UTC
enabled: true
run:
  type: prompt
  prompt: |
    Check the product dashboard metrics for the last 24 hours.
    Compare against targets in ROADMAP.md.
    Log anomalies. Update structured state with latest numbers.
  script: scripts/fetch_metrics.py
context:
  - ROADMAP.md
  - state/core.json
output:
  log: true
  update_state: true
  notify: false
```

`schedule` uses a standard cron expression. `timezone` is required unless the
epic declares a default timezone in `EPIC.md`.

`run.type` MUST be one of:

* `prompt`
* `script`
* `both`

`context` lists additional files to load beyond the default disclosure flow.

`output` declares whether the runtime may create logs, update structured state,
or notify a human or external system.

## hooks/ — Event-Triggered Actions

Hooks are typed handlers triggered by lifecycle events. Supported handler types
are:

* `prompt`
* `script`
* `http`
* `agent`

### Canonical triggers

The standard canonical trigger names are:

* `install`
* `uninstall`
* `status-changed`
* `milestone-complete`
* `plan-empty`
* `became-blocked`
* `cron-fired`

Custom triggers are allowed and SHOULD use descriptive kebab-case names.

Trigger meanings:

| Trigger | Fires when |
|---------|------------|
| `install` | Epic is activated for the first time, not on resume |
| `uninstall` | Epic is removed from the workspace or explicitly torn down |
| `status-changed` | Epic lifecycle status changes |
| `milestone-complete` | A `ROADMAP.md` milestone is marked complete |
| `plan-empty` | The current plan's `## Now` section has no actionable items |
| `became-blocked` | The epic becomes blocked |
| `cron-fired` | A `cron.d/` job completes |

### Discovery and execution

Trigger discovery is path-based:

* `hooks/<trigger>.d/` is the multi-handler form
* `hooks/<trigger>.*` is the single-handler form
* If both forms exist, tooling MUST prefer `hooks/<trigger>.d/`

Handlers inside `hooks/<trigger>.d/` MUST run serially in lexical filename
order.

Hooks for the same trigger are synchronous and blocking. Later handlers MUST
NOT run until the current handler finishes. Later handlers MUST NOT run after an
`abort` result or an unrecoverable failure unless the epic's escalation policy
explicitly instructs the executor to continue.

The old `concurrent` field is reserved for forward compatibility and SHOULD be
ignored by `v0.5.0` implementations.

### Markdown hook format

`prompt` and `agent` hooks use markdown with YAML frontmatter:

```markdown
---
enabled: true
type: prompt
timeout: 300
---

A milestone just completed in this epic. Review ROADMAP.md, update status
markers, and create a new plan in plans/ for the next milestone.
If this was the final milestone, propose marking the epic complete.
```

When `type` is absent, tooling SHOULD infer it for backward compatibility:

* `.md` => `prompt`
* executable/script files (`.sh`, `.py`, etc.) => `script`
* `.yml` / `.yaml` MUST declare `type: http`

### Handler types

| Type | Typical file | Behavior |
|------|--------------|----------|
| `prompt` | `.md` | Markdown body executes in the current agent session using hook event context |
| `script` | `.sh`, `.py`, etc. | Executed as a subprocess with JSON event context on stdin |
| `http` | `.yml` / `.yaml` | Sends hook event context as an HTTP request according to YAML config |
| `agent` | `.md` with `type: agent` | Spawns a sub-agent scoped to the epic and waits for completion |

`prompt` hooks run in the current session and may guide immediate follow-up
work.

`script` hooks are appropriate for deterministic automation, validation, and
data collection.

`http` hooks are synchronous and intended for webhooks and external
integrations.

`agent` hooks are autonomous but not fire-and-forget. The executor MUST wait
for the sub-agent to complete, time out, fail, or refuse before advancing.

### Hook communication protocol

All hook types receive the same logical event context:

```json
{
  "trigger": "milestone-complete",
  "epic_id": "saas-launch",
  "timestamp": "2026-03-03T14:22:44Z",
  "idempotency_key": "4b8e1f7c",
  "state": { "status": "active", "milestone": "M2" },
  "current_plan": "002-billing-integration.md",
  "milestone": "M2"
}
```

Minimum fields:

* `trigger`
* `epic_id`
* `timestamp`
* `idempotency_key`
* `state` when structured state exists
* `current_plan` when known

Trigger-specific fields SHOULD be included when known:

* `status-changed` => `from`, `to`
* `milestone-complete` => `milestone`
* `plan-empty` => `plan`
* `cron-fired` => `job`
* `became-blocked` => `reason`

Delivery by type:

* `script` — JSON on stdin
* `prompt` — structured executor preamble followed by markdown body
* `agent` — structured executor preamble followed by markdown body
* `http` — JSON request body, optionally transformed by `body_template`

### Hook result protocol

`script`, `prompt`, and `agent` hooks produce a normalized result:

```json
{
  "action": "continue",
  "message": "Created next plan for M3"
}
```

Allowed `action` values:

* `continue`
* `abort`
* `escalate`

`message` is optional and SHOULD be logged or surfaced to the parent session.

Type-specific result mapping:

* `script` — stdout JSON plus exit codes
* `prompt` — executor obtains a structured result from the current agent session
* `agent` — executor obtains a structured result from the sub-agent
* `http` — no custom action channel; HTTP success continues and failure follows
  retry and escalation rules

Hooks MUST NOT return direct file mutations in their output. File changes happen
through the normal epic write path.

### Script hook exit codes

* `0` — success; parse stdout as result JSON when present
* `1` — error; handled per `policy.yml`
* `2` — abort; stop further handlers and halt the triggering operation

### HTTP hook format

HTTP hook files are YAML documents:

```yaml
enabled: true
type: http
timeout: 30
url: ${SLACK_WEBHOOK_URL}
method: POST
headers:
  Content-Type: application/json
body_template: |
  {"text": "Epic {{epic_id}} milestone {{milestone}} completed"}
retry:
  max_attempts: 3
  backoff_seconds: [1, 5, 15]
```

`http` hooks MUST execute inline. A non-2xx response is a hook failure. Retries
occur inline before escalation rules are applied.

### Agent hook format

Agent hook files use markdown with `type: agent`:

```markdown
---
enabled: true
type: agent
timeout: 600
max_turns: 12
---

A milestone just completed. Review ROADMAP.md, update milestone markers, and
create a new plan in plans/ for the next milestone. If this was the final
milestone, propose marking the epic complete.
```

Agent hooks MUST run with the epic as their scope, MUST follow the same
`policy.yml` constraints as the parent epic, and MUST block until completion,
refusal, timeout, or failure.

### Hook safety and failure handling

Hooks SHOULD be idempotent. Executors SHOULD generate an opaque
`idempotency_key` for each hook firing. If the executor writes any log entry for
that firing, it MUST include the same `idempotency_key` in the log frontmatter.

If no `policy.yml` exists, default failure handling is `log_and_continue`.

When a hook fails, the executor MUST write an error log entry. The hook itself
is not responsible for failure logging.

Recommended failure filename:

`log/YYYY-MM-DDTHH-MM-SSZ-hook-error-<trigger>.md`

Recommended failure frontmatter includes:

* `actor: hook-error`
* `type: error`
* `trigger`
* `handler`
* `idempotency_key`

## Lifecycle triggers

`install` fires exactly once: the first time an epic becomes active, not on
subsequent resumptions. Use it to bootstrap infrastructure.

`uninstall` fires when an epic is removed from the workspace or explicitly torn
down. Use it for cleanup.

Both SHOULD be idempotent. Implementations MUST track whether `install` has
fired, typically with a sentinel in `runtime/`, to distinguish first activation
from resumption.

## policy.yml — Constraints for Autonomous Operation

`policy.yml` declares boundaries for agents operating on the epic without human
oversight. Agents MUST read it at activation time and treat it as hard
constraints. Policy applies to hooks and cron jobs as well as interactive
sessions.

```yaml
autonomy:
  max_spend_per_run: 0.50
  allowed_tools:
    - web_search
    - bash
    - file_create
  forbidden_actions:
    - delete production data
    - commit to main branch
    - send external emails without approval

hooks:
  allowed_types:
    - prompt
    - script
    - http
    - agent
  allowed_domains:
    - hooks.slack.com
    - api.pagerduty.com
  max_timeout_seconds: 900

escalation:
  on_error: log_and_continue
  on_ambiguity: ask_human
  notify: martin@kindship.ai
```

If no `policy.yml` exists, autonomous behavior defaults to:

* `on_error: log_and_continue`
* `on_ambiguity: ask_human`

In that case, the epic inherits the host agent's existing constraints rather
than gaining broader privileges.

### Hook-specific policy rules

* `hooks.allowed_types` controls which hook handler types may run. If absent,
  tooling SHOULD allow `prompt` and `script` only.
* `http` hooks MUST be denied unless `http` appears in `hooks.allowed_types`.
* `agent` hooks MUST be denied unless `agent` appears in `hooks.allowed_types`.
* `hooks.allowed_domains` applies only to `http` hooks. If absent, `http`
  hooks MUST be denied.
* `hooks.max_timeout_seconds`, when present, caps per-hook `timeout` values.

Autonomous execution surfaces MAY run only local workspace files or inline
prompts already stored in the epic. Fetching remote prompts or executable code
during autonomous execution requires explicit human approval.

`http` hooks MAY call external services only when allowed by `policy.yml`.

## runtime/ — Executor Metadata

`runtime/` stores non-portable executor state such as install sentinels,
lockfiles, dedupe caches, hook replay protection, and temporary outputs.

It SHOULD be gitignored. Tooling MUST treat it as non-authoritative for business
facts and SHOULD recreate it safely when missing.

Anything required for human or agent resumption belongs in repo-tracked epic
state, not in `runtime/`.
