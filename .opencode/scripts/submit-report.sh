#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <discipline> <concluded> <transcript_file> <server_url> <agent> <model> <session_slug> [reason] [--async] [--summary <text>]

Arguments:
  discipline       One of: internet-of-things, embedded-systems
  concluded        true or false
  transcript_file  Path to the Markdown transcript file (e.g. .reports/iot-2026-05-28.md)
  server_url       Report server URL (e.g. https://xxx.trycloudflare.com)
  agent            Name of the agent (e.g. Learn)
  model            Model identifier (e.g. deepseek-v4-flash-free)
  session_slug     Descriptive slug with random suffix (e.g. iot-class1-dG9rZW4)
  reason           (optional) Reason if not concluded, use "" if none

Options:
  --async          Fire-and-forget mode: submit in background, return immediately
  --summary        Optional summary text for the report

Environment:
  AUTH_TOKEN       Auth token for the report server (read from .env or env var)
EOF
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 7 ]]; then
    usage
fi

DISCIPLINE="$1"
CONCLUDED="$2"
TRANSCRIPT_FILE="$3"
SERVER_URL="$4"
AGENT="$5"
MODEL="$6"
SESSION_SLUG="$7"
REASON="${8:-}"
ASYNC=false
SUMMARY=""

EXTRA_ARGS=("${@:9}")

i=0
while [[ $i -lt ${#EXTRA_ARGS[@]} ]]; do
    case "${EXTRA_ARGS[$i]}" in
        --async)   ASYNC=true; ((i++)) ;;
        --summary) SUMMARY="${EXTRA_ARGS[$((i+1))]:-}"; ((i+=2)) ;;
        *)         echo "Unknown option: ${EXTRA_ARGS[$i]}" >&2; usage ;;
    esac
done

if [[ ! -f "$TRANSCRIPT_FILE" ]]; then
    echo "Error: Transcript file not found: $TRANSCRIPT_FILE" >&2
    exit 1
fi

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

PAYLOAD_FILE="/tmp/report-payload-$$.json"
trap 'rm -f "$PAYLOAD_FILE"' EXIT

python3 "$SCRIPT_DIR/build_payload.py" \
    "$TRANSCRIPT_FILE" \
    "$DISCIPLINE" \
    "$CONCLUDED" \
    "$AGENT" \
    "$MODEL" \
    "$SESSION_SLUG" \
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
        &>/tmp/report-result-$$.log \
        & disown
    echo "Report queued for submission (async)."
else
    RESULT=$(submit_report)
    echo "$RESULT"
fi