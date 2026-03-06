# Specification

> The complete format specification for the EPIC.md Standard.
> **Version 0.4.13**

An Epic is a stateful, long-running workflow that an AI agent (or human-AI pair) can operate on across sessions. It extends the SKILL.md standard: every epic *is* a skill, with the same triggering and progressive disclosure mechanics, plus state management, planning, and scheduling.

Where a skill says *how* to do a task, an epic defines a *workflow* — a repeatable process with phases, state, and history. Each workflow can be instantiated: the definition stays stable while instance-specific details (project name, dependencies, dates) live in working state.

Think of an epic like a class and its working state like an instance. The `saas-launch` epic defines how to launch any SaaS product. When you start a specific launch, you populate working state (`state.json` or `state/`, `plans/`, `log/`) with the project-specific details.

## Design Principles

* **Backward compatible.** Every epic is a valid skill. Skill-only loaders see a skill and work normally. Epic-aware loaders unlock stateful behavior.
* **Progressively disclosed.** An agent loads only what it needs — frontmatter first, then context, then state, then history.
* **Mutable/immutable separation.** Some files are working state (written frequently), others are structure (written rarely). Agents need to know which is which.
* **Portable by default.** Repo-tracked epic files should move between workspaces and executors without rewrites or hidden instance-local dependencies.
* **Machine-validated.** Reserved fields and machine-readable files have stable, versioned structure so tooling can validate, migrate, and round-trip them safely.
* **Minimally prescriptive.** Only two files are required. Everything else appears when the epic needs it.

## Epic Archetypes

**Workflow epics** (the default) define a reusable process — how to launch a SaaS product, how to run email outreach, how to build a website. The workflow definition (SKILL.md, EPIC.md, hooks/, policy.yml) stays stable; each run creates instance state (`state.json` or `state/`, `plans/`, `log/`) with the project-specific details.

**Instance epics** are one-off efforts with unique scope. The EPIC.md body describes this specific project rather than a generic process. Useful when the work is truly unique and won't repeat. Instance epics may place fields like `owner` directly in EPIC.md frontmatter for convenience.

**Capability epics** extend the agent itself — new tools, channels, integrations. The agent works *with* the epic. It typically stays active indefinitely. Its SKILL.md teaches the agent how to use the new capability across all contexts, not just within the epic itself.

Example: a Telegram epic is a capability epic. Once installed, the agent *has* Telegram the way it has bash. It decides when to use it based on context. Other epics don't reference or depend on it — composability flows through the agent, not between epics.

## Conventions

* All timestamps in machine-readable files (`state.json`, `state/`, log frontmatter, cron output) MUST be ISO 8601 with timezone, preferably UTC (`2026-03-03T14:22:44Z`).
* Log filenames SHOULD use UTC (see log/ spec for format).
* cron.d schedules MUST declare a `timezone` field, or the epic MUST declare a default in EPIC.md frontmatter (`timezone: UTC`).
* Repo-tracked JSON files MUST use UTF-8, 2-space indentation, and a trailing newline. Writers SHOULD preserve stable key order for reserved fields.
* Executor-only metadata (locks, sentinels, dedupe caches, ephemeral run state) MUST NOT be stored in repo-tracked files unless it is required for resumption. Use `runtime/` for non-portable executor state.
* Repo-tracked epic files SHOULD reference external systems by stable semantic alias, not executor-assigned or database-local IDs.
* Write operations to `plans/`, `state.json` or `state/`, and EPIC.md frontmatter SHOULD be serialized per-epic. Implementations SHOULD use a per-epic lock (file lock, advisory lock, or equivalent) to prevent logical races between concurrent agents, hooks, and cron jobs. If the lock is unavailable, the writer SHOULD retry or log-and-skip per the epic's policy.yml escalation rules.
* Epics SHOULD be loosely coupled. One epic SHOULD NOT depend on another epic's internal files, hooks, policy, or state. Cross-epic coordination SHOULD happen through shared external artifacts or through the agent, not through nested epic structure or direct sibling dependencies.

## Anatomy of an Epic

```
epic-name/
├── SKILL.md             (required — routing, triggering, instructions)
├── EPIC.md              (required — workflow definition, identity)
│
│   # Working state (mutable — written by agents and humans each session)
├── plans/               (optional — tactical plans, current and past)
│   └── 001-initial.md
├── state.json           (optional — structured machine-readable state)
├── state/               (optional — split structured state; use `state/core.json` for reserved fields)
│   └── core.json
├── log/                 (optional — append-only activity history)
│   ├── 2026-03-03T14-22-44Z-agent-researched-competitors.md
│   └── 2026-03-04T09-01-12Z-human-revised-pricing.md
│
│   # Strategic state (mutable — written at milestones, not every session)
├── ROADMAP.md           (optional — long-term goals, milestones, outcomes)
├── DECISIONS.md         (optional — curated decision records)
│
│   # Structure (immutable unless consciously revised)
├── cron.d/              (optional — recurring task definitions)
│   └── daily-metrics.yml
├── skills/              (optional — epic-scoped skills)
│   └── generate-report/
│       └── SKILL.md
├── hooks/               (optional — event-triggered typed handlers)
│   ├── plan-empty.md
│   └── milestone-complete.d/
│       ├── 010-slack.yml
│       └── 020-review.md
├── policy.yml           (optional — constraints for autonomous operation)
├── runtime/             (optional — non-portable executor metadata; SHOULD be gitignored)
│   └── install-sentinel.json
├── artifacts/           (optional — produced outputs, deliverables)
├── scripts/             (inherited from SKILL.md standard)
├── references/          (inherited from SKILL.md standard)
└── assets/              (inherited from SKILL.md standard)
```

### What's Required

`SKILL.md` and `EPIC.md` MUST both exist. SKILL.md handles routing and backward compatibility with skill loaders. EPIC.md holds stateful context. A two-file epic is valid. The minimum *useful* stateful epic adds `plans/` + `log/`.

### Mutability Tiers

Understanding what changes and how often prevents agents from accidentally overwriting structure or ignoring state:

| Tier | Files | Who writes | How often |
|------|-------|-----------|-----------|
| Working state | plans/, state.json, log/ | Agents, humans, cron | Every session |
| Split working state | state/ | Agents, humans, cron | Every session when state.json is insufficient |
| Strategic state | ROADMAP.md, DECISIONS.md | Humans, agents at milestones | Weekly/monthly |
| Curated context | EPIC.md | Humans, lifecycle transitions | Rarely |
| Configuration | SKILL.md, cron.d/, hooks/, policy.yml | Humans, conscious revision | At setup or revision |
| Runtime state | runtime/ | Executors | As needed, non-portable |
| Output | artifacts/ | Agents | As produced |
| Immutable | scripts/, references/, assets/ | Skill author | During normal operation |

Agents MUST NOT write to Configuration or Immutable tier files during normal operation. Agents MUST NOT rewrite EPIC.md body without human approval.

### Authoritative Files

When information overlaps or conflicts, precedence is deterministic:

| Question | Authoritative source |
|----------|---------------------|
| What is the current status? | `state/core.json`, then `state.json` |
| What should I do next? | plans/ (current plan) |
| What are the facts/numbers? | `state/core.json` or `state.json` |
| What happened? | log/ |
| What are we building toward? | ROADMAP.md |
| Why did we decide X? | DECISIONS.md, then log/ |
| What am I allowed to do? | policy.yml |

If the current plan and the active state file disagree, the plan wins for intent (what to do), the state file wins for facts (what is true). An agent encountering a conflict SHOULD log the discrepancy and resolve it.

## SKILL.md — Routing and Instructions

SKILL.md uses standard SKILL.md format with no additions:

```yaml
---
name: saas-launch
description: >
  Workflow for launching a SaaS product. Covers architecture decisions,
  implementation, deployment, and first-customer onboarding. Activate
  this epic when planning or executing a product launch.
---
```

An epic's SKILL.md is a completely standard skill. Epic-aware loaders detect an epic by checking whether `EPIC.md` exists in the same directory — no special frontmatter fields needed. Skill-only loaders see a normal skill and work as usual.

The SKILL.md body contains instructions — how to work on this epic, what tools to use, what patterns to follow. Same role as in any skill.

SKILL.md SHOULD describe stable workflow shape, not volatile operational detail. If instructions change weekly, they belong in `plans/`, `scripts/`, `references/`, or structured state instead of the skill body.

## EPIC.md — Stateful Context

EPIC.md is the part that makes an epic more than a skill. It defines the workflow — what it does, how it proceeds, and what an agent needs to resume work.

EPIC.md MUST have YAML frontmatter with at least `id` and `spec_version`.

```yaml
---
spec_version: 0.4.13
id: saas-launch             # workflow identifier (or instance name for instance epics)
tags: [saas, launch, product]  # optional — for discovery/filtering
timezone: UTC               # optional — default timezone for cron and logs
---
```

The `spec_version` field declares which revision of this standard the epic targets. Readers MUST ignore unknown fields from newer versions. Writers SHOULD preserve unknown fields they do not understand.

The `id` field is the epic's stable identifier. For workflow epics it names the workflow type; for instance epics it names the specific effort. It MUST be unique within the workspace.

The markdown body of EPIC.md defines the workflow:

* **What workflow does this define?** (purpose, phases, inputs needed, outputs produced)
* **What does success look like?** (exit criteria, definition of done)
* **What are the phases?** (high-level process steps — the general shape, not a specific plan)
* **What are the interfaces?** (where data comes from, where outputs go)
* **How to resume an instance?** (which files are authoritative, what to read first)

For instance epics, the body may describe project-specific context instead of generic workflow phases. For per-session state, use `plans/` and `state.json` or `state/`.

EPIC.md SHOULD include a top-level `## Resume` section that summarizes how to restart work on this epic. The EPIC.md body SHOULD stay under roughly 300 lines (excluding frontmatter). If it grows beyond that, move volatile operational detail into `plans/`, `scripts/`, `references/`, or structured state.

## Progressive Disclosure

Epics extend the skill disclosure model from 3 to 6 levels, optimized for context budget:

| Level | What | When loaded | Budget |
|-------|------|-------------|--------|
| 1 | SKILL.md frontmatter | Always — skill index | ~150 words |
| 2 | SKILL.md body + EPIC.md (frontmatter + body) + policy.yml | When epic activates | <500 lines combined |
| 3 | state.json or state/core.json + current plan from plans/ | Immediately after activation | <150 lines combined |
| 4 | Recent log entries (last 3-5) | For session continuity | ~200 lines |
| 5 | ROADMAP.md + DECISIONS.md | When strategic context needed | <300 lines |
| 6 | Full logs, skills, references, and supporting folders | On demand | Unlimited |

Level 1 is SKILL.md frontmatter only. This keeps Level 1 implementable by plugin-based coding agents that can only inject skill metadata into context, not arbitrary additional files.

An agent resuming work on an epic reads levels 1-4 (~1500 lines — the "cold start budget") to get oriented, then pulls in 5-6 as needed. This mirrors how a human returning to a project reads their recent notes before reviewing the full history.

### Resumption Sequence

When an agent resumes work on an epic, it SHOULD follow this sequence:

1. Read `SKILL.md` frontmatter and body
2. Read `EPIC.md` frontmatter and body, plus `policy.yml` if present
3. Read `state/core.json` if present; otherwise read `state.json` if present
4. Read the current plan from `plans/`
   - Use `state/core.json.current_plan` or `state.json.current_plan` when present
   - Otherwise load the most recently modified plan file
5. Read the 3-5 most recent log entries for session continuity

If the active state file and the current plan disagree, the state file wins for facts and the plan wins for intent. Agents SHOULD log the discrepancy before proceeding. Agents SHOULD NOT take action before completing steps 1-4.

## Validation and Compatibility

Reserved fields exist so tools can interoperate safely. Implementations MAY extend epic files with additional fields, but they MUST validate and preserve the reserved fields defined by this standard.

### Normative validation surface

The following structures are normative and SHOULD have published machine-readable schemas in compliant tooling:

* `EPIC.md` frontmatter
* `state.json` reserved fields
* `state/core.json` reserved fields
* `cron.d/*.yml`
* `policy.yml`
* Markdown hook frontmatter
* HTTP hook YAML config
* Log frontmatter

Epic-defined extension fields MAY be validated by epic-local schemas, but the standard does not require a schema for every domain-specific field.

### Compatibility rules

* Readers MUST ignore unknown fields from newer standard revisions unless the unknown field changes execution semantics in a way the reader cannot safely handle.
* Writers MUST preserve unknown fields in machine-readable files when performing targeted updates.
* Breaking changes to reserved fields or file semantics MUST increment `spec_version` and document the migration behavior.
* Import/export tooling MUST round-trip reserved fields without silent loss or normalization that changes meaning.

### Compliance levels

Implementations SHOULD document which of these levels they satisfy:

* **Read-only loader** — discovers epics, reads authoritative files, and validates reserved fields
* **Interactive executor** — performs resumption and user-driven updates while following mutability and validation rules
* **Autonomous executor** — additionally runs hooks/cron, manages `runtime/`, and enforces policy.yml during unattended execution

## Component Specifications

### ROADMAP.md — Strategic Intent

The long view. Updated infrequently, usually when milestones complete or strategy shifts. Contains goals, milestones, success criteria, and the narrative arc of the epic.

```markdown
# SaaS Launch — Roadmap

## Vision
Take a product from architecture to first paying customer.

## Milestones

### M1: Core Product ✅
- [x] Architecture decisions
- [x] Core implementation
- Completed: 2026-02-28

### M2: Beta Program 🔄
- [ ] Invite beta users
- [ ] Feedback collection pipeline
- Target: 2026-03-15

### M3: First Customer
- [ ] Onboarding flow
- [ ] Usage-based billing
- Target: 2026-04-01

## Success Criteria
- 10 beta customers within 30 days of launch
- <5% churn during beta period
```

> **Convention:** Use ✅ 🔄 ⬚ (or `[x]` `[-]` `[ ]`) for milestone status so agents can parse progress programmatically.

### DECISIONS.md — Decision Records (optional)

Curated, low-churn record of significant decisions. Extracted from logs so agents and humans can answer "why did we choose X?" without parsing full history.

```markdown
# Decisions

### D1: PostgreSQL over MongoDB for primary store
**Date:** 2026-03-02
**Context:** Need relational queries across users, subscriptions, and usage data.
**Decision:** PostgreSQL — strong relational model, better for our query patterns.
**Alternatives considered:** MongoDB (more flexible schema, but harder to query across collections).
**Status:** Accepted

### D2: Stripe for billing
**Date:** 2026-03-03
**Context:** Need usage-based billing with metering support.
**Decision:** Stripe Billing with metered subscriptions.
**Status:** Accepted
```

Decision entries MUST be stable after reaching "Accepted" status. If a decision is later reversed, add a new decision that supersedes the old one and mark the original as "Superseded by D{n}". This keeps the record curated and prevents silent rewrites.

When present, DECISIONS.md is loaded at Level 5 alongside ROADMAP.md.

### plans/ — Tactical Plans

The short view. Plans are updated frequently — often every session. Each plan is the agent's working memory of *what to do right now*. Keep individual plans under 100 lines. When items are done, they should move to log/. When items are strategic, they should graduate to ROADMAP.md.

```
plans/
├── 001-database-setup.md
├── 002-billing-integration.md
└── 003-beta-onboarding.md
```

The current plan is tracked via the reserved `current_plan` field in `state/core.json` when present, otherwise in `state.json`. When neither file exists, or when `current_plan` is absent, tooling SHOULD load the most recently modified plan file. Old plans are preserved in the directory, providing plan history for free (like `log/`).

#### Plan file format

Plan files MUST contain:

* A title heading
* An `Updated:` line
* `## Now`
* `## Next`
* `## Blocked`

Additional sections are allowed.

```markdown
# Billing Integration Plan

Updated: 2026-03-03

## Now
- Set up PostgreSQL schema for users and subscriptions
- Decision pending: free trial length (7 vs 14 days)

## Next
- Integrate Stripe billing with metered subscriptions
- Draft onboarding flow for beta users

## Blocked
- Domain setup — waiting on DNS propagation

## Recent Decisions
- 2026-03-02: Chose PostgreSQL over MongoDB (see log/2026-03-02...)
```

The `plan-empty` hook fires when `## Now` contains no actionable items. When `## Now` is empty and no `plan-empty` hook exists, agents SHOULD treat the plan as exhausted: log completion, check `ROADMAP.md` for the next milestone, create the next plan when needed, and otherwise propose marking the epic complete.

### state.json — Structured State

Machine-readable snapshot of current state. Complements the human-readable plans. Useful when scripts or cron jobs need to read epic state, or when an agent needs to quickly check a value without parsing markdown.

```json
{
  "state_version": 1,
  "status": "active",
  "name": "Spectr MVP Launch",
  "owner": "martin",
  "started": "2026-02-15",
  "current_plan": "002-billing-integration.md",
  "milestone": "M2",
  "progress": 0.4,
  "blocked": false,
  "target_customers": 10
}
```

The schema is mostly epic-defined. Three fields are reserved for interoperability: `state_version`, `status`, and `current_plan`. Everything else is epic-defined.

#### Reserved fields

* `state_version` — version of the reserved state-file schema. When absent, readers SHOULD assume version `1` for backward compatibility.
* `status` — lifecycle state. When present, it MUST be one of `active`, `paused`, `complete`, or `abandoned`. When absent, tooling should assume the epic is active.
* `current_plan` — filename of the active plan in `plans/` (e.g., `"002-billing-integration.md"`)

#### Other conventional fields

* `name` — human-readable name for this instance of the workflow
* `owner` — who drives this instance
* `started` — when work began (ISO 8601)

These are suggestions, not requirements. Epics may use any additional fields that make sense for their domain.

Updates to state.json SHOULD be atomic (write to a temp file, then rename) to avoid partial writes from crashes or concurrent access. Writers MUST preserve unknown fields when updating reserved fields.

#### Upgrade path

When a single state.json becomes unwieldy, epics MAY use a `state/` directory with multiple JSON files instead (`state/core.json`, `state/metrics.json`, etc.). Tooling SHOULD check `state/core.json` first for reserved fields, then fall back to `state.json`. Reserved fields MUST live in `state/core.json` when that file exists.

### log/ — Activity History

Append-only. Each entry is a markdown file with a timestamped, slugified filename. Log entries MUST NOT be edited once written, except for redacting secrets or PII that were logged in error.

```
log/
├── 2026-02-15T10-00-00Z-epic-created.md
├── 2026-02-20T14-22-31Z-agent-architecture-review.md
├── 2026-03-01T09-15-07Z-human-approved-tech-stack.md
└── 2026-03-03T14-22-44Z-agent-implemented-aggregation.md
```

#### Filename convention

`YYYY-MM-DDTHH-MM-SSZ-{actor}-{slug}.md`

Where `{actor}` is `agent`, `human`, `cron`, `hook`, or a specific agent/user name. Second-level precision avoids collisions when multiple agents or hooks fire in the same minute.

> **Safety rule:** Log entries MUST NOT contain secrets, tokens, API keys, or unredacted private user data. Agents SHOULD redact sensitive values before writing. If secrets are detected in existing logs, they SHOULD be redacted in place (the only permitted log mutation).

#### Log entry format

```markdown
---
actor: agent
type: work          # work | decision | review | error | milestone
epic: saas-launch
duration_minutes: 12
tokens_used: 48000
---

## Set up PostgreSQL schema

Created tables for users, subscriptions, and usage metering.
Added migration scripts and seed data for development.

### Changes
- Created `scripts/create_schema.sql`
- Updated structured state: milestone = "M2"
- Moved "database schema" from current plan/Now to completed

### Next
- Integrate Stripe billing (moved to current plan/Now)
```

### cron.d/ — Recurring Tasks

Each file defines a recurring invocation — could be a script, an LLM prompt, or both.

```yaml
# cron.d/daily-metrics.yml
name: daily-metrics-check
schedule: "0 9 * * *"          # standard cron expression
timezone: UTC
enabled: true

# What to run
run:
  type: prompt                  # prompt | script | both
  prompt: |
    Check the product dashboard metrics for the last 24 hours.
    Compare against targets in ROADMAP.md.
    Log anomalies. Update structured state with latest numbers.
  script: scripts/fetch_metrics.py   # optional — runs before prompt

# Context to load (beyond default levels 1-4)
context:
  - ROADMAP.md
  - state/core.json

# Where output goes
output:
  log: true                     # auto-create log entry
  update_state: true            # allow structured state mutation
  notify: false                 # optional — alert human
```

### skills/ — Epic-Scoped Skills

Standard SKILL.md skills, but scoped to this epic. They're only available when this epic is active. Useful for specialized workflows that don't make sense globally.

```
skills/
└── generate-report/
    ├── SKILL.md
    └── templates/
        └── weekly-report.html
```

Authors MAY create additional local folders for supporting context or generated materials. These folders are epic-defined and outside the standard. If work needs to become its own reusable or stateful unit, prefer a separate epic with loose coupling over nesting epics inside other epics.

### hooks/ — Event-Triggered Actions

Typed handlers triggered by lifecycle events. Hooks support `prompt`, `script`, `http`, and `agent` handler types.

**Trigger discovery is path-based.** The trigger name comes from either a single file named `hooks/<trigger>.*` or a directory named `hooks/<trigger>.d/`.

#### Canonical triggers

| Trigger filename     | Fires when                                              |
|---------------------|---------------------------------------------------------|
| `install`           | Epic is activated for the first time (not on resume)     |
| `uninstall`         | Epic is removed from the workspace or explicitly torn down |
| `status-changed`    | Epic lifecycle status changes                            |
| `milestone-complete` | A ROADMAP.md milestone is marked ✅                      |
| `plan-empty`        | The current plan's `## Now` section has no actionable items |
| `became-blocked`    | Epic becomes blocked                                     |
| `cron-fired`        | Any cron.d/ job completes (receives job name as context)  |

Custom triggers are allowed — use descriptive kebab-case names.

```
hooks/
├── milestone-complete.md
├── milestone-complete.d/
│   ├── 010-slack.yml
│   └── 020-review.md
├── plan-empty.md
├── became-blocked.md
└── status-changed.sh
```

#### Discovery and execution order

* `hooks/<trigger>.d/` is the multi-handler form. Files inside the directory MUST run serially in lexical filename order.
* `hooks/<trigger>.*` is the legacy single-handler form.
* If both forms exist for the same trigger, tooling MUST prefer `hooks/<trigger>.d/` and ignore the single-file form for that trigger.
* Hooks for the same trigger are synchronous and blocking. Later handlers MUST NOT run until the current handler finishes.
* Later handlers MUST NOT run after an `abort` result or an unrecoverable failure, unless the epic's escalation policy explicitly instructs the executor to continue.
* The old `concurrent` field is reserved for forward compatibility and SHOULD be ignored by `v0.4.13` implementations.

#### Markdown hook format

```markdown
---
enabled: true
type: prompt            # prompt | agent
timeout: 300            # optional — seconds
---

A milestone just completed in this epic. Review the ROADMAP.md,
update status markers, and create a new plan in plans/ for the next milestone.
If this was the final milestone, propose marking the epic complete.
```

`prompt` and `agent` hooks use markdown plus YAML frontmatter. When `type` is absent, tooling SHOULD infer it for backward compatibility:

* `.md` => `prompt`
* executable/script files (`.sh`, `.py`, etc.) => `script`
* `.yml` / `.yaml` MUST declare `type: http`

#### Handler types

| Type | Typical file | Behavior |
|------|--------------|----------|
| `prompt` | `.md` | Markdown body is executed by the current agent session using the hook event context |
| `script` | `.sh`, `.py`, etc. | Executed as a subprocess with JSON event context on stdin |
| `http` | `.yml` / `.yaml` | Sends the hook event context as an HTTP request according to YAML config |
| `agent` | `.md` with `type: agent` | Spawns a sub-agent scoped to the epic and waits for its completion |

`prompt` hooks run in the current session and may guide follow-up work immediately.

`script` hooks run as local programs. They are appropriate for validation, data collection, and deterministic automation. Script hooks are usually inferred from file extension and do not require YAML frontmatter.

`http` hooks are intended for webhooks and external integrations. They are synchronous: retries and failures happen before the trigger completes.

`agent` hooks are autonomous but not fire-and-forget. The executor MUST wait for the sub-agent to complete, time out, fail, or refuse before advancing to the next handler.

#### Hook Communication Protocol

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
* `state` — from `state/core.json` or `state.json`, when present
* `current_plan` — when present

Trigger-specific fields SHOULD be included when known:

| Trigger | Additional fields |
|---------|-------------------|
| `status-changed` | `from`, `to` |
| `milestone-complete` | `milestone` |
| `plan-empty` | `plan` |
| `cron-fired` | `job` |
| `became-blocked` | `reason` |

Delivery by type:

* `script` — JSON on stdin
* `prompt` — structured executor preamble followed by the markdown body
* `agent` — structured executor preamble followed by the markdown body
* `http` — JSON request body, optionally transformed by `body_template`

#### Hook Result Protocol

`script`, `prompt`, and `agent` hooks produce a normalized result:

```json
{
  "action": "continue",
  "message": "Created next plan for M3"
}
```

Allowed `action` values:

* `continue` — default; proceed to the next handler
* `abort` — stop further handlers and halt the triggering operation
* `escalate` — stop further handlers and hand control to the executor's escalation path

`message` is optional and SHOULD be logged or surfaced to the parent session.

Type-specific result mapping:

* `script` — stdout JSON plus exit codes
* `prompt` — executor obtains a structured result from the current agent session
* `agent` — executor obtains a structured result from the sub-agent before continuing
* `http` — has no custom action channel; HTTP success continues, HTTP failure is handled through retries and policy escalation

State mutations MUST NOT be returned in hook output. Hooks may recommend actions, but file mutations still happen through the normal epic write path.

#### Script hook exit codes

* `0` — success; parse stdout as result JSON when present
* `1` — error; handled per `policy.yml`
* `2` — abort; stop further handlers and halt the triggering operation

#### HTTP hook format

HTTP hook files are YAML documents with top-level config keys:

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

`http` hooks MUST execute inline. A non-2xx response is a hook failure. Retries occur inline before escalation rules are applied.

#### Agent hook format

Agent hook files use markdown with `type: agent`:

```markdown
---
enabled: true
type: agent
timeout: 600
max_turns: 12
---

A milestone just completed. Review ROADMAP.md, update milestone markers,
and create a new plan in plans/ for the next milestone.
If this was the final milestone, propose marking the epic complete.
```

Agent hooks MUST run with the epic as their scope, MUST follow the same `policy.yml` constraints as the parent epic, and MUST block until completion, refusal, timeout, or failure.

Hooks enable reactive behavior — the epic can respond to its own state changes without cron polling.

> **Note:** Hooks SHOULD be idempotent — safe to rerun if the trigger fires twice.

> **Note:** Executors SHOULD generate an opaque `idempotency_key` for each hook firing. If the executor writes any log entry for that firing (success, retry, or failure), it MUST include the same `idempotency_key` in the log frontmatter so duplicate firings and retries can be correlated.

> **Note:** Hooks are synchronous and serial within a trigger. Implementations MUST NOT run multiple handlers for the same trigger concurrently.

> **Note:** On failure, hooks follow the epic's `policy.yml` escalation rules. If no policy exists, the default is `log_and_continue`.

> **Failure logging:** When a hook fails (non-zero exit, timeout, agent error/refusal, or crash), the executor MUST write a log entry. The hook itself is not responsible for failure logging. Error log entries use the standard filename convention with `hook-error` as the actor:
>
> ```
> log/2026-03-03T14-22-44Z-hook-error-milestone-complete.md
> ```
>
> With frontmatter:
> ```yaml
> ---
> actor: hook-error
> type: error
> trigger: milestone-complete
> handler: hooks/milestone-complete.d/020-review.md
> idempotency_key: 4b8e1f7c
> ---
> Hook `milestone-complete` failed: [error summary from executor]
> ```

#### Lifecycle triggers

`install` fires exactly once: the first time an epic becomes active,
not on subsequent resumptions. Use it to bootstrap infrastructure — install
dependencies, start daemons, provision credentials.

`uninstall` fires when an epic is removed from the workspace or explicitly
torn down. Use it for cleanup — stop daemons, revoke tokens, remove config.

Both SHOULD be idempotent. Implementations MUST track whether `install` has
fired (for example with a sentinel in `runtime/`) to distinguish first
activation from resumption.

### policy.yml — Constraints for Autonomous Operation

Declares boundaries for agents operating on this epic without human oversight. Especially relevant for autonomous agents that manage their own infrastructure.

```yaml
# policy.yml
autonomy:
  max_spend_per_run: 0.50       # USD — halt and ask if exceeded
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
  on_error: log_and_continue     # or: halt_and_notify
  on_ambiguity: ask_human        # or: best_guess_and_log
  notify: martin@kindship.ai     # optional
```

Agents MUST read policy.yml at activation time and treat it as hard constraints. Policy applies to hooks and cron jobs too, not just interactive sessions.

If no `policy.yml` exists, autonomous behavior defaults to `on_error: log_and_continue` and `on_ambiguity: ask_human`. In that case, the epic inherits the host agent's existing constraints rather than gaining any broader privileges.

Hook-specific policy rules:

* `hooks.allowed_types` controls which hook handler types may run. If absent, tooling SHOULD allow `prompt` and `script` only.
* `http` hooks MUST be denied unless `http` appears in `hooks.allowed_types`.
* `agent` hooks MUST be denied unless `agent` appears in `hooks.allowed_types`.
* `hooks.allowed_domains` applies only to `http` hooks. If absent, `http` hooks MUST be denied.
* `hooks.max_timeout_seconds`, when present, caps per-hook `timeout` values. Hook-local timeouts MUST NOT exceed the policy cap.

Autonomous execution surfaces (`hooks/`, `cron.d/`, `install`, and `uninstall`) MAY run only local workspace files or inline prompts already stored in the epic. `http` hooks MAY call external services only when allowed by `policy.yml`. Fetching remote prompts or executable code during autonomous execution requires explicit human approval.

### runtime/ — Executor Metadata

Non-portable executor state belongs here: install sentinels, lockfiles, dedupe caches, hook replay protection, temporary outputs, and other metadata that should not travel with the epic.

```
runtime/
├── install-sentinel.json
├── locks/
└── hook-dedupe/
```

`runtime/` SHOULD be gitignored. Tooling MUST treat it as non-authoritative for business facts and SHOULD recreate it safely when missing. Anything required for human or agent resumption belongs in `state.json`, `state/`, `plans/`, `ROADMAP.md`, `DECISIONS.md`, or `log/` instead.

### artifacts/ — Outputs and Deliverables

The things the epic *produces*. Separating artifacts from logs and scripts makes it clear what the epic has delivered.

```
artifacts/
├── api-schema-v1.yaml
├── architecture-diagram.svg
└── pitch-deck-draft-2.pptx
```

## Portability and Round-Tripping

Portable epics should survive copy, export, import, and executor changes without silent rewrites.

### External references

* Repo-tracked files MUST NOT store executor-assigned numeric IDs, database-local IDs, or opaque instance handles when a stable semantic alias is available.
* Credentials and external services SHOULD be referenced by alias or logical name (`primary-openai`, `prod-stripe`, `customer-db`) rather than by host-local identifier.
* Cross-epic references SHOULD use the epic `id` or stable relative workspace paths, not transient runtime identifiers.
* If an epic intentionally depends on a non-portable local binding, that dependency SHOULD be called out explicitly in `EPIC.md` or `policy.yml`.

### Import/export behavior

* The portable export unit is the epic directory excluding `runtime/` and any other explicitly non-portable executor caches.
* Import/export tooling MUST round-trip reserved fields without silent dropping, renaming, or reordering that changes meaning.
* Importing an epic into a new workspace MUST NOT require rewriting stable identifiers such as `EPIC.md.id`.
* Epic-scoped skills, hooks, cron definitions, references, and artifacts are part of the portable unit and SHOULD move with the epic.

## Composability Patterns

### Pattern 1: Shared Skills (Capability Reuse)

Multiple epics can reference the same global skill. Epic-scoped skills override globals of the same name.

### Pattern 2: Epic Workspace (Loose Coordination)

A workspace can coordinate multiple separate epics while keeping them loosely coupled:

```
product-launch/
├── launch-coordination/
│   ├── SKILL.md
│   ├── EPIC.md
│   └── plans/
├── backend-implementation/
├── frontend-implementation/
└── marketing-rollout/
```

### Pattern 3: Epic Chaining (Sequential)

One epic's `status-changed` hook can hand off to the next through the agent or a shared artifact:

```markdown
# hooks/status-changed.md
---
enabled: true
---
This epic's status just changed. If the epic is now complete:
Notify the agent that `customer-onboarding` is ready to begin.
Record the handoff in a shared artifact or workspace-level note.
```

### Pattern 4: Instantiation

To start a new run of a workflow, create working state — populate `state.json` or `state/core.json` with instance details, create an initial plan in `plans/` with first tasks, and begin logging. The workflow definition (`SKILL.md`, `EPIC.md`, `hooks/`, `policy.yml`) stays unchanged. Most epics have one active instance at a time, with working state in the epic directory itself.

## Log Compaction

Over time, logs grow. Agents (or cron jobs) can compact logs:

1. **Summarize** — periodically create `log/YYYY-MM-summary.md` that distills a month of entries
2. **Archive** — move raw entries to `log/archive/YYYY-MM/`
3. **Retain recent** — always keep the last 10-20 entries unarchived

This keeps the log/ directory scannable while preserving full history.

## Relationship to SKILL.md

| Aspect | SKILL.md (standalone) | SKILL.md + EPIC.md |
|--------|----------------------|-------------------|
| Purpose | How to do X | How to do X + track doing X over time |
| State | Stateless | Stateful |
| Lifespan | Permanent | Has a lifecycle (active → complete) |
| Triggering | Description-based | Description-based + state-aware resume |
| Disclosure | 3 levels | 6 levels |
| Scheduling | None | cron.d/ |
| Composition | References only | Separate epics with loose coupling |
| Outputs | Inline | artifacts/ directory |
| Memory | None | log/ + state.json/state/ |
| Constraints | None | policy.yml |

## Minimal Examples

### Bare Minimum (just a stateful skill)

```
my-task/
├── SKILL.md
└── EPIC.md
```

### Minimal Useful Epic

```
my-task/
├── SKILL.md
├── EPIC.md
├── plans/
│   └── 001-initial.md
└── log/
    └── 2026-03-03T10-00-00Z-agent-started.md
```

### Autonomous Epic (agent-driven)

```
my-task/
├── SKILL.md
├── EPIC.md
├── ROADMAP.md
├── plans/
├── state.json
├── log/
├── runtime/
├── cron.d/
│   └── daily-check.yml
├── hooks/
│   └── milestone-complete.d/
│       ├── 010-slack.yml
│       └── 020-review.md
└── policy.yml
```

### Full Epic (all capabilities)

```
my-task/
├── SKILL.md
├── EPIC.md
├── ROADMAP.md
├── DECISIONS.md
├── plans/
├── state/
│   └── core.json
├── log/
├── runtime/
├── cron.d/
├── hooks/
│   └── milestone-complete.d/
│       ├── 010-slack.yml
│       └── 020-review.md
├── policy.yml
├── skills/
├── artifacts/
├── scripts/
├── references/
└── assets/
```
