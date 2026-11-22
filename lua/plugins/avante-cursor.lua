-- 💸💳💰REQUIERE API. USA : AvanteSwitchProvider ollama | consigue tu key en https://www.avantelabs.ai (MEJOR QUE CURSOR)
--  Puedes hacer el trucazo de usar OLLAMA local cloud con API gratuita.🐐 Talke asi [Lineas: 35]:
--
-- =============================================================================
-- 🎛️ AVANTE DASHBOARD — 3 VÍAS DE AUTENTICACIÓN (orden de prioridad ACP)
-- =============================================================================
-- 1) ACP (Agent Client Protocol) — usa el LOGIN PROPIO del CLI externo
--    Prioridad: opencode → claude-code → agy-acp → codex
--    :AvanteSwitchProvider opencode|claude-code|agy-acp|codex
--    ✅ opencode:          ~/.local/bin/opencode              → suscripción opencode
--    ✅ claude-code:       npm i -g @agentclientprotocol/claude-agent-acp → `claude` CLI = Pro/Max
--    ✅ agy-acp:           agy acp (Antigravity)              → agy alias
--    ⏳ codex:             npm i -g codex-acp                 → `codex` CLI = ChatGPT Plus
--
-- 2) OAuth DENTRO DE AVANTE (native)
--    • claude:  auth_type = "max" (comentado: rompía snacks picker). Reactivar: descomenta L327.
--    • copilot: provider listo; requiere copilot.lua configurado.
--
-- 3) API KEY (pago por token)
--    • ollama:  local gratis (down)                    → no key
--    • gemini:  GEMINI_API_KEY (no seteada)            → variable de entorno
--    • deepseek: DEEPSEEK_API_KEY                      → variable de entorno
--    • openrouter: COMENTADO completo (L390-L417)
--
-- AUTOCOMPLETADO (Cursor Tab): ollama si up → claude (key) → gemini. Toggle: <leader>aS
-- CURSOR/APPLY: usa el MISMO agente ACP activo (opencode ahora).
-- =============================================================================
return {
  {
    "yetone/avante.nvim",
    -- 🔧 [dizzi fix] Antes: build = "make" → exige toolchain Rust (cargo) y fallaba en Bazzite:
    --   "cargo build --release --features=luajit -p avante-tokenizers → make: cargo: No such file"
    -- :AvanteBuild (source=false por defecto) NO compila: descarga el .so ya compilado del release
    -- (avante_lib-linux-x86_64-luajit.tar.gz, ~21 MB) y lo deja en lua/*.so. Solo necesita curl+tar.
    -- La versión a descargar la saca de lua/avante/version.lua ⇒ siempre coincide con el tag fijado.
    build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1" or ":AvanteBuild",
    event = "VeryLazy",
    -- 🔧 [dizzi] Los binarios precompilados solo se publican por release ⇒ fijamos el tag para que
    -- el código Lua y los .so SIEMPRE coincidan (con version=false el código iba por delante y
    -- rompía). Al salir release nueva: subir este tag y `:Lazy build avante.nvim`.
    version = "v0.5.0",

    -- 🔧 [dizzi fix] "Invalid log level: 3" (avante/utils/log.lua:60-63 muta log_levels
    -- mientras itera pairs → el alias numérico log_levels[3] a veces NO se agrega;
    -- depende del hash-seed de LuaJIT, por eso es intermitente entre sesiones).
    -- Fix: pasar el log level como TEXTO ("OFF") → la rama string del assert solo usa
    -- log_levels[string.upper(level)], SIEMPRE presente tras el deepcopy. Debe setearse
    -- con `init` porque el crash ocurre al requerir el módulo (antes que setup()).
    init = function()
      vim.g.avante = vim.g.avante or {}
      vim.g.avante.log_level = "OFF"
    end,

    -- 🔌 ACP AUTO-INSTALL (multi-OS: Linux/macOS/WSL/Termux)
    -- Instala claude-agent-acp y codex-acp si faltan, usando npm global.
    -- Respeta: Linux/macOS → npm global; WSL → npm global (Windows); Termux → pkg/npm.
    -- Se ejecuta una sola vez al cargar el plugin (defer 2s para no bloquear startup).
    config = function(_, opts)
      require("avante").setup(opts)

      -- 🔇 claude-agent-acp (≥0.109) emite `auth/status_update` y `_auth/status_update`,
      --    que este avante no conoce → ~6 WARN "Unknown notification method" por sesión.
      --    Son inofensivos: se ignoran EN ORIGEN (ACPClient). Envolver vim.notify no sirve:
      --    snacks.notifier (ui.lua) reemplaza vim.notify después y pisa el envoltorio.
      local acp_ok, ACPClient = pcall(require, "avante.libs.acp_client")
      if acp_ok and type(ACPClient) == "table" and ACPClient._handle_notification then
        local handle = ACPClient._handle_notification
        ACPClient._handle_notification = function(self, id, method, params)
          if method == "auth/status_update" or method == "_auth/status_update" then
            return
          end
          return handle(self, id, method, params)
        end
      end
      -- which-key: registrar después de que avante esté listo
      vim.defer_fn(function()
        local ok, wk = pcall(require, "which-key")
        if ok then
          wk.add({
            { "<leader>ae", mode = "x", group = "avante: edit", icon = { icon = "" } },
            { "<leader>an", mode = "x", group = "avante: new ask", icon = { icon = "" } },
            { "<leader>aa", mode = "x", group = "avante: ask", icon = { icon = "" } },
          })
        end
      end, 100)

      -- 📦 ACP auto-install (solo una vez por sesión)
      vim.defer_fn(function()
        local is_wsl = vim.fn.has("wsl") == 1
        local is_termux = vim.fn.isdirectory("/data/data/com.termux") == 1
        local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

        -- Mapeo: binario → paquete npm OFICIAL (scope @agentclientprotocol).
        -- ⚠️ `claude-agent-acp` / `codex-acp` SIN scope son forks de terceros: no instalar.
        local acp_tools = {
          ["claude-agent-acp"] = { pkg = "@agentclientprotocol/claude-agent-acp", desc = "Claude Code ACP (Pro/Max)" },
          ["codex-acp"] = { pkg = "@agentclientprotocol/codex-acp", desc = "Codex ACP (ChatGPT Plus/Pro)" },
        }

        local function npm_global_root()
          -- respeta NPM_CONFIG_PREFIX si existe
          local prefix = vim.fn.system("npm config get prefix 2>/dev/null"):gsub("\n", "")
          if vim.v.shell_error ~= 0 or prefix == "" then
            prefix = vim.fn.expand("~/.npm-global")
          end
          return prefix
        end

        local function is_installed(bin)
          return vim.fn.executable(bin) == 1
        end

        ---@param bin string Binario esperado en PATH
        ---@param pkg string Paquete npm que lo provee
        local function install_via_npm(bin, pkg)
          local prefix = npm_global_root()
          local bin_dir = prefix .. "/bin"
          -- asegurar que el bin dir esté en PATH
          local path = vim.env.PATH or ""
          if not path:match(vim.pesc(bin_dir)) then
            vim.env.PATH = bin_dir .. ":" .. path
          end
          vim.notify("[avante] Instalando " .. bin .. " vía npm global...", vim.log.levels.INFO)
          local out = vim.fn.system("npm install -g " .. pkg .. " 2>&1")
          if vim.v.shell_error == 0 then
            vim.notify("[avante] ✅ " .. bin .. " instalado en " .. bin_dir, vim.log.levels.INFO)
            return true
          else
            vim.notify("[avante] ❌ Falló instalación de " .. bin .. ": " .. out, vim.log.levels.ERROR)
            return false
          end
        end

        -- Termux usa pkg, pero npm global también funciona si está configurado
        if is_termux then
          local has_pkg = vim.fn.executable("pkg") == 1
          local has_npm = vim.fn.executable("npm") == 1
          if has_pkg then
            -- Termux: nodejs-lts ya trae npm, usamos npm global
          elseif not has_npm then
            vim.notify("[avante] Termux sin npm/pkg, saltando ACP auto-install", vim.log.levels.WARN)
            return
          end
        end

        local missing = {}
        for bin, info in pairs(acp_tools) do
          if not is_installed(bin) then
            table.insert(missing, { bin = bin, info = info })
          end
        end

        if #missing > 0 then
          vim.notify("[avante] ACP tools faltantes: " .. table.concat(
            vim.tbl_map(function(m)
              return m.bin
            end, missing),
            ", "
          ) .. " → instalando...", vim.log.levels.INFO)
          for _, m in ipairs(missing) do
            install_via_npm(m.bin, m.info.pkg)
          end
          -- recargar PATH por si se instaló en directorio nuevo
          vim.defer_fn(function()
            vim.env.PATH = npm_global_root() .. "/bin:" .. vim.env.PATH
            vim.notify(
              "[avante] ACP auto-install completado. Reinicia nvim o ejecuta :checkhealth avante",
              vim.log.levels.INFO
            )
          end, 3000)
        end
      end, 2000)
    end,

    ---@module 'avante'
    ---@type avante.Config
    opts = function(_, opts)
      -- Track avante's internal state during resize
      local in_resize = false
      local original_cursor_win = nil
      local avante_filetypes = { "Avante", "AvanteInput", "AvanteAsk", "AvanteSelectedFiles" }

      -- Check if current window is avante
      local function is_in_avante_window()
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")

        for _, avante_ft in ipairs(avante_filetypes) do
          if ft == avante_ft then
            return true, win, ft
          end
        end
        return false
      end

      -- feature n1: Auto-switch a Ollama (provider gratuito por defecto)
      -- 🎮 Usa :AvanteSwitchProvider <provider>
      -- Providers: claude, ollama, gemini, deepseek, openrouter, copilot
      -- vim.defer_fn(function()
      --   pcall(vim.cmd, "silent! AvanteSwitchProvider claude")
      -- end, 500)

      -- Temporarily move cursor away from avante during resize
      local function temporarily_leave_avante()
        local is_avante, avante_win, avante_ft = is_in_avante_window()
        if is_avante and not in_resize then
          in_resize = true
          original_cursor_win = avante_win

          -- Find a non-avante window to switch to
          local target_win = nil
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")

            local is_avante_ft = false
            for _, aft in ipairs(avante_filetypes) do
              if ft == aft then
                is_avante_ft = true
                break
              end
            end

            if not is_avante_ft and vim.api.nvim_win_is_valid(win) then
              target_win = win
              break
            end
          end

          -- Switch to non-avante window if found
          if target_win then
            vim.api.nvim_set_current_win(target_win)
            return true
          end
        end
        return false
      end

      -- Restore cursor to original avante window
      local function restore_cursor_to_avante()
        if in_resize and original_cursor_win and vim.api.nvim_win_is_valid(original_cursor_win) then
          -- Small delay to ensure resize is complete
          vim.defer_fn(function()
            pcall(vim.api.nvim_set_current_win, original_cursor_win)
            in_resize = false
            original_cursor_win = nil
          end, 50)
        end
      end

      -- Prevent duplicate windows cleanup
      local function cleanup_duplicate_avante_windows()
        local seen_filetypes = {}
        local windows_to_close = {}

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")

          -- Special handling for Ask and Select Files panels
          if ft == "AvanteAsk" or ft == "AvanteSelectedFiles" then
            if seen_filetypes[ft] then
              -- Found duplicate, mark for closing
              table.insert(windows_to_close, win)
            else
              seen_filetypes[ft] = win
            end
          end
        end

        -- Close duplicate windows
        for _, win in ipairs(windows_to_close) do
          if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end

      -- 🖥️ Detección de OS simplificada y eficaz
      local is_wsl = vim.fn.has("wsl") == 1
      local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
      local is_linux = vim.fn.has("unix") == 1 and not is_wsl
      local is_termux = vim.fn.isdirectory("/data/data/com.termux") == 1

      -- feature n2: Verificar avante_templates presentes (build.sh/:AvanteBuild los deja en lua/, no en build/)
      local lib_ext = is_windows and ".dll" or ".so"
      local templates_lib = vim.fn.stdpath("data") .. "/lazy/avante.nvim/lua/avante_templates" .. lib_ext
      if vim.fn.filereadable(templates_lib) == 0 then
        vim.notify("Avante templates no encontrados. Descargando binarios precompilados...", vim.log.levels.WARN)
        vim.defer_fn(function()
          vim.cmd("Lazy build avante.nvim")
        end, 1000)
      end

      -- Create autocmd group for resize fix
      vim.api.nvim_create_augroup("AvanteResizeFix", { clear = true })

      -- Main resize handler for Resize
      vim.api.nvim_create_autocmd({ "VimResized" }, {
        group = "AvanteResizeFix",
        callback = function()
          -- Move cursor away from avante before resize processing
          local moved = temporarily_leave_avante()

          if moved then
            -- Let resize happen, then restore cursor
            vim.defer_fn(function()
              restore_cursor_to_avante()
              -- Force a clean redraw
              vim.cmd("redraw!")
            end, 100)
          end

          -- Cleanup duplicates after resize completes
          vim.defer_fn(cleanup_duplicate_avante_windows, 150)
        end,
      })

      -- Prevent avante from responding to scroll/resize events during resize
      vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized" }, {
        group = "AvanteResizeFix",
        pattern = "*",
        callback = function(args)
          local buf = args.buf
          if buf and vim.api.nvim_buf_is_valid(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")

            for _, avante_ft in ipairs(avante_filetypes) do
              if ft == avante_ft then
                -- Prevent event propagation for avante buffers during resize
                if in_resize then
                  return true -- This should stop the event
                end
                break
              end
            end
          end
        end,
      })

      -- Additional cleanup on focus events
      vim.api.nvim_create_autocmd("FocusGained", {
        group = "AvanteResizeFix",
        callback = function()
          -- Reset resize state on focus gain
          in_resize = false
          original_cursor_win = nil
          -- Clean up any duplicate windows
          vim.defer_fn(cleanup_duplicate_avante_windows, 100)
        end,
      })

      -- 🎨 Re-linkear highlights de Avante suggestions (mismo verde clásico GitHub que NES)
      -- Avante por defecto linkea AvanteSuggestion a "Comment" (depende del theme).
      -- Forzamos colores concretos para consistencia visual con Copilot NES.
      local function set_avante_hl()
        vim.api.nvim_set_hl(0, "AvanteSuggestion", { fg = "#68d391", bg = "none" })

        vim.api.nvim_set_hl(0, "AvanteAnnotation", { link = "AvanteSuggestion" })
        vim.api.nvim_set_hl(0, "AvanteToBeDeleted", { fg = "#ffa198", bg = "#391a1a", strikethrough = true })
      end
      set_avante_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_avante_hl })
      -- Re-aplicar después de que Avante cargue (VeryLazy) por si setup sobreescribió
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = set_avante_hl,
      })

      -- 🔑 Atajos extra para ACEPTAR suggestion (avante no soporta array en "accept",
      -- así que definimos keymaps adicionales que apuntan al mismo <Plug> que el principal)
      local avante_suggestion_accept = function()
        local _, _, sg = require("avante").get()
        if sg then
          sg:accept()
        end
      end
      vim.keymap.set(
        { "n", "v" },
        "<C-y>",
        avante_suggestion_accept,
        { desc = "avante: accept suggestion", silent = true }
      )
      -- [fix] <Tab> SOLO en n/v: quitar 'i' para que NO robe el Tab a Supermaven en insert.
      vim.keymap.set(
        { "n", "v" },
        "<C-l>",
        avante_suggestion_accept,
        { desc = "avante: accept suggestion", silent = true }
      )

      return {
        -- 🎯 CONFIGURACIÓN BÁSICA
        --   ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
        ---@type Provider
        -- 🥇 PROVIDER ACTIVO: se elige solo, en este orden de prioridad:
        --   1) opencode acp   2) claude-agent-acp   3) agy-acp   4) codex-acp
        --   Si no hay ningún CLI ACP instalado → cae a "claude" (API key / suscripción).
        --   Ver `acp_providers` abajo. Se cambia en caliente con :AvanteSwitchProvider
        provider = "claude-code",
        ---@alias Mode "agentic" | "legacy"
        ---@type Mode
        mode = "legacy", -- o/ agentic -- 󰄭 GEMINI, Claude, 󰄬 etc SOPORTAN agentic, OLLAMA NO 󰂭 -- The default mode for interaction. "agentic" uses tools to automatically generate code, "legacy" uses the old planning method to generate code.
        -- 🔥 Log level como STRING (no número): la rama string del assert
        -- (log_levels[string.upper(level)]) NO falla aunque falte el alias
        -- numérico log_levels[3] → evita "Invalid log level: 3"
        log_level = "off",
        -- 🔕 SILENCIAR NOTIFICACIONES, etiquetas XLS?
        hints = {
          enabled = true, -- Desactiva hints que pueden mostrar XML
        },

        -- 📝 Archivo de instrucciones del proyecto
        instructions_file = "avante.md",

        -- 🔌 ACP (3ª vía): usa el login propio de cada CLI. Orden = el de `provider` arriba.
        --    :AvanteSwitchProvider → opencode | claude-code | agy-acp | codex
        acp_providers = {
          -- 1) opencode acp
          ["opencode"] = { command = "opencode", args = { "acp" } },
          -- 2) claude-agent-acp (npm i -g @agentclientprotocol/claude-agent-acp)
          --    → reutiliza el login del CLI `claude` (Pro/Max). Ruta permitida por Anthropic:
          --    corre el binario oficial sin modificar. Sin ANTHROPIC_API_KEY a propósito.
          --    • command = node + index.js: el bin es `#!/usr/bin/env node` y en Termux
          --      /usr/bin/env no existe (termux-exec/LD_PRELOAD no llega: avante solo pasa PATH+env).
          --    • CLAUDE_CODE_EXECUTABLE: única var que lee el adaptador (no ACP_PATH_TO_*);
          --      en Android no hay binario empaquetado del Agent SDK.
          --    Linux/macOS (PC): bin directo, igual que antes. Termux: node + script.
          ["claude-code"] = vim.tbl_extend("force", (function()
            if vim.fn.isdirectory("/data/data/com.termux") == 0 then
              return { command = "claude-agent-acp", args = {} }
            end
            local bin = vim.fn.exepath("claude-agent-acp")
            if bin == "" then
              bin = vim.fn.expand("~/.npm-global/bin/claude-agent-acp")
            end
            return { command = vim.fn.exepath("node"), args = { vim.fn.resolve(bin) } }
          end)(), {
            env = {
              HOME = os.getenv("HOME"),
              TMPDIR = os.getenv("TMPDIR") or "/tmp",
              PREFIX = os.getenv("PREFIX") or "",
              LANG = os.getenv("LANG") or "C.UTF-8",
              CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
            },
          }),
          -- 3) agy-acp (Antigravity CLI, `agy acp`) → sin API key
          ["agy-acp"] = {
            command = "agy",
            args = { "acp" },
            env = { PATH = os.getenv("PATH"), HOME = os.getenv("HOME") },
          },
          -- 4) codex-acp (npm i -g codex-acp) → login de `codex` = ChatGPT Plus/Pro
          ["codex"] = { command = "codex-acp", args = {}, env = { PATH = os.getenv("PATH"), HOME = os.getenv("HOME") } },
          -- Futuro (requiere instalar el CLI `gemini`):
          -- ["gemini-cli"] = { command = "gemini", args = { "--experimental-acp" }, auth_method = "gemini-api-key" },
        },

        -- 🤖 CONFIGURACIÓN DE PROVIDERS (SIN DEPRECATED WARNINGS)
        providers = {
          --  OLLAMA - Local y gratuito 󰎣
          ollama = {
            priority = 1,
            endpoint = "127.0.0.1:11434", -- Sin /v1
            model = "phi3:mini", -- de PAGO: "deepseek-v3.2:cloud", -- Tu modeloAvanteSwitchProvider deepseek
            timeout = 30000,
            mode = "agentic", -- ✅ CRÍTICO, "agentic" permite ejecutar BASH, legacy menos errores (tomo el riesgo).
            disable_tools = true, -- 🔥 Agregar esto
            -- api_key_name = "OLLAMA-API-KEY", -- NO necesitas api_key_name para Ollama local
          },
          -- GEMIMI-CLI 󰊭    OLLAMA 🐐 = LOS UNICOS MODELOS GRATIS DE AVANTE 🐐 󰸞 .
          ["gemini-cli-dizzi"] = {
            __inherited_from = "openai",
            api_key_name = "GEMINI_API_KEY",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/openai/",
            model = "gemini-2.0-flash-exp", -- ✅ Modelo correcto para API OpenAI-compatible
            timeout = 30000,
            mode = "agentic",
            disable_tools = true, -- 🔥 Agregar esto
          },
          --  GEMINI - API gratuita 💸🐐
          gemini = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.0-flash-exp",
            api_key_name = "GEMINI_API_KEY", -- ✅ NOMBRE DE VARIABLE, NO PATH
            mode = "agentic", -- USA Tools para GEMINI
            disable_tools = true, -- 🔥 Agregar esto
            timeout = 30000,
            -- La API key se lee de GEMINI_API_KEY o AVANTE_GEMINI_API_KEY
          },
          --  DeepSeek - GRATIS y POTENTE 🚀💸🐐
          deepseek = {
            priority = 2,
            __inherited_from = "openai", -- ✅ IMPORTANTE: Hereda de OpenAI
            endpoint = "https://api.deepseek.com",
            model = "deepseek-chat", -- No-thinking mode (más rápido)
            -- model = "deepseek-reasoner", -- Thinking mode (como Claude)
            timeout = 30000,
            mode = "agentic", -- USA Tools para DeepSeek
            disable_tools = true, -- 🔥 Agregar esto
            api_key_name = "DEEPSEEK_API_KEY", -- ✅ NOMBRE DE VARIABLE, NO PATH
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4096, -- Lo baje de 8192
            },
          },

          --  CLAUDE - Pago 💀☠️ (SIN deprecated warnings)
          -- Linux nativo: auth_type "max" (usa suscripcion, sin API key)
          -- Windows/WSL: api_key_name (OAuth no funciona en Windows/WSL)
          claude = {
            priority = 1,
            endpoint = "https://api.anthropic.com",
            model = "claude-sonnet-4-20250514",
            timeout = 30000,
            -- 🖥️ 3 VÍAS: dejamos "api" (funciona YA con ANTHROPIC_API_KEY).
            --    Para usar tu SUSCRIPCIÓN Claude Pro/Max: cambiá a auth_type = "max",
            --    reabrí nvim y corré :AvanteSwitchProvider claude (OAuth en el navegador).
            --    ⚠️ OAuth "max" NO funciona en Windows/WSL; y ojo: el picker de snacks
            --    se rompe al hacer login (por eso quedó en "api").
            auth_type = "api",
            api_key_name = "ANTHROPIC_API_KEY", -- API key como fallback
            mode = "agentic",
            disable_tools = true,
            -- ✅ Usar extra_request_body para evitar warnings
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4096,
            },
          },

          --   COPILOT - Pago 💀☠️
          copilot = {
            model = "claude-sonnet-4",
            mode = "agentic", -- USA Tools para Copilot
            disable_tools = true, -- 🔥 Agregar esto
            -- Totalmente de PAGO
          },
          --[==[ ⛔ OPENROUTER COMENTADO: para reactivarlo, quitá las marcas de bloque Lua
          openrouter = {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "cohere/north-mini-code:free", -- "nvidia/nemotron-3-super-120b-a12b", -- LIGERO:
            -- ──────────────────────────────────────────────────────────
            -- 🏆 MEJORES MODELOS GRATIS PARA CODING (OpenRouter)
            -- ──────────────────────────────────────────────────────────
            -- 1. gpt-oss-120b:free  ← 117B MoE (5.1B activos), reasoning configurable,
            --    tool use nativo, el más polenta para código + arquitectura
            -- 2. owl-alpha:free     ← #1 en uso (1.99T tokens), agentic, 1.05M ctx
            -- 3. poolside/laguna-m.1:free ← especialista SWE, tool calling + reasoning
            -- 4. moonshotai/kimi-k2.6:free ← long-horizon coding, agent swarm
            -- 5. qwen/qwen3-coder:free ← rápido y liviano para código puro
            -- ──────────────────────────────────────────────────────────
            mode = "legacy", -- USA Tools para OpenRouter
            disable_tools = true, -- 🔥 Agregar esto
            api_key_name = "OPEN_ROUTER_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4421, -- Lo baje de 8192
              reasoning = { enabled = false }, -- 🔥 Desactiva thinking mode en modelos que lo soporten
            },
          },
          ]==]
        },
        -- 🖱️ CURSOR/APPLY: usa provider REGULAR (no ACP). Los providers ACP (agy-acp, claude-code, codex)
        --    NO están en el registry hasta que haces :AvanteSwitchProvider.
        --    Prioridad: ollama (gratis local) → claude (API key) → gemini (API key) → opencode (ACP activo) → codex/claude-code (requieren switch previo).
        cursor_applying_provider = (function()
          local ok = vim.fn.system({ "curl", "-s", "-m", "1", "http://127.0.0.1:11434/api/tags" })
          if vim.v.shell_error == 0 and ok and ok:match("models") then
            return "ollama"
          end
          if os.getenv("ANTHROPIC_API_KEY") and os.getenv("ANTHROPIC_API_KEY") ~= "" then
            return "claude"
          end
          if os.getenv("GEMINI_API_KEY") and os.getenv("GEMINI_API_KEY") ~= "" then
            return "gemini"
          end
          -- Si hay ACP activo, úsalo; si no, cae a claude
          local acp_active = vim.fn.executable("opencode") == 1 or vim.fn.executable("agy") == 1
          if acp_active then
            -- Devolvemos el provider activo (requiere que ya se haya hecho :AvanteSwitchProvider)
            return require("avante.config").provider
          end
          return "claude"
        end)(),
        -- ✨ AUTOCOMPLETADO (Cursor Tab). NUNCA puede ser un provider ACP: necesita
        --    completions streaming. Prioridad: ollama local (gratis) → claude (API key) → gemini.
        auto_suggestions_provider = (function()
          local ok = vim.fn.system({ "curl", "-s", "-m", "1", "http://127.0.0.1:11434/api/tags" })
          if vim.v.shell_error == 0 and ok and ok:match("models") then
            return "ollama"
          end
          if os.getenv("ANTHROPIC_API_KEY") and os.getenv("ANTHROPIC_API_KEY") ~= "" then
            return "claude"
          end
          if os.getenv("GEMINI_API_KEY") and os.getenv("GEMINI_API_KEY") ~= "" then
            return "gemini"
          end
          return "ollama" -- último recurso: arrancá `ollama serve`
        end)(),
        --  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀 
        ---Note: This is an experimental feature and may not work as expected.
        --[==[ ⛔ DUAL_BOOST COMENTADO (usa openrouter que está comentado). Reactivar: borrar --[==[ y ]==]
        dual_boost = {
          -- OFF: claude (sin ANTHROPIC_API_KEY) y gemini (sin GEMINI_API_KEY) no responden →
          -- cada pregunta esperaba 60 s y acababa en "Dual boost stream timeout reached".
          enabled = false,
          first_provider = "claude",  -- provider regular (no ACP)
          second_provider = "gemini", -- provider regular (no ACP)
          prompt = "Combina la respuesta de claude y gemini. Responde en español, tono técnico pero cercano, estilo argentino. Sin explicaciones, solo la respuesta final.",
          timeout = 60000,
        },
        -- ]==]
        -- FIN -  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀  - FIN

        -- 🎨 COMPORTAMIENTO
        behaviour = {
          enable_cursor_planning_mode = true,
          -- AUTO-SUGERENCIAS (Cursor Tab). El provider se elige solo:
          --   ollama local (gratis) → claude (API key) → gemini (API key).
          --   Toggle manual: <leader>as
          auto_suggestions = true,
          auto_suggestions_respect_ignore = true,
          disable_tools = true,
          minimize_diff = true,
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          support_paste_from_clipboard = true,
        },
        -- ⏱️ SUGGESTIONS: debounce/throttle altos para no quemar el plan Free de OpenRouter
        -- (el motor envia el archivo completo por request, sin caching → consume tokens)
        suggestion = {
          debounce = 800, -- ms tras dejar de escribir antes de pedir suggestion
          throttle = 1500, -- ms minimo entre requests (reduce consumo de tokens Free)
        },
        -- File selector configuration
        --- @alias FileSelectorProvider "native" | "fzf" | "mini.pick" | "snacks" | "telescope" | string
        file_selector = {
          provider = "snacks", -- Avoid native provider issues
          provider_opts = {},
        },
        --  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀 
        mappings = {
          --- @class AvanteConflictMappings
          diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "]x",
            prev = "[x",
          },
          suggestion = {
            accept = "<M-f>", -- Aceptar sugerencia de avante. NO usar array aqui: avante no soporta arrays en safe_keymap_set. Para multiples atajos, definir keymaps extra fuera apuntando a <Plug>(AvanteSuggestionAccept).
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<S-Tab>", -- Antes C-]
          },
          jump = {
            next = "]]",
            prev = "[[",
          },
          submit = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          cancel = {
            normal = { "<C-c>", "<Esc>", "q" },
            insert = { "<C-c>" },
          },
          sidebar = {
            apply_all = "A",
            apply_cursor = "a",
            retry_user_request = "r",
            edit_user_request = "e",
            reverse_switch_windows = "<S-Tab>",
            remove_file = "d",
            add_file = "@",
            close = { "<Esc>", "q" },
            close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
          },
          -- 🔄 TOGGLES DE AVANTE (con <Space> como leader en LazyVim)
          -- ⚠️ Conflictos con claude-code.lua (claudecode.nvim): Claude se queda con
          --    ac (toggle), ad (diff deny), aC (continue), am (modelo) → Avante se mueve.
          toggle = {
            -- default = "<leader>at", -- Abrir/cerrar sidebar
            debug = "<leader>aX", -- antes ad (Claude: diff deny)
            selection = "<leader>aT", -- antes aC (Claude: continue)
            -- suggestion = "<leader>aS", -- ✅ Enciende/apaga las AUTO-SUGGESTIONS (usar en proyectos grandes para no gastar tokens Free)
            -- repomap = "<leader>aR",
          },
          files = {
            add_current = "<leader>aI", -- antes ac (Claude: toggle)
            add_all_buffers = "<leader>aB",
          },
          select_acp_mode = "<leader>aG", -- antes am (Claude: seleccionar modelo)
        },
        selection = {
          enabled = true,
          hint_display = "delayed",
        },
        -- FIN -  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀  - FIN
        -- 🪟 CONFIGURACIÓN DE VENTANAS
        windows = {
          ---@type "right" | "left" | "top" | "bottom" | "smart"
          position = "left", -- the position of the sidebar
          wrap = true, -- similar to vim.o.wrap
          width = 30, -- default % based on available width
          sidebar_header = {
            enabled = true, -- true, false to enable/disable the header
            align = "center", -- left, center, right for title
            rounded = false,
          },
          input = {
            provider = "snacks", -- ✅ Evita "native input doesn't support concealed"
            prefix = "> ",
            height = 8,
          },
          edit = {
            start_insert = true, -- Start insert mode when opening the edit window
          },
          ask = {
            floating = false, -- Open the 'AvanteAsk' prompt in a floating window
            start_insert = true, -- Start insert mode when opening the ask window
            ---@type "ours" | "theirs"
            focus_on_apply = "ours", -- which diff to focus after applying
          },
          -- ✅ AGREGAR render_markdown config:
          render_markdown = {
            enabled = true,
            file_types = { "Markdown", "Norg", "Rmd", "Org", "Vimwiki", "Avante", "AvanteInput", "AvanteAsk" },
          },
          -- ]==]
          -- 🎭 SYSTEM PROMPT PERSONALIZADO (Opcional)
          system_prompt = "Este GPT es un clon del usuario, un arquitecto líder frontend especializado en Angular y React, con experiencia en arquitectura limpia, arquitectura hexagonal y separación de lógica en aplicaciones escalables. Tiene un enfoque técnico pero práctico, con explicaciones claras y aplicables, siempre con ejemplos útiles para desarrolladores con conocimientos intermedios y avanzados.\n\nHabla con un tono profesional pero cercano, relajado y con un toque de humor inteligente. Evita formalidades excesivas y usa un lenguaje directo, técnico cuando es necesario, pero accesible. Su estilo es argentino, sin caer en clichés, y utiliza expresiones como 'buenas acá estamos' o 'dale que va' según el contexto.\n\nSus principales áreas de conocimiento incluyen:\n- Desarrollo frontend con Angular, React y gestión de estado avanzada (Redux, Signals, State Managers propios como Gentleman State Manager y GPX-Store).\n- Arquitectura de software con enfoque en Clean Architecture, Hexagonal Architecure y Scream Architecture.\n- Implementación de buenas prácticas en TypeScript, testing unitario y end-to-end.\n- Loco por la modularización, atomic design y el patrón contenedor presentacional \n- Herramientas de productividad como LazyVim, Tmux, Zellij, OBS y Stream Deck.\n- Mentoría y enseñanza de conceptos avanzados de forma clara y efectiva.\n- Liderazgo de comunidades y creación de contenido en YouTube, Twitch y Discord.\n\nA la hora de explicar un concepto técnico:\n1. Explica el problema que el usuario enfrenta.\n2. Propone una solución clara y directa, con ejemplos si aplica.\n3. Menciona herramientas o recursos que pueden ayudar.\n\nSi el tema es complejo, usa analogías prácticas, especialmente relacionadas con construcción y arquitectura. Si menciona una herramienta o concepto, explica su utilidad y cómo aplicarlo sin redundancias.\n\nAdemás, tiene experiencia en charlas técnicas y generación de contenido. Puede hablar sobre la importancia de la introspección.",
        },
      } -- cierra tabla opts
    end, -- cierra opts function
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- 🆕 [dizzi] avante v0.5.0 usa mega.cmdparse en plugin/avante.lua (comandos :Avante/:AvanteBuild).
      -- Sin esto: "module 'mega.cmdparse' not found" y avante no arranca.
      -- lazy=false para que carguen ANTES que avante.nvim
      { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" }, lazy = false },
      { "ColinKennedy/mega.logging", lazy = false },
      -- Opcional pero recomendado
      "nvim-tree/nvim-web-devicons",

      -- Desactivo markdown para usar MARKVIEW sin eliminar el plugin
      {
        "MeanderingProgrammer/render-markdown.nvim",
        lazy = false, -- ← NO lazy loading
        priority = 1000, -- ← Carga antes que Avante
        dependencies = { "folke/snacks.nvim" }, -- ← Dependencia explícita
        opts = {
          file_types = { "markdown", "Avante", "AvanteInput" },
          render_modes = { "n", "c", "i" }, -- ✅ Renderizar en todos los modos
          anti_conceal = {
            enabled = false, -- ✅ Evita que oculte caracteres
          },
          -- ✅ NO pongas anti_conceal aquí
        },
      },
      -- [Indexado ] Soporte para pegar imágenes
    },
  },
}
