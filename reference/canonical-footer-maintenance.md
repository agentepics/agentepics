# Canonical Footer Maintenance Checklist

Use this checklist when changing the canonical Agent Epics `SKILL.md` footer.

## Canonical source

1. Update [footer.md](../footer.md) in this repo first.
2. If the canonical footer URL changes, verify the new URL is live on GitHub
   before treating it as canonical.
3. Update any spec or migration pages in this repo that inline the marker or
   describe the footer behavior:
   - [docs/epic-specification.mdx](../docs/epic-specification.mdx)
   - [docs/epic-migration-0-5-2.mdx](../docs/epic-migration-0-5-2.mdx)
   - any other page that quotes the marker or canonical URL

## CLI and validator repo

4. Sync the local footer copy in `epics.sh` with:
   - `./scripts/sync-canonical-footer.sh` from the `epics.sh` repo root, or
   - `./scripts/sync-canonical-footer.sh <path-to-agentepics/footer.md>` when
     the canonical repo is not checked out as a sibling at `../agentepics`
5. Confirm the synced file
   [epics.sh/internal/epic/footer.md](../../epics.sh/internal/epic/footer.md)
   matches [footer.md](../footer.md).
6. Update any `epics.sh` docs that describe the footer marker, footer refresh
   flow, or validation behavior.
7. Run `epics upgrade-skill-footer` against the maintained fixture epics in
   `epics.sh/examples/fixtures/` that embed the footer.

## Curated epics repo

8. Run `epics upgrade-skill-footer` against every published epic in the
   `epics` repo so the local `SKILL.md` copies match the canonical footer
   exactly.

## Generated copies

9. Refresh any generated or embedded copies:
   - `epics.sh/examples/fixtures/*/SKILL.md`
   - `epics.sh/registry/epics/*.json` `skillMd` snapshots

## Validation

10. Run the relevant `epics.sh` tests, at minimum:
   - `go test ./internal/epic ./internal/cli`
11. Run `epics validate` against at least:
   - one curated epic from the `epics` repo
   - one fixture epic from `epics.sh/examples/fixtures/`
12. Confirm the canonical footer URL and any linked installer URL return live
    content from GitHub after push.

## Versioning

13. If the footer text changes but the EPIC spec version does not, keep the
    version constant and still refresh all propagated copies.
14. If the marker semantics or validation contract change, document the
    migration explicitly in the spec docs.
