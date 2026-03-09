# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository. The project defines Agent Epics and keeps `SKILL.md`
material as a compatibility reference.

## Documentation

The Agent Epics documentation site, defined in the `docs/` directory, is built with [Mintlify](https://mintlify.com).

### Quick Start Commands

```bash
# Run local development server
npm run dev
```

Local preview available at `http://localhost:3000`

### Development Notes

- **Navigation**: Defined in `docs/docs.json` under `navigation.pages` array
- **Adding pages**: Create the `.mdx` file in the matching docs subdirectory and add its route (without extension) to `docs/docs.json`
- **Deployment**: Automatic on push to `main` branch
- **Troubleshooting**: If page shows 404, ensure you're running `mint dev` from directory containing `docs.json`
