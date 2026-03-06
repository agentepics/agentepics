#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")"/generate-proposals.sh \
  "reference/skills" \
  "reference/skills/proposals-prompt.md" \
  "reference/skills/Research-Claude.md" \
  "reference/skills/Research-GPT.md"
