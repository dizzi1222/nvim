#!/usr/bin/env python3
"""opencode_transcript.py — Transcript de sesiones opencode desde la DB.

Replica EXACTAMENTE el formato del transcript del TUI (`/copy` / `export`):
los headers `## User` / `## Assistant (Agent · Model · tiempo)`, el bloque
`_Thinking:_` y los bloques de tools, tal como los produce
packages/tui/src/util/transcript.ts (formatTranscript / formatMessage).

Modos:
  sin args                 → transcript de la sesión más activa (time_updated)
  --session <id>           → transcript de la sesión indicada
  --list                   → lista de sesiones (id|title|created|texts) para
                             alimentar un selector en nvim
  --session <id> --out <f> → escribe el markdown en <f> (default /tmp/copy.md)
"""
import argparse
import json
import os
import sqlite3
import sys
from datetime import datetime

STORAGE = os.path.expanduser("~/.local/share/opencode")
OUT = "/data/data/com.termux/files/usr/tmp/opencode/copy.md"


def find_db():
    """La DB activa: la más recientemente escrita (WAL de la sesión viva)."""
    best, best_mtime = None, -1
    for name in os.listdir(STORAGE):
        if name.endswith(".db") and not name.endswith((".db-shm", ".db-wal")):
            path = os.path.join(STORAGE, name)
            mtime = os.path.getmtime(path)
            if mtime > best_mtime:
                best, best_mtime = path, mtime
    return best


def connect(db):
    return sqlite3.connect(f"file:{db}?mode=ro", uri=True)


def titlecase_agent(agent):
    """'plan' -> 'Plan' (Locale.titlecase del TUI)."""
    return " ".join(w.capitalize() for w in str(agent or "build").split())


def humanize_model(model):
    """'big-pickle' -> 'Big Pickle' (Model.name sin providers)."""
    if not model:
        return "Model"
    parts = model.replace("_", " ").replace("-", " ").split()
    return " ".join(w.capitalize() for w in parts)


def js_locale(ms):
    """Reproduce Date#toLocaleString() del runtime (9/20/2026, 4:30:09 AM)."""
    try:
        dt = datetime.fromtimestamp(ms / 1000)
    except (ValueError, OSError, OverflowError):
        return "?"
    ampm = "AM" if dt.hour < 12 else "PM"
    hour = dt.hour % 12
    hour = 12 if hour == 0 else hour
    return f"{dt.month}/{dt.day}/{dt.year}, {hour}:{dt.minute:02d}:{dt.second:02d} {ampm}"


def format_part(part):
    """Una 'part' como cadena markdown (igual que formatPart del TUI)."""
    ptype = part.get("type")
    if ptype == "text" and not part.get("synthetic"):
        text = part.get("text") or ""
        return f"{text}\n\n"
    if ptype == "reasoning":
        text = part.get("text") or ""
        return f"_Thinking:_\n\n{text}\n\n"
    if ptype == "tool":
        result = f"**Tool: {part.get('tool')}**\n"
        state = part.get("state") or {}
        if state.get("input") is not None:
            result += f"\n**Input:**\n```json\n{json.dumps(state['input'], indent=2)}\n```\n"
        if state.get("status") == "completed" and state.get("output"):
            result += f"\n**Output:**\n```\n{state['output']}\n```\n"
        if state.get("status") == "error" and state.get("error"):
            result += f"\n**Error:**\n```\n{state['error']}\n```\n"
        return result + "\n"
    return ""


def format_transcript(con, session_id, out_path):
    """Reconstruye el transcript completo de la sesión (formato TUI)."""
    cur = con.cursor()
    cur.execute(
        "SELECT id, title, time_created, time_updated FROM session WHERE id=?", (session_id,)
    )
    srow = cur.fetchone()
    if not srow:
        print("NO_SESSION", file=sys.stderr)
        return 1
    sid, title, tcreated, tupdated = srow

    parts_by_msg = {}
    cur.execute("SELECT message_id, data FROM part WHERE session_id=? ORDER BY time_created ASC", (sid,))
    for mid, data in cur.fetchall():
        try:
            parts_by_msg.setdefault(mid, []).append(json.loads(data))
        except (json.JSONDecodeError, TypeError):
            continue

    lines = [f"# {title}", "", f"**Session ID:** {sid}",
             f"**Created:** {js_locale(tcreated)}", f"**Updated:** {js_locale(tupdated)}", "", "---", ""]

    cur.execute(
        "SELECT id, data FROM message WHERE session_id=? ORDER BY time_created ASC, id ASC",
        (sid,),
    )
    for mid, data in cur.fetchall():
        try:
            info = json.loads(data)
        except (json.JSONDecodeError, TypeError):
            continue
        parts = parts_by_msg.get(mid, [])
        # Solo mensajes con contenido relevante (payload real, no epílogo)
        has_content = any(p.get("type") in ("text", "reasoning", "tool") for p in parts)
        if not has_content:
            continue
        if info.get("role") == "user":
            lines.append("## User\n")
        else:
            agent = titlecase_agent(info.get("agent") or info.get("mode") or "build")
            model = humanize_model(info.get("modelID") or info.get("model"))
            duration = ""
            t = info.get("time") or {}
            created, completed = t.get("created"), t.get("completed")
            if created and completed:
                duration = f" · {((completed - created) / 1000):.1f}s"
            lines.append(f"## Assistant ({agent} · {model}{duration})\n")
        for part in parts:
            txt = format_part(part)
            if txt:
                lines.append(txt.rstrip() + "\n")
        lines.append("---\n")

    transcript = "\n".join(lines) + "\n"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(transcript)
    sys.stdout.write(transcript)
    return 0


def list_sessions(con):
    cur = con.cursor()
    cur.execute(
        "SELECT s.id, s.title, s.time_created, s.time_updated, "
        "(SELECT count(*) FROM part p WHERE p.session_id=s.id "
        "   AND json_extract(p.data,'$.type')='text') AS texts "
        "FROM session s ORDER BY s.time_updated DESC LIMIT 60"
    )
    for sid, title, created, updated, texts in cur.fetchall():
        print(f"{sid}|{title}|{js_locale(created)}|{js_locale(updated)}|{texts}")


def active_session(con):
    cur = con.cursor()
    cur.execute("SELECT id FROM session ORDER BY time_updated DESC LIMIT 1")
    row = cur.fetchone()
    return row[0] if row else None


def main():
    ap = argparse.ArgumentParser(description="opencode transcript helper")
    ap.add_argument("--session", help="session id (default: más activa)")
    ap.add_argument("--list", action="store_true", help="listar sesiones")
    ap.add_argument("--out", default=OUT, help="archivo de salida")
    args = ap.parse_args()

    db = find_db()
    if not db:
        print("SQLITE_DB_NOT_FOUND", file=sys.stderr)
        return 1
    try:
        con = connect(db)
    except sqlite3.Error as e:
        print(f"DB_ERROR {e}", file=sys.stderr)
        return 1
    try:
        if args.list:
            list_sessions(con)
            return 0
        sid = args.session or active_session(con)
        if not sid:
            print("NO_SESSION", file=sys.stderr)
            return 1
        return format_transcript(con, sid, args.out)
    finally:
        con.close()


if __name__ == "__main__":
    sys.exit(main())