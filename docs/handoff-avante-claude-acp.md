# Handoff: Avante + Claude vía ACP · Claude Code keymaps · plugin-switcher

> Origen: sesión Claude Code en **Termux (Android aarch64)**, 2026-11-22.
> Destino: agente del **PC (NixOS, thinkpad-x1e2)**. La config de nvim es compartida.
> Commits: los hace **Diego** (regla de la submodule `nvim/`). El agente no commitea.

## Ramas (submodule `nvim/`)

- Trabajo hecho en la rama **`termux`** (Android). **`main` = PC.** No comparten historia lineal
  (`origin/main...termux` = 41 / 104 commits).
- Base idéntica: `plugin-switcher.lua` y `claude-code.lua` son iguales en `origin/main` y
  `termux` HEAD; `avante-cursor.lua` también, **pero en `main` vive en `lua/plugins/`
  (activo)** y en `termux` en `lua/plugins/disabled/`.
- Llevar a `main`: Diego commitea en `termux` → en el PC `git cherry-pick <sha>` sobre `main`.
  Si git no detecta el rename de `avante-cursor.lua`, aplicar el diff con la ruta de `main`:
  `git diff <sha>^ <sha> -- lua/plugins/disabled/avante-cursor.lua | sed 's#plugins/disabled/#plugins/#g' | git apply`.
- **No** llevar a `main` los movimientos del switcher (son estado local de Termux):
  `opencode-chat.lua` → `disabled/`, `claude-code.lua` → `plugins/`, ni `lazy-lock.json`.

## TL;DR

- `auth_type = "max"` (OAuth Pro/Max dentro de Avante) → **no usar**. Anthropic prohíbe que
  terceros enruten requests con credenciales de suscripción (riesgo de restricción de cuenta).
  Fuente: <https://code.claude.com/docs/en/legal-and-compliance>.
  En avante upstream ya ni existe: se renombró a `auth_type = "subscription"`.
- **Vía recomendada: ACP** (`provider = "claude-code"`). Corre el binario oficial `claude`
  sin modificar con tu login → uso permitido, consume límites de la suscripción.
- En Termux quedó **verificado E2E**: spec real de avante + `ACPClient` de avante →
  Claude respondió `"hola desde Avante"` sin `ANTHROPIC_API_KEY`.
- Pendiente: verificación en el PC (checklist abajo).

## Cambios (sin commitear)

### `lua/plugins/disabled/avante-cursor.lua`

| Cambio | Motivo | ¿Afecta al PC? |
| --- | --- | --- |
| `file_selector.provider` y `windows.input.provider` → `"snacks"` | El preset del switcher los había pisado con `"agy-acp"`/`"claude-code"` (inválidos) | Sí, **fix** |
| Auto-install npm usa paquetes con scope `@agentclientprotocol/*` | `claude-agent-acp` y `codex-acp` **sin scope** son forks de terceros | Sí, **fix de seguridad** |
| `acp_providers["claude-code"]`: `CLAUDE_CODE_EXECUTABLE = exepath("claude")` | El adaptador solo lee esa var; `ACP_PATH_TO_*` y `ACP_PERMISSION_MODE` no existen | Sí, inocuo |
| `command`: Termux → `node <index.js>`; resto → `claude-agent-acp` | En Termux `#!/usr/bin/env node` falla (avante solo pasa PATH+env, sin termux-exec) | No: el PC usa el bin directo |
| `env` con `HOME`, `TMPDIR`, `PREFIX`, `LANG` | avante NO hereda el entorno, solo PATH + este `env` | Inocuo |
| `ACPClient._handle_notification` ignora `auth/status_update` y `_auth/status_update` | Adaptador ≥0.109 las emite; avante (sep-2026) no las conoce → ~6 WARN. Envolver `vim.notify` no sirve: snacks.notifier lo pisa | Inocuo |
| `dual_boost.enabled = false` | claude/gemini sin API key → 60 s de espera y "Dual boost stream timeout" en cada pregunta | Sí, si el PC tampoco tiene keys |

### `lua/utils/plugin-switcher.lua`

- `find_enabled_line()`: entradas comentadas en `disabled.lua` caen al método por archivo.
- `update_disabled_config` devuelve `true` si la entrada existe aunque no cambie.
- `claude` con `repo = "coder/claudecode.nvim"`.
- **Fix** `avante_apply`: solo reescribe el **primer** `provider =` (top-level).
  Antes pisaba también `file_selector`/`input` → causa del bug de arriba.
- `avante_current` (fallback por archivo): toma el primer `provider =`.
- **Fix gestión doble** (bug previo, ya en HEAD): Avante tiene entrada `enabled = true` en
  `disabled.lua` **y** spec en `disabled/` (movido en `80cf0c8`). El switcher solo miraba
  `disabled.lua` → lo mostraba "activo" y el toggle nunca movía el spec (lazy cargaba avante
  sin config). Ahora el toggle es **simétrico y hace las dos vías a la par** (cada una si
  aplica): `enabled = true/false` en `disabled.lua` **y** mover el `.lua` entre `plugins/` ↔
  `disabled/`. `spec_stuck_in_disabled()` marca off un spec en `disabled/` aunque
  `enabled = true`; `avante_current().enabled` usa lo mismo.
- En `termux` Avante quedó **activado** (spec movido a `lua/plugins/`). Estado local: no llevar
  ese movimiento a `main` (allí ya está en `plugins/`).

### `lua/plugins/claude-code.lua` (activado: movido desde `disabled/`)

- `<leader>al` / `<leader>aC`: con sesión abierta, `:ClaudeCode --resume` solo alternaba la
  ventana (los args solo se usan al **crear** el terminal). Ahora: sin sesión → `--resume` /
  `--continue`; con sesión → envía `/resume` / solo muestra.
- `send_to_claude`: usa `claudecode.terminal.get_active_terminal_bufnr()` (antes llamaba a una
  función inexistente) y envía `\r` (Enter). `/rename` va sin Enter.
- Keymaps movidos por conflicto con Avante: `<leader>aa` → **`<leader>aA`** (DiffAccept),
  `<leader>af` → **`<leader>aO`** (Focus). `<leader>aO` en visual es de Ollama: no choca.
- Resto de choques resueltos moviendo **Avante** (`avante-cursor.lua` → `mappings`):
  `files.add_current` ac → **`aI`**, `toggle.debug` ad → **`aX`**, `toggle.selection` aC → **`aT`**,
  `select_acp_mode` am → **`aG`**. Verificado con `avante.config.setup`: 0 choques en modo normal.

### Otros en el working tree

- `opencode-chat.lua` → `disabled/` (movido por el switcher, contenido idéntico a HEAD).
- `lazy-lock.json` modificado (revisar antes de commitear).
- `av.txt` (132 KB, dump de `doc/avante.txt`) en la raíz del config: **basura, borrar**.

## Fuera del repo (solo Termux, no viaja)

- `npm i -g @agentclientprotocol/claude-agent-acp` (0.109.1) en `~/.npm-global`.
- `avante_templates.so` compilado desde fuente (`make luajit TARGET_LIBRARY=templates`):
  no hay binario precompilado para Android; sin él el primer mensaje ACP falla en
  `generate_prompts` ("missing avante_templates").

## Checklist para el agente del PC

1. `git pull` del dotfiles tras el commit de Diego; `home-manager switch` si aplica.
2. Instalar el adaptador **oficial** (no el sin scope):
   `npm i -g @agentclientprotocol/claude-agent-acp` → `command -v claude-agent-acp`.
   En NixOS el bin debe estar en el PATH que hereda Neovim.
3. `claude` logueado con la suscripción (`claude` → `/login`). Sin `ANTHROPIC_API_KEY` en el
   entorno de nvim, o el adaptador usará la key.
4. En `main` Avante ya está activo (`lua/plugins/avante-cursor.lua`). Reiniciar nvim.
   Para `claude-code.lua` (claudecode.nvim): activarlo con `<leader>D` si se quiere en el PC.
5. Verificar que `lua/avante_templates.so` existe en `~/.local/share/nvim/lazy/avante.nvim/`
   (en Linux lo trae `:AvanteBuild`).
6. Prueba: `:AvanteAsk` → "di hola". Esperado: responde Claude, sin WARN de `auth/status_update`.
7. Probar el preset del switcher (`<leader>D` → Avante · modo → otro provider y volver):
   `file_selector`/`input` deben seguir en `"snacks"`.
8. Probar en `claude-code.lua`: `<leader>ac` abre, `<leader>al` con sesión abierta envía
   `/resume` (no oculta), `<leader>aA` / `<leader>aO` funcionan.

## Pendiente / no verificado

- E2E completo por `llm.stream` (camino del sidebar) en Termux: el proceso headless fue
  matado (exit 137) dos veces; probar en el PC (paso 6).
- `codex-acp` en Termux tendría el mismo problema de shebang; no se tocó.
- Avante upstream (`avante-corp/avante.nvim`) ya soporta `auth/status_update`; actualizar
  el plugin haría innecesario el filtro de notify (cambia `lazy-lock.json`).
