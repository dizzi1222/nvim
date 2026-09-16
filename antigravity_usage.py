#!/usr/bin/env python3
"""Antigravity Usage Overview — RPC directo (retrieveUserQuotaSummary).

Usa el MISMO endpoint que `agy /usage`:
  POST https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary

Token: ~/.config/nvim/antigravity_token (Bearer del CLI, capturado con
capture_anty_token.sh — 0600, expira y se recaptura). PERMANENTE POR USUARIO
logueado: sirve mientras dure el login de agy en esta máquina.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

BASE = "https://daily-cloudcode-pa.googleapis.com"
TOK_FILE = os.path.expanduser("~/.config/nvim/antigravity_token")


def load_token():
    try:
        with open(TOK_FILE, encoding="utf-8") as f:
            auth = f.read().strip()
        if not auth.lower().startswith("bearer "):
            auth = "Bearer " + auth
        return auth
    except OSError:
        return None


def pending(reason):
    print("┌──────────────────────────────────────────────────┐")
    print("│ ⚠️  " + reason)
    print("│   Generá/actualizá tu token del CLI agy:          │")
    print("│   ~/.config/nvim/capture_anty_token.sh            │")
    print("└──────────────────────────────────────────────────┘")


def main():
    auth = load_token()
    if not auth:
        return pending("falta el token (antigravity_token)")
    body = json.dumps({"project": ""}).encode()
    h = {
        "Authorization": auth,
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "antigravity/cli/1.1.4",
    }
    try:
        req = urllib.request.Request(BASE + "/v1internal:retrieveUserQuotaSummary",
                                     data=body, headers=h, method="POST")
        with urllib.request.urlopen(req, timeout=25) as r:
            data = json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            return pending("token vencido/inválido (401) — recapturá con\n   capture_anty_token.sh")
        return pending(f"HTTP {e.code}")
    except Exception as e:
        return pending(f"error de red ({e})")

    W = 50
    bar_w = 30

    def L(s):
        return "│ " + s[:W - 2].ljust(W - 2) + "│"

    def models_of(g):
        d = g.get("description") or ""
        ix = d.find("within this group:")
        return (d[ix + len("within this group:"):].strip() if ix >= 0 else "") or ""

    rx = []
    rx.append("┌" + "─" * W + "┐")
    rx.append(L("🏫 Antigravity — cuota semanal por grupo"))
    rx.append("├" + "─" * W + "┤")
    for g in data.get("groups") or []:
        name = g.get("displayName") or "?"
        bucket = (g.get("buckets") or [{}])[0]
        frac = bucket.get("remainingFraction")
        pct = (frac * 100) if frac is not None else None
        agotado = (pct is not None and pct <= 0.0001)
        icon = "⚠️" if agotado else "⚡"
        rx.append(L(f"{icon} {name}"))
        if pct is None:
            rx.append(L("      remaining: ?"))
        else:
            fill = max(0, min(bar_w, int(round(pct / 100 * bar_w))))
            bar = "█" * fill + "░" * (bar_w - fill)
            pct_s = f"{pct:.1f}%"
            rx.append(L(f"      {bar}  {pct_s:>6}" + ("  ⚠️" if agotado else "")))
        reset = bucket.get("resetTime") or ""
        if reset:
            rx.append(L("      refresca el " + reset[:10]))
        mods = models_of(g)
        if mods:
            rx.append(L("      " + mods[:42]))
        if agotado:
            rx.append(L("      → activá AI Credit overages o esperá el reset"))
        rx.append("├" + "─" * W + "┤")
    rx.append("└" + "─" * W + "┘")
    print("\n".join(rx))
    return 0


if __name__ == "__main__":
    sys.exit(main())