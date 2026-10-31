#!/usr/bin/env python3
"""Export OpenCode v2 transcripts through its authenticated CLI.

--list prints JSON session metadata; otherwise Markdown is written to stdout.
--session selects an explicit session, --directory scopes the default session,
and --out optionally saves the Markdown. No legacy SQLite tables are read.
"""

import argparse
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlencode


def cli_json(*args):
    """Let OpenCode resolve its own service URL and credentials."""
    result = subprocess.run(
        ["opencode", *args], capture_output=True, text=True, timeout=30, check=True
    )
    return json.loads(result.stdout)


def list_sessions(directory=None):
    """List recent root sessions, optionally limited to the editor directory."""
    query = {"limit": 60, "order": "desc", "parentID": "null"}
    if directory:
        query["directory"] = directory
    sessions = cli_json("api", "GET", "/api/session?" + urlencode(query))["data"]
    return [s for s in sessions if not s.get("time", {}).get("archived")]


def timestamp(ms):
    """Render an API timestamp in local time."""
    return datetime.fromtimestamp((ms or 0) / 1000).strftime("%Y-%m-%d %H:%M:%S")


def format_content(part):
    """Render v2 text, reasoning, and tool content without internal native payloads."""
    kind = part.get("type")
    if kind == "text":
        return part.get("text", "")
    if kind == "reasoning":
        return "_Thinking:_\n\n" + part.get("text", "")
    if kind != "tool":
        return ""
    state = part.get("state", {})
    lines = [f"**Tool: {part.get('name', 'tool')}**"]
    if "input" in state:
        lines.append("```json\n" + json.dumps(state["input"], indent=2, ensure_ascii=False) + "\n```")
    for item in state.get("content", []) or []:
        if isinstance(item, dict) and item.get("type") == "text":
            lines.append(item.get("text", ""))
    if state.get("error"):
        lines.append("**Error:** " + str(state["error"]))
    return "\n\n".join(lines)


def format_transcript(exported):
    """Build Markdown from the v2 session export envelope."""
    info = exported["info"]
    times = info.get("time", {})
    lines = [
        "# " + (info.get("title") or "OpenCode session"),
        f"**Session ID:** {info['id']}",
        f"**Created:** {timestamp(times.get('created'))}",
        f"**Updated:** {timestamp(times.get('updated'))}",
        "---",
    ]
    for message in exported.get("messages", []):
        kind = message.get("type")
        if kind == "user":
            lines.extend(["## User", message.get("text", ""), "---"])
        elif kind == "assistant":
            model = message.get("model", {})
            model_name = model.get("id", "Model") if isinstance(model, dict) else str(model)
            agent = (message.get("agent") or "assistant").title()
            times = message.get("time", {})
            duration = ""
            if times.get("completed") and times.get("created"):
                duration = f" · {(times['completed'] - times['created']) / 1000:.1f}s"
            lines.append(f"## Assistant ({agent} · {model_name}{duration})")
            lines.extend(filter(None, (format_content(p) for p in message.get("content", []))))
            lines.append("---")
    return "\n\n".join(lines) + "\n"


def main():
    """Handle the Neovim transcript and session-picker commands."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", help="session ID (default: most recently updated)")
    parser.add_argument("--directory", help="scope session lookup to this directory")
    parser.add_argument("--list", action="store_true", help="print session metadata as JSON")
    parser.add_argument("--out", help="also save Markdown to this file")
    args = parser.parse_args()
    try:
        if args.list:
            print(json.dumps(list_sessions(args.directory), ensure_ascii=False))
            return 0
        session_id = args.session
        if not session_id:
            sessions = list_sessions(args.directory)
            if not sessions:
                print("No hay sesiones OpenCode v2 para este directorio.", file=sys.stderr)
                return 1
            session_id = sessions[0]["id"]
        text = format_transcript(cli_json("session", "export", session_id))
        if args.out:
            Path(args.out).write_text(text, encoding="utf-8")
        sys.stdout.write(text)
        return 0
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        print(f"No se pudo exportar la sesión OpenCode v2: {type(exc).__name__}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
