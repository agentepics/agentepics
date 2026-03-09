# EPIC Spec Parity Checklist

This checklist maps the legacy monolithic EPIC spec to the split `v0.5.1`
docs-canonical EPIC spec.

Validation rule: every row must have `Status = verified`.

| Original section | Original lines | Destination | Classification | Status |
|---|---:|---|---|---|
| Specification header and framing | 1-10 | `docs/epic-specification.mdx` intro | normative-core | verified |
| Design Principles | 12-20 | `docs/epic-specification.mdx#design-principles` | normative-core | verified |
| Epic Archetypes | 21-29 | `docs/epic-specification.mdx#epic-archetypes` | normative-core | verified |
| Conventions | 31-40 | `docs/epic-specification.mdx#conventions` | normative-core | verified |
| Anatomy of an Epic | 42-81 | `docs/epic-specification.mdx#anatomy-of-an-epic`, `docs/epic-examples.mdx#directory-trees` | mixed | verified |
| What's Required | 83-85 | `docs/epic-specification.mdx#whats-required` | normative-core | verified |
| Mutability Tiers | 87-102 | `docs/epic-specification.mdx#mutability-tiers` | normative-core | verified |
| Authoritative Files | 104-118 | `docs/epic-specification.mdx#authoritative-files` | normative-core | verified |
| SKILL.md — Routing and Instructions | 120-138 | `docs/epic-specification.mdx#skillmd--routing-and-instructions` | normative-core | verified |
| EPIC.md — Stateful Context | 140-169 | `docs/epic-specification.mdx#epicmd--stateful-context` | normative-core | verified |
| Progressive Disclosure | 171-186 | `docs/epic-specification.mdx#progressive-disclosure` | normative-core | verified |
| Resumption Sequence | 188-200 | `docs/epic-specification.mdx#resumption-sequence` | normative-core | verified |
| Validation and Compatibility | 202-235 | `docs/epic-specification.mdx#validation-and-compatibility` | normative-core | verified |
| runtime/ROADMAP.md — Strategic Intent | 238-270 | `docs/epic-specification.mdx#runtimeroadmapmd--strategic-intent`, `docs/epic-examples.mdx#runtimeroadmapmd-example` | mixed | verified |
| runtime/DECISIONS.md — Decision Records | 272-295 | `docs/epic-specification.mdx#runtimedecisionsmd--decision-records`, `docs/epic-examples.mdx#runtimedecisionsmd-example` | mixed | verified |
| runtime/plans/ — Tactical Plans | 297-342 | `docs/epic-specification.mdx#runtimeplans--tactical-plans`, `docs/epic-examples.mdx#plan-example` | mixed | verified |
| runtime/state.json — Structured State | 344-384 | `docs/epic-specification.mdx#runtimestatejson-and-runtimestate--structured-state`, `docs/epic-examples.mdx#runtimestatejson-example` | mixed | verified |
| runtime/log/ — Activity History | 385-428 | `docs/epic-specification.mdx#runtimelog--activity-history`, `docs/epic-examples.mdx#runtimelog-example` | mixed | verified |
| cron.d/ — Recurring Tasks | 430-460 | `docs/epic-runtime.mdx#crond--recurring-tasks`, `docs/epic-examples.mdx#crond-example` | normative-runtime | verified |
| skills/ — Epic-Scoped Skills | 462-474 | `docs/epic-specification.mdx#skills--epic-scoped-skills` | normative-core | verified |
| hooks/ — Event-Triggered Actions | 476-709 | `docs/epic-runtime.mdx#hooks--event-triggered-actions`, `docs/epic-examples.mdx#hooks-examples` | normative-runtime | verified |
| policy.yml — Constraints for Autonomous Operation | 710-756 | `docs/epic-runtime.mdx#policyyml--constraints-for-autonomous-operation`, `docs/epic-examples.mdx#policyyml-example` | normative-runtime | verified |
| runtime/ — Live Instance Tree | 758-769 | `docs/epic-runtime.mdx#runtime--live-instance-tree` | normative-runtime | verified |
| runtime/artifacts/ — Outputs and Deliverables | 771-780 | `docs/epic-specification.mdx#runtimeartifacts--outputs-and-deliverables` | normative-core | verified |
| Portability and Round-Tripping | 782-799 | `docs/epic-specification.mdx#portability-and-round-tripping` | normative-core | verified |
| Composability Patterns | 800-838 | `docs/epic-examples.mdx#composability-patterns` | non-normative-example | verified |
| Log Compaction | 839-847 | `docs/epic-examples.mdx#log-compaction` | non-normative-example | verified |
| Relationship to SKILL.md | 849-863 | `docs/epic-specification.mdx#relationship-to-skillmd` | normative-core | verified |
| Minimal Examples | 864-930 | `docs/epic-examples.mdx#directory-trees` | non-normative-example | verified |
