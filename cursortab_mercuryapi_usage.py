#!/usr/bin/env python3
"""Mercury API (Inception Labs) Usage Overview.
Endpoint real: GET https://platform.inceptionlabs.ai/api/usage?quota=1
Auth: cookie de sesión NextAuth (__Secure-next-auth.session-token, HttpOnly,
~24h de vida). Se lee directo de cookies.sqlite de Firefox o Zen Browser — si expira,
solo hace falta re-loguearte en el dashboard con el browser.
"""
import glob, json, os, shutil, sqlite3, sys, tempfile, urllib.error, urllib.request

DOMAIN = "platform.inceptionlabs.ai"
COOKIE_NAME = "__Secure-next-auth.session-token"
URL = "https://platform.inceptionlabs.ai/api/usage?quota=1"


def find_zen_cookies_db():
    home = os.path.expanduser("~")
    # Zen Browser specific locations
    zen_patterns = (
        f"{home}/.mozilla/zen-browser/*/cookies.sqlite",
        f"{home}/.zen/*/cookies.sqlite",
        f"{home}/.var/app/zen-browser.ZenBrowser/.mozilla/zen-browser/*/cookies.sqlite",
        f"{home}/.var/app/zen-browser/.mozilla/zen-browser/*/cookies.sqlite",
        f"{home}/.zen-browser*/cookies.sqlite",
        f"{home}/.config/zen/*/cookies.sqlite",
    )
    # Firefox fallback locations
    firefox_patterns = (
        f"{home}/.mozilla/firefox/*.default*/cookies.sqlite",
        f"{home}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default*/cookies.sqlite",
    )
    patterns = zen_patterns + firefox_patterns
    for p in patterns:
        matches = glob.glob(p)
        if matches:
            return max(matches, key=os.path.getmtime)
    return None

def box(lines, W=54):
    L = lambda s: "│ " + s[: W - 4].ljust(W - 4) + " │"
    out = ["┌" + "─" * (W - 2) + "┐"]
    out += [L(l) for l in lines]
    out.append("└" + "─" * (W - 2) + "┘")
    print("\n".join(out))


def render(data):
    used = data.get("tokens")
    limits = data.get("limits") or {}
    total = limits.get("totalTokens")
    if used is None or total is None:
        box(["⚠️ Shape inesperado, JSON crudo:"] + json.dumps(data, indent=2).splitlines()[:12])
        return
    meta = data.get("metadata") or {}
    prompt = meta.get("prompt_tokens")
    completion = meta.get("completion_tokens")
    requests = data.get("requests")
    pct = (used / total * 100) if total else 0
    bar_w = 30
    fill = max(0, min(bar_w, int(round(pct / 100 * bar_w))))
    bar = "█" * fill + "░" * (bar_w - fill)
    lines = [
        "󱂛 Mercury API (Inception Labs) Usage 󰓅  ",
        f"⚡ {used:,} / {total:,} tokens",
        f"   {bar}  {pct:.1f}%",
    ]
    if prompt is not None and completion is not None:
        lines.append(f"📥 Prompt: {prompt:,}  📤 Completion: {completion:,}")
    if requests is not None:
        lines.append(f"🔢 Requests: {requests}")
    box(lines)

def pending(reason):
    box([f"⚠️  {reason}", "Logueate en https://platform.inceptionlabs.ai/dashboard/api-keys", "con Firefox o Zen Browser (sesión ~24h)."])


def read_all_cookies():
    db = find_zen_cookies_db()
    if not db:
        return None
    tmp_dir = tempfile.mkdtemp()
    tmp_db = os.path.join(tmp_dir, "cookies.sqlite")
    try:
        for suffix in ("", "-wal", "-shm"):
            src = db + suffix
            if os.path.exists(src):
                shutil.copy2(src, tmp_db + suffix)
        con = sqlite3.connect(tmp_db)
        rows = con.execute(
            "SELECT name, value FROM moz_cookies WHERE host LIKE ?",
            (f"%{DOMAIN}%",),
        ).fetchall()
        con.close()
        return "; ".join(f"{n}={v}" for n, v in rows) if rows else None
    except Exception:
        return None
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main():
    cookie_header = read_all_cookies()
    if not cookie_header:
        pending("No se encontraron cookies del dominio")
        return 1
    req = urllib.request.Request(
        URL,
        headers={
            "Cookie": cookie_header,
            "Accept": "*/*",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:153.0) Gecko/20100101 Firefox/153.0",
            "Referer": "https://platform.inceptionlabs.ai/dashboard/api-keys",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        pending("Sesión vencida (401/403) — reloguéate" if e.code in (401, 403) else f"HTTP {e.code}")
        return 1
    except Exception as e:
        pending(f"Error de red: {e}")
        return 1
    render(data)
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF; exit
