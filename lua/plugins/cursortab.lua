-- 👻 cursortab.nvim — edit completions + cursor prediction (líneas verdes/Z en NORMAL)
-- Repo: cursortab/cursortab.nvim. Go daemon; el build lo compila (go ya en work.nix).
--
-- 󰓅 PROVIDER ACTIVO: `mercuryapi` — hosted Inception Labs (cloud, sin GPU local).
--   Requiere:  export MERCURY_AI_TOKEN=<key>  (antes de abrir nvim)
--   Tras tocar la env, reinicia daemon: :CursortabRestart  (lee el token al arrancar)
--   Trabaja en modo NORMAL: líneas verdes predictivas tipo Cursor Tab.
--   Alternativas (local, descomenta una a la vez): inline / sweep / zeta / fim.
return {
  "cursortab/cursortab.nvim",
  lazy = false, -- el server (daemon go) ya es lazy; aquí solo el frontend Lua
  build = "cd server && go build",
  config = function()
    require("cursortab").setup({
      provider = {
        -- ✅ ACTIVO: MERCURY API (hosted). No usa llama-server local; solo token.
        type = "mercuryapi",
        api_key_env = "MERCURY_AI_TOKEN", -- requiere: export MERCURY_AI_TOKEN=...

        -- ─────────────────── OPCIONES ALTERNATIVAS ───────────────────
        -- (Cada una sustituye SOLO el bloque provider; descomenta una a la vez)
        --
        -- 🐬 SWEEP next-edit (local) — llama-server pero con modelo sweep.
        --    Para usar, arranca otro server con un GGUF de sweep, p.ej.:
        --      llama-server -hf sweepai/sweep-next-edit-0.5b --port 8000
        --    (mejor calidad que inline para next-edit, pero otro download)
        -- type = "sweep",
        -- url = "http://localhost:8000",
        --
        -- 🧠 INLINE (local) — usa el llama-server Qwen local (sin API key).
        --    llama-server -hf unsloth/Qwen3.5-0.8B-GGUF:Q8_0 --port 8000
        -- type = "inline",
        -- url = "http://localhost:8000",
        --
        -- 🌌 ZETA-2.1 (local) — el mejor next-edit local (SeedCoder-8B) sin GPU.
        --    Para usarlo, arranca: llama-server -hf mradermacher/zeta-2.1-GGUF --port 8000
        -- type = "zeta-2.1",
        -- url = "http://localhost:8000",
        --
        -- ✂️  FIM (local) — fill-in-middle con cualquier modelo FIM-capable.
        --    Con Qwen3.5 funciona; útil si amplías a otro GGUF con prompt FIM.
        -- type = "fim",
        -- url = "http://localhost:8000",
        --
        -- 🤖 COPILOT (hosted) — si prefieres la cuenta GitHub Copilot (subscriptión).
        -- type = "copilot",
        --
        -- 🌊 WINDSURF (hosted) — si usas cuenta Windsurf AI.
        -- type = "windsurf",
        --
        -- legacy: ZETA-2 / ZETA = igual que zeta-2.1 pero familias viejas.
        -- type = "zeta-2", url = "http://localhost:8000"
        -- type = "zeta", url = "http://localhost:8000"
        -- ─────────────────────────────────────────────────────────────
      },

      -- Keymaps coherentes con el set NES de copilot.lua / nextedit.lua:
      --   <M-CR>  aceptar  (el principal, "M-CR es la mejor siempre")
      --   <S-Tab> rechazar (set NES consistente; enviado abajo vía daemon esc)
      --   <Esc>   rechazar  (built-in del plugin, no lo pisamos)
      -- partial_accept desactivado: <S-Tab> en los otros plugins es REJECT, así
      -- que lo unificamos a rechazar y perdemos el aceptar-parcial de cursortab.
      keymaps = {
        accept = "<C-y>",
        partial_accept = false,
        trigger = false,
      },

      ui = {
        completions = {
          addition_style = "dimmed",
          fg_opacity = 1.0, -- 1.0 => factor 0 => sin blend: fondo verde #238636 sólido (no atenuado)
        },
        jump = {
          symbol = "󰁔",
          text = " TAB ",
          show_distance = true,
        },
      },

      behavior = {
        idle_completion_delay = 50,
        text_change_debounce = 50,
        max_visible_lines = 50, -- más preview de next-edit en normal
        -- 👻 SOLO NORMAL (líneas verdes tipo NES / next-edit).
        -- Al quitar "insert" se apaga el autocompletado fantasma en INSERT
        -- (events.lua filtra TextChangedI/CursorMovedI → return), pero el
        -- cursor_prediction de NORMAL sigue enviando eventos → líneas verdes.
        enabled_modes = { "normal", "insert" },
        cursor_prediction = {
          enabled = true,
          auto_advance = true,
          proximity_threshold = 2,
        },
        ignore_filetypes = { "", "terminal" },
        ignore_gitignored = true,
      },
    })

    -- ── Highlights NES consistentes con copilot.lua ──
    local function set_cursortab_hl()
      -- Verde GitHub (#238636) para texto añadido (líneas verdes)
      vim.api.nvim_set_hl(0, "CursorTabAddition", { fg = "#ffffff", bg = "#238636" })
      -- Rojo GitHub (#391a1a) para texto eliminado
      vim.api.nvim_set_hl(0, "CursorTabDeletion", { fg = "#ffa198", bg = "#391a1a" })
      -- Ghost text de completado inline (texto justo tras el cursor):
      -- grupo VÁLIDO = CursorTabCompletion. bg #238636 para que el ghost inline
      -- tenga fondo verde (a petición).
      vim.api.nvim_set_hl(0, "CursorTabCompletion", { bg = "#238636" })
      vim.api.nvim_set_hl(0, "CursorTabModification", { bg = "#238636" })
      vim.api.nvim_set_hl(0, "CursorTabJumpSymbol", { bg = "#238636" })
      vim.api.nvim_set_hl(0, "CursorTabJumpText", { bg = "#238636" })
      vim.api.nvim_set_hl(0, "Completions", { bg = "#238636" })
    end
    set_cursortab_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_cursortab_hl })

    -- ── Keymaps NES extra (set consistente con copilot.lua) ──
    -- El plugin ya registra <M-CR> (accept) y <S-Tab> (partial_accept) vía
    -- update_keymap en N/I; y rechaza con <Esc> mediante un hook vim.on_key
    -- (no un keymap). Aquí SOLO añadimos los atajos que el set NES espera y el
    -- plugin no cubre: <Tab> en NORMAL/VISUAL y <C-CR> en N/I/V.
    local ct = require("cursortab")

    -- <M-CR> en NORMAL/INSERT/VISUAL: aceptar predicción o fallback a C-i
    vim.keymap.set({ "n", "i", "v" }, "<M-CR>", function()
      ct.accept()
    end, { noremap = true, silent = true, desc = "cursortab: Aceptar (Alt-Enter)" })

    -- <C-CR> en N/I/V: aceptar (alias extra, coherente con copilot.lua)
    vim.keymap.set({ "n", "v" }, "<C-CR>", function()
      ct.accept()
    end, { noremap = true, silent = true, desc = "cursortab: Aceptar (Control-Enter)" })

    -- <Tab> en N/I/V: aceptar (alias extra, coherente con copilot.lua)
    vim.keymap.set({ "n", "v" }, "<Tab>", function()
      ct.accept()
    end, { noremap = true, silent = true, desc = "cursortab: Aceptar (Tab)" })

    -- <S-Tab> en N/I/V: rechazar (set NES consistente). Envía el mismo evento
    -- "esc" que el <Esc> built-in (on_escape → daemon.send_event("esc")).
    local ct_daemon = require("cursortab.daemon")
    vim.keymap.set({ "n", "i", "v" }, "<S-Tab>", function()
      ct_daemon.send_event("esc")
    end, { noremap = true, silent = true, desc = "cursortab: Rechazar (S-Tab)" })

    vim.keymap.set({ "n" }, "<Esc>", function()
      ct_daemon.send_event("esc")
    end, { noremap = true, silent = true, desc = "cursortab: Rechazar (Esc)" })

    -- 📊 Mercury Usage Overview (<leader>M / :MercuryUsage)
    local function mercury_usage()
      local script = vim.fn.stdpath("config") .. "/cursortab_mercuryapi_usage.py"
      local out = {}
      vim.fn.jobstart({ "python3", script }, {
        stdout_buffered = true,
        on_stdout = function(_, d)
          for _, l in ipairs(d or {}) do
            if l ~= "" then
              table.insert(out, l)
            end
          end
        end,
        on_exit = function()
          vim.schedule(function()
            if #out == 0 then
              vim.notify("Mercury Usage: sin respuesta", vim.log.levels.WARN)
              return
            end
            local buf = vim.api.nvim_create_buf(false, true)
            vim.bo[buf].filetype = "markdown"
            vim.bo[buf].bufhidden = "wipe"
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
            local w = 0
            for _, l in ipairs(out) do
              w = math.max(w, vim.fn.strdisplaywidth(l))
            end
            local cols, rows = vim.o.columns, vim.o.lines
            local width, height = math.min(w + 4, cols - 4), math.min(#out + 2, rows - 4)
            local win = vim.api.nvim_open_win(buf, true, {
              relative = "editor",
              style = "minimal",
              border = "rounded",
              width = width,
              height = height,
              row = math.max(0, math.floor((rows - height) / 2) - 1),
              col = math.max(0, math.floor((cols - width) / 2)),
            })
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
            vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
            vim.wo[win].cursorline = false
          end)
        end,
      })
    end

    vim.api.nvim_create_user_command("MercuryUsage", mercury_usage, { desc = "Mercury Quota Overview" })
    vim.keymap.set("n", "<leader>C", "<cmd>MercuryUsage<cr>", { desc = " Mercury Usage Overview 󰓅" })

    -- which-key: solo mostrar icono cuando cursortab está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>C", icon = { icon = "󱂛" } })
    end
  end,
}
