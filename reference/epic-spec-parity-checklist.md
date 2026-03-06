# EPIC Spec Parity Checklist

This checklist maps the preserved monolith in `EPIC-STANDARD.original.md` to the
split `v0.5.0` doc set.

Validation rule: every row must have `Status = verified`.

| Original section | Original lines | Destination | Classification | Status |
|---|---:|---|---|---|
| Specification header and framing | 1-10 | `EPIC-STANDARD.md` intro | normative-core | verified |
| Design Principles | 12-20 | `EPIC-STANDARD.md#design-principles` | normative-core | verified |
| Epic Archetypes | 21-29 | `EPIC-STANDARD.md#epic-archetypes` | normative-core | verified |
| Conventions | 31-40 | `EPIC-STANDARD.md#conventions` | normative-core | verified |
| Anatomy of an Epic | 42-81 | `EPIC-STANDARD.md#anatomy-of-an-epic`, `EPIC-EXAMPLES.md#directory-trees` | mixed | verified |
| What's Required | 83-85 | `EPIC-STANDARD.md#whats-required` | normative-core | verified |
| Mutability Tiers | 87-102 | `EPIC-STANDARD.md#mutability-tiers` | normative-core | verified |
| Authoritative Files | 104-118 | `EPIC-STANDARD.md#authoritative-files` | normative-core | verified |
| SKILL.md — Routing and Instructions | 120-138 | `EPIC-STANDARD.md#skillmd--routing-and-instructions` | normative-core | verified |
| EPIC.md — Stateful Context | 140-169 | `EPIC-STANDARD.md#epicmd--stateful-context` | normative-core | verified |
| Progressive Disclosure | 171-186 | `EPIC-STANDARD.md#progressive-disclosure` | normative-core | verified |
| Resumption Sequence | 188-200 | `EPIC-STANDARD.md#resumption-sequence` | normative-core | verified |
| Validation and Compatibility | 202-235 | `EPIC-STANDARD.md#validation-and-compatibility` | normative-core | verified |
| ROADMAP.md — Strategic Intent | 238-270 | `EPIC-STANDARD.md#roadmapmd--strategic-intent`, `EPIC-EXAMPLES.md#roadmap-example` | mixed | verified |
| DECISIONS.md — Decision Records | 272-295 | `EPIC-STANDARD.md#decisionsmd--decision-records`, `EPIC-EXAMPLES.md#decisions-example` | mixed | verified |
| plans/ — Tactical Plans | 297-342 | `EPIC-STANDARD.md#plans--tactical-plans`, `EPIC-EXAMPLES.md#plan-example` | mixed | verified |
| state.json — Structured State | 344-384 | `EPIC-STANDARD.md#statejson-and-state--structured-state`, `EPIC-EXAMPLES.md#statejson-example` | mixed | verified |
| log/ — Activity History | 385-428 | `EPIC-STANDARD.md#log--activity-history`, `EPIC-EXAMPLES.md#log-example` | mixed | verified |
| cron.d/ — Recurring Tasks | 430-460 | `EPIC-RUNTIME.md#crond--recurring-tasks`, `EPIC-EXAMPLES.md#crond-example` | normative-runtime | verified |
| skills/ — Epic-Scoped Skills | 462-474 | `EPIC-STANDARD.md#skills--epic-scoped-skills` | normative-core | verified |
| hooks/ — Event-Triggered Actions | 476-709 | `EPIC-RUNTIME.md#hooks--event-triggered-actions`, `EPIC-EXAMPLES.md#hooks-examples` | normative-runtime | verified |
| policy.yml — Constraints for Autonomous Operation | 710-756 | `EPIC-RUNTIME.md#policyyml--constraints-for-autonomous-operation`, `EPIC-EXAMPLES.md#policyyml-example` | normative-runtime | verified |
| runtime/ — Executor Metadata | 758-769 | `EPIC-RUNTIME.md#runtime--executor-metadata` | normative-runtime | verified |
| artifacts/ — Outputs and Deliverables | 771-780 | `EPIC-STANDARD.md#artifacts--outputs-and-deliverables` | normative-core | verified |
| Portability and Round-Tripping | 782-799 | `EPIC-STANDARD.md#portability-and-round-tripping` | normative-core | verified |
| Composability Patterns | 800-838 | `EPIC-EXAMPLES.md#composability-patterns` | non-normative-example | verified |
| Log Compaction | 839-847 | `EPIC-EXAMPLES.md#log-compaction` | non-normative-example | verified |
| Relationship to SKILL.md | 849-863 | `EPIC-STANDARD.md#relationship-to-skillmd` | normative-core | verified |
| Minimal Examples | 864-930 | `EPIC-EXAMPLES.md#directory-trees` | non-normative-example | verified |
