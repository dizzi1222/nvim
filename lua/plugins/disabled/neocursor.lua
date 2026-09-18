-- 👻 neocursor.nvim — Cursor Tab-Tab-Tab real en Neovim
-- 🎛 HAY 3 PRESETS de modo (host + usage_host) gestionados desde
-- lua/utils/plugin-switcher.lua ("neocursor · modo" en Space D, o
-- M.preset_neocursor("cursor"|"antigravity"|"antigravity-tui")):
--   cursor           → host=cursor · usage_host=cursor          (backend + usage Cursor)
--   antigravity      → host=antigravity · usage_host=antigravity (tab tab_flash + RPC usage)
--   antigravity-tui  → host=antigravity · usage_host=antigravity-tui (tab + agy /usage TUI)
-- Lógica cycle-include-toggle: elegir el modo activo lo APAGA; cambiarlo lo activa.
-- <leader>C (usage) es INDEPENDIENTE del tab y usa `usage_host` (ver arriba).
-- Referencia de keymaps: copilot.lua (set de atajos NES) para consistencia.
return {
  -- 1. Apuntar a tu fork con los parches nativos
  "dizzi1222/neocursor.nvim",
  -- commit = "9323168", -- Opcional: Lazy.nvim descargará siempre lo último de main.

  event = "VeryLazy", -- Cargar al arranque: NO InsertEnter (bloquea el disparo en normal)
  opts = {
    -- 🔀 BACKEND REAL del cursortab (gestionado por los presets de modo):
    --   "cursor"       → app Cursor (StreamCpp, sesión firmada local)
    --   "antigravity"  → app Antigravity (tab_flash_lite_preview Supercomplete)
    host = "cursor",
    -- 🖥️ Qué HOST alimenta <leader>C (usage):
    --   "cursor"           → tabla del plan de Cursor (cursor_usage.py)
    --   "antigravity"      → RPC del CLI (antigravity_usage.py): quota por grupo +
    --                         reset; token en antigravity_token (0600, recapturable
    --                         con capture_anty_token.sh)
    --   "antigravity-tui"  → float-terminal `agy /usage` (TUI completa)
    usage_host = "antigravity", -- "antigravity" | "antigravity-tui" | "cursor"
    -- NO mapear <Tab> (lo gestionan Supermaven/blink en INSERT).
    -- Aceptar ghost text / saltos con el mismo set de atajos estilo NES.
    map_tab = false,
    -- Aceptar palabra a palabra (parcial) con <M-Right>.
    map_partial = "<M-Right>",
    -- 👻 [opt-in] Sugerencia predictiva en NORMAL (como Cursor al leer): dispara
    -- un request por cada pausa de lectura — consumo extra de cuota CppConfig.
    -- La cadencia la marca &updatetime, NO el debounce del plugin.
    cursorhold_normal = true,
    show_hints = true,
    debounce = 250, -- fallback 0.25s (default del plugin; irrelevante si llega CppConfig)
    -- 🎨 Tema de color del ghost text / diff (estilo NES). Mejor que un booleano:
    nes_colors = "classic", -- classic | pywal | none
  },
  config = function(_, opts)
    -- 🤫 Interceptar y silenciar el mensaje de inicio de neocursor
    local original_notify = vim.notify
    vim.notify = function(msg, level, notify_opts)
      if msg and msg:find("neocursor ready") then
        return -- Bloquea este string específico y no muestra nada
      end
      return original_notify(msg, level, notify_opts)
    end

    require("neocursor").setup(opts)
    vim.notify = original_notify

    -- Aceptar o saltar al siguiente edit (flujo tab-tab-tab de Cursor).
    -- Estos binds replican el set de atajos NES de copilot.lua.
    -- <C-CR> y <Tab> solo en NORMAL/VISUAL (en INSERT los reservan Supermaven/cursortab).
    -- <M-CR> es el aliase libre que funciona en n/i/v.
    local function accept()
      if require("neocursor").accept() then
        return
      end
    end
    for _, lhs in ipairs({ "<C-CR>", "<Tab>" }) do
      vim.keymap.set({ "n", "v" }, lhs, accept, { noremap = true, silent = true, desc = "neocursor: accept/jump" })
    end
    vim.keymap.set(
      { "n", "i", "v" },
      "<M-CR>",
      accept,
      { noremap = true, silent = true, desc = "neocursor: accept/jump" }
    )

    -- 👻 Descartar ghost text / predicciones con <Esc> o <S-Tab> en NORMAL, INSERT y VISUAL
    -- Llama a dismiss() de Neocursor y limpia el estado de hlsearch.
    local function dismiss_esc()
      -- 1. Descarta la sugerencia de Neocursor
      require("neocursor").dismiss()

      -- 2. Limpia el resaltado de búsqueda (hlsearch) de Neovim
      vim.cmd("noh")

      -- 3. Si estás en modo Insertar o Visual, forzamos la salida al modo Normal de forma limpia
      local mode = vim.api.nvim_get_mode().mode
      if mode:match("^[vV]") or mode == "i" then
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "n", false)
      end
    end

    -- Mapeamos tanto <S-Tab> como <Esc> para unificar el comportamiento.
    -- ⚠️ LazyVim registra su propio `<Esc>` expr en `User VeryLazy`
    -- (LazyVim/config/init.lua → keymaps.lua:52) DESPUÉS de cargar este plugin,
    -- y lo pisa. vim.schedule() aplaza el re-mapeo al final del tick, ganándole a
    -- la carrera: así el dismiss de neocursor vuelve a ganar en NORMAL/VISUAL.
    vim.schedule(function()
      vim.keymap.set(
        { "n", "i", "v" },
        "<S-Tab>",
        dismiss_esc,
        { noremap = true, silent = true, desc = "neocursor: dismiss and clear hlsearch" }
      )

      vim.keymap.set(
        { "n", "i", "v" },
        "<Esc>",
        dismiss_esc,
        { noremap = true, silent = true, desc = "neocursor: dismiss and clear hlsearch" }
      )
    end)

    -- 👻 Sugerencia predictiva en NORMAL: CursorHold pide la predicción (jump/ghost),
    -- replicando el disparo que Cursor hace al leer código. Evita conflictos con
    -- Supermaven/cursortab (que manejan INSERT) limitándonos a modo normal.
    -- ⚠️ RIESGO: cada pausa de lectura dispara UN request a api2.cursor.sh (consume
    -- cuota CppConfig), a la cadencia de &updatetime — NO del debounce del plugin.
    -- M.suggest() NO respeta el mute 20/20 ni filtra buffers: por eso ESTE bloque
    -- lleva guardas propias (buffer real, cooldown, y no re-disparar la misma línea
    -- recién sugerida). Sin ellas, el loop DISMISS→REQ→SHOW quema requests. El
    -- JUMP-forever de normal ya está resuelto por el latch 539f8b5 del fork.
    -- Opt-in: desactivar con `cursorhold_normal = false`.
    if opts.cursorhold_normal then
      local last = { buf = nil, row = 0, at = 0 }
      local MIN_IDLE_MS = 1500 -- 1.5s
      vim.api.nvim_create_autocmd("CursorHold", {
        group = "neocursor",
        desc = "neocursor: sugerencia predictiva en normal (guardada)",
        callback = function()
          if not vim.api.nvim_get_mode().mode:match("^[nN]") then
            return
          end
          local buf = vim.api.nvim_get_current_buf()
          if vim.bo[buf].buftype ~= "" then
            return
          end -- solo archivos reales
          local path = vim.fn.expand("%:.")
          if path == "" or path:find("^neocursor://") then
            return
          end -- sin log/untitled/fake buffers
          local row = vim.api.nvim_win_get_cursor(0)[1]
          local now = vim.loop.hrtime() / 1e6
          -- no re-disparar la misma línea recién vista/sugerida (mataba el loop)
          if last.buf == buf and last.row == row and (now - last.at) < 5000 then
            return
          end
          if (now - last.at) < MIN_IDLE_MS then
            return
          end
          last.buf, last.row, last.at = buf, row, now
          require("neocursor").suggest()
        end,
      })
    end

    -- 🎨 Tema de color del ghost text / diff de neocursor (estilo NES).
    -- Neocursor NO expone colores en setup(): deriva de DiffAdd/DiffDelete en
    -- preview.lua (ensure_hl). Como nuestro autocmd queda registrado después del
    -- plugin, re-aplica tras cada ColorScheme y siempre gana.
    -- Modos: "classic" | "pywal" | "none"  (ver opts.nes_colors)
    local nes_theme = opts.nes_colors
    if nes_theme == "classic" or nes_theme == "pywal" then
      local function set_nes_hl()
        if nes_theme == "classic" then
          -- CLÁSICO: verde/rojo clásico de GitHub completo.
          vim.api.nvim_set_hl(0, "NeocursorAdd", { fg = "#ffffff", bg = "#238636" })
          vim.api.nvim_set_hl(0, "NeocursorDelete", { fg = "#ffa198", bg = "#391a1a", strikethrough = true })
        else
          -- PYWAL: adiciones sin override (heredan DiffAdd del colorscheme);
          -- borrado con tinte rojo translúcido y tachado.
          vim.api.nvim_set_hl(0, "NeocursorDelete", { bg = "#391a1a", strikethrough = true })
        end
        -- B: DiffDelete directo (line_hl_group en preview.lua) pinta el fondo de la
        -- línea borrada completa. Consistente con copilot.lua y avante-cursor.lua.
        vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#ffa198", bg = "#391a1a" })
      end
      set_nes_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_nes_hl,
        desc = "neocursor: NES colors (" .. nes_theme .. ")",
      })
    end
    -- "none" => sin overrides, NeocursorAdd/Delete derivan del colorscheme por defecto.

    -- 📊 AI Usage Overview (<leader>C): consumo del HOST activo en ventana flotante.
    --   host="cursor"      → cursor_usage.py (GetCurrentPeriodUsage + link dashboard)
    --   host="antigravity" → float-terminal centrado con `agy` + auto `/usage`
    --                        (TUI real: cuota semanal por grupo, modelos, cuenta).
    -- vim.g.ai_host se despacha desde opts.usage_host (NO del tab, que es siempre cursor).
    vim.g.ai_host = opts.usage_host == "antigravity" and "antigravity" or "cursor"
    local usage_scripts = {
      cursor = vim.fn.stdpath("config") .. "/cursor_usage.py",
    }

    -- 🔜 Float-terminal centrado con agy / `/usage` (fallback confiable del usage
    -- de Antigravity — el RPC directo queda pendiente de schema). q / Esc cierra.
    local function anty_usage_float()
      local cols, rows = vim.o.columns, vim.o.lines
      local width = math.min(118, cols - 6)
      local height = math.min(34, rows - 6)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = "wipe" -- termopen() setea buftype=terminal solo
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        width = width,
        height = height,
        row = math.max(0, math.floor((rows - height) / 2) - 1),
        col = math.max(0, math.floor((cols - width) / 2)),
      })
      local chan = vim.fn.termopen("agy", { cwd = vim.fn.expand("~") })
      if chan > 0 then
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            vim.fn.chansend(chan, "/usage\r")
          end
        end, 2800)
      end
      local function close()
        if chan and chan > 0 then
          pcall(vim.fn.jobstop, chan)
        end
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end
      vim.keymap.set("n", "q", close, { buffer = buf })
      vim.keymap.set("n", "<Esc>", close, { buffer = buf })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = buf })
      vim.cmd("startinsert")
    end
    local function run_usage(script)
      local out = {}
      vim.fn.jobstart({ "python3", script }, {
        stdout_buffered = true,
        on_stdout = function(_, d)
          if d then
            for _, l in ipairs(d) do
              out[#out + 1] = l
            end
          end
        end,
        on_exit = function()
          vim.schedule(function()
            if #out == 0 then
              vim.notify("AI Usage: sin salida", vim.log.levels.WARN)
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
            local width = math.min(w + 6, cols - 4)
            local height = math.min(#out + 2, rows - 4)
            local win = vim.api.nvim_open_win(buf, true, {
              relative = "editor",
              style = "minimal",
              border = "rounded",
              width = width,
              height = height,
              row = math.max(0, math.floor((rows - height) / 2) - 1),
              col = math.max(0, math.floor((cols - width) / 2)),
            })
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
            vim.wo[win].cursorline = false
          end)
        end,
      })
    end
    local function ai_usage()
      if vim.g.ai_host == "antigravity" then
        anty_usage_float()
        return
      end
      run_usage(usage_scripts.cursor)
    end
    vim.api.nvim_create_user_command("AIUsage", ai_usage, {
      desc = "AI Usage Overview (host-aware)",
    })
    vim.keymap.set("n", "<leader>C", "<cmd>AIUsage<cr>", {
      desc = "󰀺 AI Usage Overview (host-aware)",
    })

    -- which-key: solo mostrar icono cuando cursortab está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>C", icon = { icon = "󱂛" } })
    end
  end,
}
