#!/usr/bin/env python3
"""Build the report payload JSON from an opencode export file.

Usage: build_payload.py <export_file> <discipline> <concluded> <session_id> [reason] [summary]

Reads the export JSON, formats the transcript, and writes the complete
payload JSON to stdout.
"""

import json
import sys
from datetime import datetime


def format_part(part):
    ptype = part.get("type", "")
    lines = []

    if ptype == "text":
        text = part.get("text", "").strip()
        if text:
            lines.append(text)
            lines.append("")

    elif ptype == "reasoning":
        text = part.get("text", "").strip()
        if text:
            lines.append(f"> **Reasoning:** {text}")
            lines.append("")

    elif ptype == "tool":
        tool_name = part.get("tool", "unknown")
        state = part.get("state", {})
        status = state.get("status", "unknown")
        tool_input = state.get("input", {})
        tool_output = state.get("output", "")

        input_str = json.dumps(tool_input, ensure_ascii=False) if isinstance(tool_input, dict) else str(tool_input)
        if len(input_str) > 200:
            input_str = input_str[:200] + "..."
        output_str = str(tool_output)
        if len(output_str) > 500:
            output_str = output_str[:500] + "..."

        lines.append(f"**Tool: `{tool_name}`** ({status})")
        lines.append(f"- **Input:** {input_str}")
        lines.append("")
        lines.append("<details><summary>Output</summary>")
        lines.append("")
        lines.append("```")
        lines.append(output_str)
        lines.append("```")
        lines.append("</details>")
        lines.append("")

    return "\n".join(lines)


def format_message(msg):
    info = msg.get("info", msg.get("data", {}))
    parts = msg.get("parts", [])
    role = info.get("role", "unknown")

    md_parts = [p for p in (format_part(p) for p in parts) if p.strip()]

    if role == "user":
        heading = "### User"
        body = "\n".join(md_parts)
    elif role == "assistant":
        agent = info.get("agent", "assistant")
        model_info = info.get("model", {})
        model_name = model_info.get("modelID", model_info if isinstance(model_info, str) else "")
        tokens = info.get("tokens", {})
        cost = info.get("cost", 0)

        token_str = f"{tokens.get('total', 0)} tokens" if tokens else ""
        cost_str = f", cost: ${cost:.4f}" if cost else ""
        heading = f"### {agent} / {model_name}"
        if token_str:
            heading += f" ({token_str}{cost_str})"
        body = "\n".join(md_parts)
    else:
        heading = f"### {role}"
        body = "\n".join(md_parts)

    return f"{heading}\n\n{body}\n"


def main():
    if len(sys.argv) < 5:
        print("Usage: build_payload.py <export_file> <discipline> <concluded> <session_id> [reason] [summary]", file=sys.stderr)
        sys.exit(1)

    export_file = sys.argv[1]
    discipline = sys.argv[2]
    concluded = sys.argv[3].lower() == "true"
    session_id = sys.argv[4]
    reason = sys.argv[5] if len(sys.argv) > 5 else None
    summary = sys.argv[6] if len(sys.argv) > 6 else None

    try:
        with open(export_file) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error parsing export JSON: {e}", file=sys.stderr)
        sys.exit(1)

    info = data.get("info", {})
    messages = data.get("messages", [])

    session_slug = info.get("slug", "unknown")
    ts_created = info.get("time", {}).get("created", 0)
    if ts_created:
        if ts_created > 1e12:
            ts_created = ts_created / 1000
        date_str = datetime.fromtimestamp(ts_created).strftime("%Y-%m-%d")
    else:
        date_str = datetime.now().strftime("%Y-%m-%d")

    first_assistant_msg = None
    for msg in messages:
        msg_info = msg.get("info", msg.get("data", {}))
        if msg_info.get("role") == "assistant":
            first_assistant_msg = msg
            break

    if first_assistant_msg:
        first_info = first_assistant_msg.get("info", first_assistant_msg.get("data", {}))
        agent = first_info.get("agent", "unknown")
        model_info = first_info.get("model", {})
        model_name = model_info.get("modelID", model_info if isinstance(model_info, str) else "unknown")
    else:
        agent = "unknown"
        model_name = "unknown"

    transcript_parts = [format_message(msg) for msg in messages]
    transcript_md = "\n".join(transcript_parts)

    metadata = {
        "date": date_str,
        "discipline": discipline,
        "concluded": concluded,
        "session_id": session_id,
        "session_slug": session_slug,
        "agent": agent,
        "model": model_name,
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