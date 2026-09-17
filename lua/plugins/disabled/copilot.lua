-- Copilot: Sugerencias inline (INSERT con Tab) + NES lineas verdes predictivas (NORMAL con Tab)
-- Configuración inspirada en
return {
  "zbirenbaum/copilot.lua",
  dependencies = {
    "copilotlsp-nvim/copilot-lsp", -- NES predictivo (lineas verdes en NORMAL)
  },
  event = "VeryLazy", -- NO InsertEnter, NES necesita cargar antes para funcionar en NORMAL
  config = function()
    require("copilot").setup({
      -- Autocompletado inline en INSERT
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<Tab>",
          accept_word = "<C-CR>",
          -- accept_line = "<C-j>",
          -- dismiss = "<C-]>",
          -- next = "<M-]>",
          -- prev = "<M-[>",
        },
        -- Lo desactivo para usar Supermaven o Windsruf/Codeiunm + CopilotLSP
      },
      panel = {
        enabled = false, -- Panel lateral con sugerencias alternativas (como el de VSCode)
        keymap = {
          -- jump_prev = "[[",
          -- jump_next = "]]",
          -- accept = "<CR>",
          -- refresh = "gr",
          open = "<C-g>",
        },
      },
      server_opts_overrides = {
        settings = {
          advanced = {
            inlineSuggestCount = 3,
          },
        },
      },
    })

    -- NES: la sugerencia verde se limpia tras N movimientos de cursor (default 3)
    require("copilot-lsp").setup({
      nes = { move_count_threshold = 12 },
    })

    -- Verde clásico de GitHub para el ghost text de NES (líneas añadidas/borradas)
    local function set_nes_hl()
      vim.api.nvim_set_hl(0, "CopilotLspNesAdd", { fg = "#ffffff", bg = "#238636" })
      vim.api.nvim_set_hl(0, "CopilotLspNesDelete", { fg = "#ffa198", bg = "#391a1a" })
    end
    set_nes_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_nes_hl })

    -- 🔥 Desactivar Copilot en buffers sin archivo (Avante, terminal, etc)
    -- Usar vim.b.copilot_enabled en lugar de comandos para evitar RPC errors

    -- Desactivar en filetypes específicos de Avante
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "Avante", "AvanteInput", "AvanteAsk", "AvanteSelectedFiles" },
      callback = function()
        vim.b.copilot_enabled = false
      end,
    })

    -- Desactivar en buffers sin nombre (buffers temporales)
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        if buf_name == "" then
          vim.b.copilot_enabled = false
        end
      end,
    })
    --
    -- NES: Lineas verdes predictivas en NORMAL (tipo Cursor/VSCode/Antigravity)
    vim.g.copilot_nes_debounce = 500

    -- Tab en NORMAL: acepta NES o fallback a C-i
    vim.keymap.set({ "n", "v", "i" }, "<Tab>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok and nes.apply_pending_nes() then
        nes.walk_cursor_end_edit()
        return nil
      end
      return "<C-i>"
    end, { expr = true, noremap = true, desc = "NES: Aceptar o C-i" })

    -- 👻 Aceptar líneas verdes predictivas (NES) en normal, insert y visual.
    local function accept_nes()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok and nes.apply_pending_nes() then
        nes.walk_cursor_end_edit()
        return true
      end
      return false
    end

    -- Ctrl+Enter: acepta NES (normal, insert y visual)
    vim.keymap.set({ "n", "i", "v" }, "<C-CR>", accept_nes, {
      noremap = true,
      silent = true,
      desc = "NES: Aceptar",
    })

    -- Alt+Enter: acepta NES (normal, insert y visual)
    vim.keymap.set({ "n", "i", "v" }, "<M-CR>", accept_nes, {
      noremap = true,
      silent = true,
      desc = "NES: Aceptar (Alt-Enter)",
    })

    -- <C-CR> en N/I/V: aceptar (alias extra, coherente con copilot.lua)
    vim.keymap.set({ "n", "v" }, "<C-CR>", accept_nes, {
      noremap = true,
      silent = true,
      desc = "NES: Aceptar (Control-Enter)",
    })

    -- Esc en NORMAL: limpiar NES o nohlsearch
    vim.keymap.set({ "n" }, "<Esc>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok and nes.clear() then
        return
      end
      vim.cmd("nohlsearch")
    end, { noremap = true, desc = "NES: Limpiar o nohlsearch" })

    -- S-Tab en NORMAL: rechazar NES
    vim.keymap.set({ "n", "i", "v" }, "<S-Tab>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok then
        nes.clear()
      end
    end, { noremap = true, desc = "NES: Rechazar" })

    -- 📊 Copilot Usage Overview (<leader>C / :CopilotUsage)
    local function copilot_usage()
      local script = vim.fn.stdpath("config") .. "/copilot_usage.py"
      local out = {}

      vim.fn.jobstart({ "python3", script }, {
        stdout_buffered = true,
        on_stdout = function(_, d)
          if d then
            for _, l in ipairs(d) do
              if l ~= "" then
                table.insert(out, l)
              end
            end
          end
        end,
        on_exit = function()
          vim.schedule(function()
            if #out == 0 then
              vim.notify("Copilot Usage: sin respuesta", vim.log.levels.WARN)
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
            local width = math.min(w + 4, cols - 4)
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

            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
            vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
            vim.wo[win].cursorline = false
          end)
        end,
      })
    end

    vim.api.nvim_create_user_command("CopilotUsage", copilot_usage, {
      desc = "Copilot Quota Overview",
    })

    vim.keymap.set("n", "<leader>C", "<cmd>CopilotUsage<cr>", {
      desc = "󰀺 Copilot Usage Overview",
    })
    -- which-key: solo mostrar icono cuando cursortab está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>C", icon = { icon = "󱂛" } })
    end
  end,

  init = function()
    -- Habilitar Copilot LSP al inicio (necesario para NES)
    if pcall(require, "copilot-lsp") then
      vim.lsp.enable("copilot_ls")
    end
  end,
}
