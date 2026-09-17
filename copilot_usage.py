#!/usr/bin/env python3
"""GitHub Copilot Usage Overview — consulta cuotas y estado de cuenta."""
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request

APPS_FILE = os.path.expanduser("~/.config/github-copilot/apps.json")


def load_oauth_token():
    if not os.path.isfile(APPS_FILE):
        return None, None
    try:
        with open(APPS_FILE, encoding="utf-8") as f:
            data = json.load(f)
        for _, val in data.items():
            token = val.get("oauth_token")
            user = val.get("user")
            if token:
                return token, user
    except Exception:
        pass
    return None, None


def fmt_date(ts):
    if not ts:
        return "N/A"
    try:
        return dt.datetime.fromtimestamp(int(ts)).strftime("%Y-%m-%d %H:%M")
    except Exception:
        return str(ts)


def days_left(ts):
    if not ts:
        return 0
    try:
        delta = dt.datetime.fromtimestamp(int(ts)) - dt.datetime.now()
        return max(0, delta.days)
    except Exception:
        return 0


def main():
    tok, user = load_oauth_token()
    if not tok:
        print("┌──────────────────────────────────────────────────┐")
        print("│ ❌ No se encontró token en ~/.config/github-copilot/apps.json │")
        print("│    Iniciá sesión en Copilot desde Neovim.          │")
        print("└──────────────────────────────────────────────────┘")
        return 1

    req = urllib.request.Request(
        "https://api.github.com/copilot_internal/v2/token",
        headers={
            "Authorization": f"token {tok}",
            "User-Agent": "GithubCopilot/1.2.3",
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"❌ Error HTTP {e.code} al consultar la API de Copilot")
        return 1
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        return 1

    sku = data.get("sku", "desconocido")
    chat_ok = "✅" if data.get("chat_enabled") else "❌"
    reset_ts = data.get("limited_user_reset_date")
    quotas = data.get("limited_user_quotas") or {}
    comp_quota = quotas.get("completions", "Sin límite")
    chat_quota = quotas.get("chat", "Sin límite")

    W = 54

    def L(s):
        return "│ " + s[: W - 4].ljust(W - 4) + " │"

    lines = [
        "┌" + "─" * (W - 2) + "┐",
        L("🤖 GitHub Copilot Usage Overview"),
        "├" + "─" * (W - 2) + "┤",
        L(f"👤 Usuario: {user or 'n/a'}"),
        L(f"📦 Plan (SKU): {sku}"),
        L(f"💬 Chat Habilitado: {chat_ok}"),
    ]

    if reset_ts:
        lines.append(
            L(f"📅 Reinicio de cuota: {fmt_date(reset_ts)} ({days_left(reset_ts)} días)")
        )

    if quotas:
        lines.append("├" + "─" * (W - 2) + "┤")
        lines.append(L("⚡ Cuotas limitadas activas:"))
        lines.append(L(f"   • Completions: {comp_quota} restantes"))
        lines.append(L(f"   • Chat: {chat_quota} restantes"))

    lines.append("└" + "─" * (W - 2) + "┘")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
