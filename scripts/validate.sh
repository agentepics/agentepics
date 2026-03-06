#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

echo "Checking shell syntax..."
bash -n scripts/generate-proposals.sh
bash -n scripts/generate-mcp-proposals.sh
bash -n scripts/generate-skills-proposals.sh
bash -n scripts/validate.sh

echo "Checking generated-output ignore rules..."
git check-ignore -q "reference/mcp/Proposals-Claude.md"
git check-ignore -q "reference/mcp/Proposals-GPT.md"
git check-ignore -q "reference/skills/Proposals-Claude.md"
git check-ignore -q "reference/skills/Proposals-GPT.md"

echo "Checking maintainer guidance..."
if awk '/The version appears on line/ { found=1 } END { exit found ? 0 : 1 }' CLAUDE.md; then
  echo "ERROR: stale line-number guidance remains in CLAUDE.md" >&2
  exit 1
fi

echo "Checking split EPIC docs..."
for path in \
  "EPIC-STANDARD.md" \
  "EPIC-RUNTIME.md" \
  "EPIC-EXAMPLES.md" \
  "EPIC-STANDARD.original.md" \
  "reference/SKILL-STANDARD.md" \
  "reference/epic-spec-parity-checklist.md"
do
  if [ ! -f "$path" ]; then
    echo "ERROR: required split-doc file is missing: $path" >&2
    exit 1
  fi
done

echo "Checking parity checklist..."
if awk '
  /^\|---/ { next }
  /^\|/ && $0 !~ /Status/ && $0 !~ /\| verified \|$/ { bad=1 }
  END { exit bad ? 0 : 1 }
' reference/epic-spec-parity-checklist.md
then
  echo "ERROR: parity checklist contains non-verified rows" >&2
  exit 1
fi

STUB_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$STUB_DIR"
  rm -f \
    "reference/mcp/Proposals-Claude.md" \
    "reference/mcp/Proposals-GPT.md" \
    "reference/skills/Proposals-Claude.md" \
    "reference/skills/Proposals-GPT.md"
}
trap cleanup EXIT

cat > "$STUB_DIR/claude" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
if [ -n "${STUB_CLAUDE_OUTPUT:-}" ]; then
  printf '%s\n' "$STUB_CLAUDE_OUTPUT"
fi
exit "${STUB_CLAUDE_EXIT:-0}"
EOF

cat > "$STUB_DIR/codex" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
if [ -n "${STUB_CODEX_OUTPUT:-}" ]; then
  printf '%s\n' "$STUB_CODEX_OUTPUT"
fi
exit "${STUB_CODEX_EXIT:-0}"
EOF

chmod +x "$STUB_DIR/claude" "$STUB_DIR/codex"

echo "Running failure smoke test..."
printf 'keep-claude\n' > "reference/mcp/Proposals-Claude.md"
printf 'keep-codex\n' > "reference/mcp/Proposals-GPT.md"

if CLAUDE_BIN="$STUB_DIR/claude" CODEX_BIN="$STUB_DIR/codex" STUB_CLAUDE_EXIT=1 ./scripts/generate-mcp-proposals.sh; then
  echo "ERROR: failure smoke test unexpectedly succeeded" >&2
  exit 1
fi

if [ "$(cat "reference/mcp/Proposals-Claude.md")" != "keep-claude" ]; then
  echo "ERROR: Claude output changed during failure smoke test" >&2
  exit 1
fi

if [ "$(cat "reference/mcp/Proposals-GPT.md")" != "keep-codex" ]; then
  echo "ERROR: GPT output changed during failure smoke test" >&2
  exit 1
fi

echo "Running success smoke tests..."
CLAUDE_BIN="$STUB_DIR/claude" \
CODEX_BIN="$STUB_DIR/codex" \
STUB_CLAUDE_OUTPUT="stub claude output" \
STUB_CODEX_OUTPUT="stub codex output" \
./scripts/generate-mcp-proposals.sh

CLAUDE_BIN="$STUB_DIR/claude" \
CODEX_BIN="$STUB_DIR/codex" \
STUB_CLAUDE_OUTPUT="skills claude output" \
STUB_CODEX_OUTPUT="skills codex output" \
./scripts/generate-skills-proposals.sh

if [ "$(cat "reference/mcp/Proposals-Claude.md")" != "stub claude output" ]; then
  echo "ERROR: MCP Claude success smoke test did not write expected output" >&2
  exit 1
fi

if [ "$(cat "reference/mcp/Proposals-GPT.md")" != "stub codex output" ]; then
  echo "ERROR: MCP GPT success smoke test did not write expected output" >&2
  exit 1
fi

if [ "$(cat "reference/skills/Proposals-Claude.md")" != "skills claude output" ]; then
  echo "ERROR: skills Claude success smoke test did not write expected output" >&2
  exit 1
fi

if [ "$(cat "reference/skills/Proposals-GPT.md")" != "skills codex output" ]; then
  echo "ERROR: skills GPT success smoke test did not write expected output" >&2
  exit 1
fi

echo "Validation passed."
