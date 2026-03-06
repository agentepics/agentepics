# CLAUDE.md

Repository guidance for Claude Code.

## Repo

- This is a merged repo: Agent Skills spec + Agent Epics extension.
- Documentation site built with Mintlify, source in `docs/`.
- Live EPIC docs at repo root:
  - `EPIC-STANDARD.md`
  - `EPIC-RUNTIME.md`
  - `EPIC-EXAMPLES.md`
- Parity baseline:
  - `EPIC-STANDARD.original.md`
- Referenced skill spec:
  - `reference/SKILL-STANDARD.md`
- Canonical skill spec rendered as docs:
  - `docs/specification.mdx`
- Reference Python library:
  - `skills-ref/`

## Rules

- Keep backward compatibility with the SKILL standard.
- Preserve semantic parity with `EPIC-STANDARD.original.md` until that baseline
  is intentionally retired.
- Keep core semantics in `EPIC-STANDARD.md` and runtime semantics in
  `EPIC-RUNTIME.md`.
- Keep `state/core.json` authoritative over `state.json` whenever `state/`
  exists.
- Keep `policy.yml`, when present, treated as a hard constraint across the spec
  and implementation guides.
- Use ISO 8601 with timezone for machine-readable timestamps.
- Keep log filenames in `YYYY-MM-DDTHH-MM-SSZ-{actor}-{slug}.md` format.
- "Agent Skills" as a concept name stays in the skills docs. Only the
  site/org brand is "Agent Epics".

## Workflow

- Run `./scripts/validate.sh` after changing EPIC docs, proposal scripts, or
  maintainer docs.
- Keep version headers in `EPIC-STANDARD.md` and `EPIC-RUNTIME.md`
  synchronized.
- Do not edit the preserved version header in `EPIC-STANDARD.original.md`.
- Run `npm run dev` (or `cd docs && npx mint dev`) to preview the docs site
  locally at `http://localhost:3000`.

## Docs Site

- Navigation defined in `docs/docs.json` under `navigation.pages`.
- Adding pages: create `.mdx` file in `docs/`, add to navigation.
- Deployment: automatic on push to `main` branch.
