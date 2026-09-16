#!/usr/bin/env python3
"""CursorTab Usage Overview — session real de la app Cursor (state.vscdb).

Consulta el mismo backend que usa neocursor: api2.cursor.sh/…/GetCurrentPeriodUsage
(conect RPC con el Bearer token de la sesión local). Si esa vía falla, cae al
legacy GET /auth/usage. Imprime un resumen legible para el keymap <leader>C.
"""
import base64
import datetime as dt
import json
import os
import sqlite3
import sys
import urllib.error
import urllib.request
from pathlib import Path


def find_state_db():
    env = os.environ.get("CURSOR_STATE_DB_PATH")
    if env:
        return Path(env).expanduser()
    xdg = Path(os.environ.get("XDG_CONFIG_HOME") or (Path.home() / ".config"))
    dirs = [
        Path(os.environ.get("CURSOR_CONFIG_DIR") or xdg) / "Cursor",
        xdg / "Cursor - Insiders",
        Path.home() / ".var" / "app" / "co.anysphere.cursor" / "config" / "Cursor",
    ]
    for d in dirs:
        p = d / "User" / "globalStorage" / "state.vscdb"
        if p.is_file():
            return p
    return dirs[0] / "User" / "globalStorage" / "state.vscdb"


def read_token(db):
    con = sqlite3.connect(db.absolute().as_uri() + "?mode=ro", uri=True)
    try:
        row = con.execute("SELECT value FROM ItemTable WHERE key='cursorAuth/accessToken'").fetchone()
        return row[0] if row else None
    finally:
        con.close()


def fmt_date(ms):
    try:
        return dt.datetime.fromtimestamp(int(ms) / 1000).strftime("%Y-%m-%d")
    except Exception:
        return str(ms)


def days_left(ms):
    try:
        delta = dt.datetime.fromtimestamp(int(ms) / 1000) - dt.datetime.now()
        return max(0, delta.days)
    except Exception:
        return -1


def http(url, method, body=None, token=None):
    h = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Connect-Protocol-Version": "1",
    }
    if token:
        h["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except Exception as e:
        return None, str(e)


def main():
    db = find_state_db()
    if not db.is_file():
        print(f"❌ state.vscdb no existe: {db}\n¿Cursor instalado y con sesión iniciada?")
        return 1
    tok = read_token(db)
    if not tok:
        print("❌ No hay cursorAuth/accessToken en el state.vscdb. Abrí Cursor y logueate.")
        return 1

    st, body = http(
        "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage",
        "POST",
        {},
        tok,
    )
    if st == 200:
        try:
            data = json.loads(body)
        except Exception:
            data = {}
        # a veces el conect envelope viene base64 en "data"
        if isinstance(data.get("data"), str) and data["data"].lstrip().startswith("ey"):
            try:
                data = json.loads(base64.b64decode(data["data"]).decode())
            except Exception:
                pass
        pu = data.get("planUsage") or {}
        cycle = data.get("billingCycleStart"), data.get("billingCycleEnd")
        total = pu.get("totalPercentUsed")
        api = pu.get("apiPercentUsed")
        auto = pu.get("autoPercentUsed")
        bonus = pu.get("bonusSpend")
        lines = [
            "┌─ CursorTab Usage Overview ─────────────────────────┐",
            f"│ 🏫 Cuenta: la app Cursor instalada (sesión local desde)",
            f"│           {db}",
            f"│ 📅 Ciclo: {fmt_date(cycle[0])} → {fmt_date(cycle[1])}  ({days_left(cycle[1])} días)",
        ]
        if total is not None:
            lines.append(f"│ 📦 Pool incluido: {total}% usado  (≈{max(0, 100-total)}% restante)")
        if auto is not None:
            lines.append(f"│ 🤖 Auto/Composer: {auto}%")
        if api is not None:
            lines.append(f"│ 🆔 API: {api}%")
        if bonus is not None:
            lines.append(f"│ 🎁 Bonus: {bonus} (spend de bonus en el periodo)")
        msg = data.get("autoModelSelectedDisplayMessage")
        if msg:
            lines.append(f"│ 💬 “{msg}”")
        lines.append("│ 🔗 Dashboard: https://cursor.com/dashboard")
        lines.append("└─────────────────────────────────────────────────┘")
        print("\n".join(lines))
        return 0

    # fallback legacy (Enterprise / request-based)
    st2, body2 = http("https://api2.cursor.sh/auth/usage", "GET", None, tok)
    if st2 == 200:
        data = json.loads(body2)
        bucket = data.get("gpt-4") or {}
        used = bucket.get("numRequests")
        mx = bucket.get("maxRequestUsage")
        print(
            f"legacy usage: used={used} max={mx} startOfMonth={data.get('startOfMonth')}"
        )
        return 0
    print(f"❌ No hay datos de uso (GetCurrentPeriodUsage={st}, auth/usage={st2})")
    return 1


if __name__ == "__main__":
    sys.exit(main())