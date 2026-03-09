#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <output-dir> <prompt-file> <claude-research-file> <gpt-research-file>" >&2
  exit 2
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

OUTPUT_DIR=$1
PROMPT_FILE=$2
CLAUDE_RESEARCH=$3
GPT_RESEARCH=$4

CLAUDE_BIN=${CLAUDE_BIN:-claude}
CODEX_BIN=${CODEX_BIN:-codex}

for cmd in "$CLAUDE_BIN" "$CODEX_BIN"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  fi
done

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PROMPT_PATH="$TMP_DIR/prompt.txt"
CLAUDE_TMP="$TMP_DIR/claude.out"
GPT_TMP="$TMP_DIR/gpt.out"
CLAUDE_OUT="$OUTPUT_DIR/Proposals-Claude.md"
GPT_OUT="$OUTPUT_DIR/Proposals-GPT.md"

{
  cat "$PROMPT_FILE"
  printf '\n\n--- EPIC STANDARD ---\n'
  cat docs/epic-specification.mdx
  printf '\n\n--- EPIC RUNTIME ---\n'
  cat docs/epic-runtime.mdx
  printf '\n\n--- SKILL STANDARD ---\n'
  cat reference/SKILL-STANDARD.md
  printf '\n\n--- RESEARCH (Claude) ---\n'
  cat "$CLAUDE_RESEARCH"
  printf '\n\n--- RESEARCH (GPT) ---\n'
  cat "$GPT_RESEARCH"
} > "$PROMPT_PATH"

echo "Generating proposals..."
echo "  Claude -> ${CLAUDE_OUT}"
echo "  GPT    -> ${GPT_OUT}"

CLAUDECODE= "$CLAUDE_BIN" --dangerously-skip-permissions -p < "$PROMPT_PATH" > "$CLAUDE_TMP" &
PID_CLAUDE=$!

"$CODEX_BIN" exec -c model="gpt-5.4" -c model_reasoning_effort="xhigh" - < "$PROMPT_PATH" > "$GPT_TMP" &
PID_GPT=$!

FAIL=0
wait "$PID_CLAUDE" || { echo "ERROR: Claude generation failed" >&2; FAIL=1; }
wait "$PID_GPT" || { echo "ERROR: GPT generation failed" >&2; FAIL=1; }

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

mv "$CLAUDE_TMP" "$CLAUDE_OUT"
mv "$GPT_TMP" "$GPT_OUT"

echo "Done. Generated:"
echo "  $(wc -l < "$CLAUDE_OUT") lines in ${CLAUDE_OUT}"
echo "  $(wc -l < "$GPT_OUT") lines in ${GPT_OUT}"
