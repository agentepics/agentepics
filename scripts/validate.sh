#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

echo "Checking shell syntax..."
bash -n scripts/generate-proposals.sh
bash -n scripts/generate-mcp-proposals.sh
bash -n scripts/generate-skills-proposals.sh
bash -n scripts/validate-epic.sh
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

echo "Checking canonical footer drift..."
if [ -d "../epics.sh" ] && command -v go >/dev/null 2>&1; then
  (
    cd ../epics.sh
    go test ./internal/epic -run TestCanonicalSkillFooterMatchesAgentepicsFooterWhenAvailable -count=1
  )
elif [ -d "../epics.sh" ]; then
  echo "Skipping canonical footer drift check (go not installed)..."
else
  echo "Skipping canonical footer drift check (../epics.sh not present)..."
fi

echo "Checking split EPIC docs..."
for path in \
  "docs/epic-specification.mdx" \
  "docs/epic-scripting.mdx" \
  "docs/epic-examples.mdx" \
  "reference/SKILL-STANDARD.md" \
  "reference/epic-spec-parity-checklist.md"
do
  if [ ! -f "$path" ]; then
    echo "ERROR: required split-doc file is missing: $path" >&2
    exit 1
  fi
done

echo "Checking root EPIC spec mirrors are gone..."
for path in \
  "EPIC-STANDARD.md" \
  "EPIC-RUNTIME.md" \
  "EPIC-EXAMPLES.md"
do
  if [ -e "$path" ]; then
    echo "ERROR: root EPIC spec mirror still exists: $path" >&2
    exit 1
  fi
done

echo "Checking EPIC docs navigation..."
while IFS= read -r page; do
  if [ ! -f "docs/${page}.mdx" ]; then
    echo "ERROR: docs/docs.json references missing page: docs/${page}.mdx" >&2
    exit 1
  fi
done < <(
  node <<'EOF'
const fs = require("fs");

const docs = JSON.parse(fs.readFileSync("docs/docs.json", "utf8"));

function visit(items) {
  for (const item of items) {
    if (typeof item === "string") {
      console.log(item);
      continue;
    }
    if (item && Array.isArray(item.pages)) {
      visit(item.pages);
    }
  }
}

visit(docs.navigation.pages);
EOF
)

for page in \
  "epic-specification" \
  "epic-scripting" \
  "epic-examples"
do
  if ! awk -v page="\"$page\"" 'index($0, page) { found=1 } END { exit found ? 0 : 1 }' docs/docs.json; then
    echo "ERROR: docs/docs.json is missing EPIC page entry: \"$page\"" >&2
    exit 1
  fi
done

echo "Validating docs build..."
docs_validate_attempt=1
until (cd docs && npx mint validate); do
  if [ "$docs_validate_attempt" -ge 3 ]; then
    echo "ERROR: docs validation failed after ${docs_validate_attempt} attempts" >&2
    exit 1
  fi
  docs_validate_attempt=$((docs_validate_attempt + 1))
  echo "Retrying docs validation (attempt ${docs_validate_attempt}/3)..." >&2
done

echo "Checking docs routes..."
ROUTE_CHECK_LOG=$(mktemp)
ROUTE_CHECK_PID=""
ROUTE_CHECK_BASE_URL=""

cleanup_route_preview() {
  if [ -n "${ROUTE_CHECK_PID:-}" ] && kill -0 "$ROUTE_CHECK_PID" 2>/dev/null; then
    kill "$ROUTE_CHECK_PID" 2>/dev/null || true
    wait "$ROUTE_CHECK_PID" 2>/dev/null || true
  fi
  rm -f "$ROUTE_CHECK_LOG"
}

trap cleanup_route_preview EXIT

(
  cd docs
  npx --yes mint dev >"$ROUTE_CHECK_LOG" 2>&1
) &
ROUTE_CHECK_PID=$!

route_preview_ready=0
for _ in $(seq 1 60); do
  if ! kill -0 "$ROUTE_CHECK_PID" 2>/dev/null; then
    echo "ERROR: docs preview exited before route checks" >&2
    cat "$ROUTE_CHECK_LOG" >&2
    exit 1
  fi

  ROUTE_CHECK_BASE_URL=$(grep -Eo 'http://localhost:[0-9]+' "$ROUTE_CHECK_LOG" | tail -n 1 || true)

  if [ -n "${ROUTE_CHECK_BASE_URL:-}" ] && curl -fsS -o /dev/null "${ROUTE_CHECK_BASE_URL}/home"; then
    route_preview_ready=1
    break
  fi

  sleep 1
done

if [ "$route_preview_ready" -ne 1 ]; then
  echo "ERROR: docs preview did not become ready for route checks" >&2
  cat "$ROUTE_CHECK_LOG" >&2
  exit 1
fi

echo "Using docs preview at $ROUTE_CHECK_BASE_URL for route checks..."
route_check_attempt=1
until BASE_URL="$ROUTE_CHECK_BASE_URL" bash scripts/check-doc-routes.sh; do
  if [ "$route_check_attempt" -ge 10 ]; then
    echo "ERROR: docs route checks failed after ${route_check_attempt} attempts" >&2
    exit 1
  fi
  route_check_attempt=$((route_check_attempt + 1))
  echo "Retrying docs route checks (attempt ${route_check_attempt}/10)..." >&2
  sleep 2
done

cleanup_route_preview
trap - EXIT

echo "Checking EPIC version headers..."
EXPECTED_VERSION=$(awk '
  /^\*\*Version / {
    gsub(/^\*\*Version /, "", $0)
    gsub(/\*\*$/, "", $0)
    print
    exit
  }
' docs/epic-specification.mdx)

if [ -z "${EXPECTED_VERSION:-}" ]; then
  echo "ERROR: could not determine EPIC version from docs/epic-specification.mdx" >&2
  exit 1
fi

for path in \
  "docs/epic-scripting.mdx" \
  "docs/epic-examples.mdx"
do
  VERSION=$(awk '
    /^\*\*Version / {
      gsub(/^\*\*Version /, "", $0)
      gsub(/\*\*$/, "", $0)
      print
      exit
    }
  ' "$path")

  if [ "$VERSION" != "$EXPECTED_VERSION" ]; then
    echo "ERROR: version header mismatch in $path (expected $EXPECTED_VERSION, found ${VERSION:-<missing>})" >&2
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
