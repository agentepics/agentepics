# Agent Epics

[Agent Epics](https://agentepics.io) is an open format for durable agent
systems. It builds on `SKILL.md` compatibility and adds plans, structured
state, logs, decisions, hooks, cron, and policy for reusable workflows,
autonomous operators, and installed capabilities.

## Getting Started

- [Documentation](https://agentepics.io) - Guides and tutorials
- [Epic Specification](https://agentepics.io/epic-specification) - Core EPIC format details
- [Epic Runtime](https://agentepics.io/epic-runtime) - Hooks, cron, policy, and executor semantics
- [Epic Examples](https://agentepics.io/epic-examples) - Layouts, patterns, and worked examples
- [Epic Reference](https://agentepics.io/specification) - Main EPIC reference entry point
- [SKILL.md Reference](https://agentepics.io/skill-specification) - Compatibility details for the underlying format

This repo contains the EPIC specification, documentation site, compatibility
references, and the reference SDK. The canonical EPIC specification source
lives in `docs/`.

## About

`SKILL.md` was originally developed by [Anthropic](https://anthropic.com) and
released as an open format. Agent Epics extends that substrate with durable
state, automation, and capability packaging and is maintained in this repo.

## License

Code in this repository is licensed under [Apache 2.0](LICENSE). Documentation
is licensed under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).
See individual directories for details.
