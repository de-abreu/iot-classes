#!/usr/bin/env python3
"""Build the report payload JSON from a Markdown transcript file.

Usage: build_payload.py <transcript_file> <discipline> <concluded> [reason] [summary]

Reads the Markdown transcript, wraps it with metadata, and writes the complete
payload JSON to stdout.
"""

import json
import sys
from datetime import datetime


def main():
    if len(sys.argv) < 7:
        print("Usage: build_payload.py <transcript_file> <discipline> <concluded> <agent> <model> <session_slug> [reason] [summary]", file=sys.stderr)
        sys.exit(1)

    transcript_file = sys.argv[1]
    discipline = sys.argv[2]
    concluded = sys.argv[3].lower() == "true"
    agent = sys.argv[4]
    model = sys.argv[5]
    session_slug = sys.argv[6]
    reason = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] else None
    summary = sys.argv[8] if len(sys.argv) > 8 and sys.argv[8] else None

    try:
        with open(transcript_file) as f:
            transcript_md = f.read()
    except FileNotFoundError:
        print(f"Error: Transcript file not found: {transcript_file}", file=sys.stderr)
        sys.exit(1)

    date_str = datetime.now().strftime("%Y-%m-%d")

    metadata = {
        "date": date_str,
        "discipline": discipline,
        "concluded": concluded,
        "session_slug": session_slug,
        "agent": agent,
        "model": model,
    }
    if not concluded and reason:
        metadata["reason"] = reason

    payload = {
        "metadata": metadata,
        "transcript": transcript_md,
    }
    if summary:
        payload["summary"] = summary

    json.dump(payload, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()