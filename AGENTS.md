# AGENTS.md

Repository guidance for agents working in this repo.

## Repo

- This repo is the source of truth for Agent Epics and carries `SKILL.md`
  compatibility references.
- The canonical EPIC spec source lives in `docs/`:
  - `docs/epic-specification.mdx`
  - `docs/epic-runtime.mdx`
  - `docs/epic-examples.mdx`
- Reference and migration artifacts live in `reference/`:
  - `reference/epic-spec-parity-checklist.md`
  - `reference/SKILL-STANDARD.md`
- Reference Python library: `skills-ref/`

## Rules

- Keep backward compatibility with the `SKILL.md` standard.
- Keep `state/core.json` authoritative over `state.json` whenever `state/`
  exists.
- Keep `policy.yml`, when present, treated as a hard constraint across the spec
  and implementation guides.
- Use ISO 8601 with timezone for machine-readable timestamps.
- Keep log filenames in `YYYY-MM-DDTHH-MM-SSZ-{actor}-{slug}.md` format.

## Workflow

- Run `./scripts/validate.sh` after changing EPIC docs, proposal scripts, or
  maintainer docs.
- Keep the EPIC version headers synchronized across the canonical docs pages.
- Run `npm run dev` (or `cd docs && npx mint dev`) to preview the docs site.
