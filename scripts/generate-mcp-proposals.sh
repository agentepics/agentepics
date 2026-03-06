#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")"/generate-proposals.sh \
  "reference/mcp" \
  "reference/mcp/proposals-prompt.md" \
  "reference/mcp/Research-Claude.md" \
  "reference/mcp/Research-GPT.md"
