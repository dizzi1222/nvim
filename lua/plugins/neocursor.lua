-- 👻 neocursor.nvim — Cursor Tab-Tab-Tab real en Neovim
-- Usa la sesión REAL de la app Cursor (instalada y firmada): nada de API keys,
-- no consume OpenRouter, calidad genuina de Cursor Tab (ghost text + saltos).
-- Requiere: app Cursor instalada + `uv` en PATH (ambos en work.nix).
-- Referencia de keymaps: copilot.lua (set de atajos NES) para consistencia.
return {
  -- 1. Apuntar a tu fork con los parches nativos
  "dizzi1222/neocursor.nvim",
  -- commit = "fec2577e", -- Opcional: Lazy.nvim descargará siempre lo último de main.

  event = "VeryLazy", -- Cargar al arranque: NO InsertEnter (bloquea el disparo en normal)
  opts = {
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
    -- keep_suggesting_after_reject = true, -- → eliminado (queda default false, muting tras 2 rechazos como Cursor)    show_hints = true,
    debounce = 250, -- fallback 0.25s (default del plugin; irrelevante si llega CppConfig)
    -- NO hay debounce configurable: CppConfig lo pisa al arrancar (parity con
    -- Cursor, ~50ms). Cualquier valor aquí solo aplica como fallback ese primer
    -- segundo antes de que llegue CppConfig.
    -- 🎨 Tema de color del ghost text / diff (estilo NES). Mejor que un booleano
    -- de 3 estados: un enum auto-documentado, un solo campo.
    --   "classic" = verde/rojo clásico de GitHub (#238636 / #391a1a) — completo
    --   "pywal"   = adiciones con el DiffAdd del colorscheme; borrado rojo translúcido
    --   "none"    = sin overrides, 100% colores del colorscheme (valor por defecto)
    nes_colors = "pywal",
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
      local MIN_IDLE_MS = 1500
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
  end,
}
