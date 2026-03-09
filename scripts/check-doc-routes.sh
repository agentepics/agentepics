#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

BASE_URL=${BASE_URL:-http://localhost:3000}
LOG_DIR=${LOG_DIR:-"$ROOT_DIR/.tmp"}
LOG_FILE=${LOG_FILE:-"$LOG_DIR/doc-route-errors.log"}

mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

expected_content_for_route() {
  case "$1" in
    /home) printf '%s\n' "<title>Overview - Agent Epics</title>" ;;
    /specification) printf '%s\n' "<title>Epic Reference - Agent Epics</title>" ;;
    /epic-creation/getting-started) printf '%s\n' "<title>Epic creation - Agent Epics</title>" ;;
    /epic-creation/evaluating-epics) printf '%s\n' "<title>Evaluating epics - Agent Epics</title>" ;;
    /epic-creation/using-scripts) printf '%s\n' "<title>Using scripts in epics - Agent Epics</title>" ;;
    /client-implementation/add-epics-support) printf '%s\n' "<title>How to add EPIC support to your coding agent harness - Agent Epics</title>" ;;
    *) return 1 ;;
  esac
}

expected_redirect_for_route() {
  case "$1" in
    /integrate-skills) printf '%s\n' "/client-implementation/add-epics-support" ;;
    /client-implementation/adding-skills-support) printf '%s\n' "/client-implementation/add-epics-support" ;;
    /skill-creation/evaluating-skills) printf '%s\n' "/epic-creation/evaluating-epics" ;;
    /skill-creation/using-scripts) printf '%s\n' "/epic-creation/using-scripts" ;;
    *) return 1 ;;
  esac
}

mapfile -t ROUTES < <(
  node <<'EOF'
const fs = require("fs");

const docs = JSON.parse(fs.readFileSync("docs/docs.json", "utf8"));
const seen = new Set();

function emit(kind, route) {
  if (!route.startsWith("/")) route = `/${route}`;
  const key = `${kind} ${route}`;
  if (seen.has(key)) return;
  seen.add(key);
  console.log(`${kind}\t${route}`);
}

function visit(items) {
  for (const item of items) {
    if (typeof item === "string") {
      emit("page", item);
      continue;
    }
    if (item && Array.isArray(item.pages)) {
      visit(item.pages);
    }
  }
}

visit(docs.navigation.pages);

for (const redirect of docs.redirects || []) {
  if (redirect && typeof redirect.source === "string") {
    emit("redirect", redirect.source);
  }
}
EOF
)

if [ "${#ROUTES[@]}" -eq 0 ]; then
  echo "ERROR: no routes found in docs/docs.json" | tee -a "$LOG_FILE" >&2
  exit 1
fi

echo "Checking ${#ROUTES[@]} docs routes against $BASE_URL"

failures=0

for entry in "${ROUTES[@]}"; do
  kind=${entry%%$'\t'*}
  route=${entry#*$'\t'}
  url="${BASE_URL}${route}"

  headers=$(curl -sS -D - -o /dev/null "$url" || true)
  status=$(printf '%s\n' "$headers" | awk '
    BEGIN { code = "" }
    /^HTTP\/[0-9.]+ [0-9]+/ { code = $2 }
    END { print code }
  ')
  location=$(printf '%s\n' "$headers" | awk '
    tolower($0) ~ /^location:/ {
      sub(/\r$/, "", $0)
      sub(/^[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]:[[:space:]]*/, "", $0)
      print
      exit
    }
  ')

  if [ -z "${status:-}" ]; then
    status="curl_failed"
  fi

  case "$kind:$status" in
    page:2*|redirect:3*)
      printf 'OK    [%s] %s -> %s\n' "$kind" "$route" "$status"
      ;;
    *)
      failures=$((failures + 1))
      {
        printf 'ERROR [%s] %s -> %s\n' "$kind" "$route" "$status"
        if [ -n "${location:-}" ]; then
          printf '  Location: %s\n' "$location"
        fi
        case "$kind" in
          page)
            printf '  Expected a 2xx response for a page route\n'
            ;;
          redirect)
            printf '  Expected a 3xx response for a redirect route\n'
            ;;
        esac
      } | tee -a "$LOG_FILE" >&2
      ;;
  esac

  if [ "$kind" = "page" ] && [[ "$status" == 2* ]] && expected=$(expected_content_for_route "$route"); then
    body=$(curl -fsSL "$url" || true)
    case "$body" in
      *"$expected"*)
        ;;
      *)
      failures=$((failures + 1))
      printf 'ERROR [content] %s missing expected text: %s\n' "$route" "$expected" | tee -a "$LOG_FILE" >&2
        ;;
    esac
  fi

  if [ "$kind" = "redirect" ] && [[ "$status" == 3* ]] && expected_location=$(expected_redirect_for_route "$route"); then
    case "${location:-}" in
      "$expected_location"|"$BASE_URL$expected_location")
        ;;
      *)
        failures=$((failures + 1))
        printf 'ERROR [redirect] %s expected Location %s but got %s\n' "$route" "$expected_location" "${location:-<missing>}" | tee -a "$LOG_FILE" >&2
        ;;
    esac
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "Route check failed with $failures error(s). See $LOG_FILE" >&2
  exit 1
fi

echo "All routes succeeded."
echo "Error log: $LOG_FILE"
