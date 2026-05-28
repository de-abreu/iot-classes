#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <session_id> <discipline> <concluded> [reason] <server_url> [--async] [--summary <text>]

Arguments:
  session_id   The opencode session ID (e.g. ses_xxx)
  discipline   One of: internet-of-things, embedded-systems
  concluded    true or false
  reason       (optional) Reason if not concluded, use "" if none
  server_url   Report server URL (e.g. https://xxx.trycloudflare.com)

Options:
  --async      Fire-and-forget mode: submit in background, return immediately
  --summary    Optional summary text for the report

Environment:
  AUTH_TOKEN    Auth token for the report server (read from .env or env var)
EOF
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 4 ]]; then
    usage
fi

SESSION_ID="$1"
DISCIPLINE="$2"
CONCLUDED="$3"
REASON="${4:-}"
SERVER_URL="$5"
ASYNC=false
SUMMARY=""

EXTRA_ARGS=("${@:6}")

i=0
while [[ $i -lt ${#EXTRA_ARGS[@]} ]]; do
    case "${EXTRA_ARGS[$i]}" in
        --async)   ASYNC=true; ((i++)) ;;
        --summary) SUMMARY="${EXTRA_ARGS[$((i+1))]:-}"; ((i+=2)) ;;
        *)         echo "Unknown option: ${EXTRA_ARGS[$i]}" >&2; usage ;;
    esac
done

if [[ -f .env ]]; then
    set -a
    source .env
    set +a
fi

case "${REPORT_CONSENT:-}" in
    false|0|no|off)
        echo "Report submission skipped: REPORT_CONSENT is set to '${REPORT_CONSENT}'." >&2
        exit 0
        ;;
esac

if [[ -z "${AUTH_TOKEN:-}" ]]; then
    echo "Error: AUTH_TOKEN not set. Set it in .env or as env var." >&2
    exit 1
fi

EXPORT_FILE="/tmp/opencode-export-${SESSION_ID}.json"
PAYLOAD_FILE="/tmp/report-payload-${SESSION_ID}.json"
trap 'rm -f "$EXPORT_FILE" "$PAYLOAD_FILE"' EXIT

opencode export "$SESSION_ID" > "$EXPORT_FILE" 2>/dev/null
if [[ ! -s "$EXPORT_FILE" ]]; then
    echo "Error: Failed to export session $SESSION_ID" >&2
    exit 1
fi

python3 "$SCRIPT_DIR/build_payload.py" \
    "$EXPORT_FILE" \
    "$DISCIPLINE" \
    "$CONCLUDED" \
    "$SESSION_ID" \
    "$REASON" \
    "$SUMMARY" \
    > "$PAYLOAD_FILE"

if [[ ! -s "$PAYLOAD_FILE" ]]; then
    echo "Error: Failed to build payload" >&2
    exit 1
fi

submit_report() {
    curl -s -X POST "${SERVER_URL}/report" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: ${AUTH_TOKEN}" \
        -d @"${PAYLOAD_FILE}"
}

if [[ "$ASYNC" == true ]]; then
    nohup curl -s -X POST "${SERVER_URL}/report" \
        -H "Content-Type: application/json" \
        -H "X-Auth-Token: ${AUTH_TOKEN}" \
        -d @"${PAYLOAD_FILE}" \
        &>/tmp/report-result-${SESSION_ID}.log \
        & disown
    echo "Report queued for submission (async). Session: ${SESSION_ID}"
else
    RESULT=$(submit_report)
    echo "$RESULT"
    rm -f "$PAYLOAD_FILE"
fi