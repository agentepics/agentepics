# CLI + Claude Code Execution Model for EPICs

## Purpose

This document describes a practical interactive implementation profile for the
split EPIC spec using:

- a standalone `epics` CLI
- Claude Code as the active agent
- Claude Code hooks configured to call `epics`

It is an implementation guide, not a normative spec. The normative sources are:

- [Epic specification](../docs/epic-specification.mdx)
- [Epic runtime specification](../docs/epic-runtime.mdx)

Host-tool background:

- [Hook systems across AI coding CLI tools](./cli-hooks.md)

## Framing

The key premise is:

**`epics` is a safe convenience path, not the definition of EPIC semantics.**

That means:

- Claude Code may still read and write files directly.
- The EPIC standard is defined by the spec docs, not by the CLI.
- The `epics` CLI should make compliant behavior easier, especially around
  resumption, validation, logging, and serialized writes.
- Claude Code hooks can improve lifecycle integration, but they do not redefine
  hooks, policy, or state semantics from the spec.

## What This Model Can Claim

The Claude-integrated CLI model is best understood as:

- a solid **read-only loader**
- a practical **interactive executor**
- a **partial runtime executor** for selected runtime-spec surfaces

It is not, by itself, a full autonomous executor.

## Core obligations that still apply

Even in an interactive Claude session, the implementation must preserve these
spec rules:

- `policy.yml`, when present, is loaded at activation and treated as a hard
  constraint
- `state/core.json` is authoritative over `state.json` whenever `state/` exists
- the plan wins for intent and the state file wins for facts
- agents should not rewrite configuration or immutable-tier files during normal
  operation
- configured runtime features cannot be silently downgraded into SKILL.md advice

If a feature from the runtime specification is unsupported, the implementation should
surface that limitation explicitly.

## Practical architecture

```text
Claude Code
- follows SKILL.md instructions
- can call `epics` through Bash
- may still edit files directly
- receives lifecycle help from Claude hooks

epics CLI
- scaffolds and validates epics
- assembles resumption context
- provides safe helpers for state, plans, and logs
- can explicitly dispatch EPIC runtime hooks

Claude hooks
- SessionStart -> `epics resume`
- Stop -> `epics log-session`
- optional PreToolUse/PostToolUse -> warnings or validation helpers
```

Recommended boundary:

- direct edits remain possible
- `epics` should be the preferred path for writes to `plans/`, `state.json` or
  `state/`, and generated log entries so it can preserve unknown fields and use
  per-epic serialization

## Command surface

### Core commands

| Command | Role |
|---|---|
| `epics init` | Scaffold `SKILL.md`, `EPIC.md`, and optional starter folders |
| `epics resume` | Assemble disclosure Levels 1-4 into a resume bundle |
| `epics validate` | Validate core and runtime EPIC files |
| `epics status` | Read or update lifecycle status |
| `epics hooks setup` | Write Claude hook configuration that bridges host events to `epics` |

### Safe helper commands

| Command | Role |
|---|---|
| `epics state get/set` | Resolve `state/core.json` first, preserve unknown fields, and write atomically |
| `epics plan create` | Create correctly shaped plan files with numbering |
| `epics plan current` | Resolve `current_plan` versus latest modified plan |
| `epics plan list` | Make plan navigation predictable |
| `epics log create` | Generate correctly timestamped log files and frontmatter |
| `epics log recent` | Provide continuity view for resumption |
| `epics log-session` | Summarize a completed session into one or more epic logs |

### Runtime-aware commands

| Command | Role |
|---|---|
| `epics hooks fire <trigger>` | Explicitly dispatch EPIC runtime hooks |
| `epics cron list` | Enumerate cron definitions |
| `epics cron validate` | Validate cron definition structure |

## What Claude hooks help with

Claude Code hooks are useful for session lifecycle integration:

| Claude hook | `epics` action | Outcome |
|---|---|---|
| `SessionStart` | `epics resume --format claude-context` | Auto-load EPIC resumption context |
| `Stop` | `epics log-session --auto` | Create session-end log entries |
| `PreToolUse` on writes | optional validation or warning command | Encourage mutability-tier awareness |
| `PostToolUse` on key files | optional reconcile helpers | Detect useful follow-up work |

Useful hook behavior in this model:

- reducing manual ceremony
- making resumption more consistent
- making logging more consistent
- warning about likely mistakes

Limitations:

- Claude hooks do not make `epics` the only write path
- Claude hooks do not automatically provide a full file-edited event stream
- Claude hooks do not replace an external scheduler for `cron.d/`

## Runtime features in the Claude-integrated model

| Runtime feature | Status in this model | Notes |
|---|---|---|
| `policy.yml` loading | Supported | Must happen at activation, even in interactive mode |
| `state/core.json` precedence | Supported | CLI helpers should always resolve split state first |
| explicit `hooks/` dispatch | Supported | `epics hooks fire` can honor runtime semantics |
| automatic condition-triggered hooks | Partial | Depends on what the host can reliably observe |
| `cron.d/` validation | Supported | Straightforward CLI validation |
| `cron.d/` scheduling | Not provided | Requires external scheduler or stronger executor |
| `runtime/` sentinels and lock files | Supported | CLI can manage non-portable executor state |
| full policy enforcement on arbitrary direct edits | Partial | Host limitations remain |

Important rule:

- if an epic defines runtime hooks for conditions the host cannot reliably
  observe, the implementation should say so rather than implying that SKILL.md
  instructions are an equivalent runtime dispatch mechanism

## What belongs in SKILL.md here

SKILL.md remains important, but as agent guidance:

- how to interpret the epic
- how to work within the epic's domain
- what to do when the current plan is exhausted
- how to handle blockers and conflicts
- how to use the CLI helpers

SKILL.md guidance can complement runtime behavior. It should not be presented as
a substitute for configured `hooks/` or `policy.yml`.

## Recommended hook setup

For a single active epic:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "epics resume --format claude-context",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "epics log-session --auto",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

For multi-epic workspaces, prefer loading Level 1 summaries for active epics at
session start and deferring full `epics resume <epic-path>` until the agent has
identified which epic to engage.

## Bottom line

The Claude + CLI model can implement most of the EPIC standard's interactive
value today:

- scaffolding
- resumption
- validation
- safe state and plan helpers
- log workflows
- session lifecycle integration

What it does not guarantee on its own:

- total write mediation
- guaranteed automatic dispatch for every runtime trigger
- unattended cron execution
- hard enforcement over every direct file edit

Those remain responsibilities of stronger executors. The important thing is to
describe those limits as implementation limits, not as changes to the EPIC
standard.
