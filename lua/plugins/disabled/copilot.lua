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
          accept_word = "<C-Right>",
          accept_line = "<C-j>",
          dismiss = "<C-]>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = {
        enabled = true, -- Panel lateral con sugerencias alternativas (como el de VSCode)
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
    vim.keymap.set("n", "<Tab>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok and nes.apply_pending_nes() then
        nes.walk_cursor_end_edit()
        return nil
      end
      return "<C-i>"
    end, { expr = true, noremap = true, desc = "NES: Aceptar o C-i" })

    -- Esc en NORMAL: limpiar NES o nohlsearch
    vim.keymap.set("n", "<Esc>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok and nes.clear() then
        return
      end
      vim.cmd("nohlsearch")
    end, { noremap = true, desc = "NES: Limpiar o nohlsearch" })

    -- S-Tab en NORMAL: rechazar NES
    vim.keymap.set("n", "<S-Tab>", function()
      local ok, nes = pcall(require, "copilot-lsp.nes")
      if ok then
        nes.clear()
      end
    end, { noremap = true, desc = "NES: Rechazar" })
  end,

  init = function()
    -- Habilitar Copilot LSP al inicio (necesario para NES)
    if pcall(require, "copilot-lsp") then
      vim.lsp.enable("copilot_ls")
    end
  end,
}
