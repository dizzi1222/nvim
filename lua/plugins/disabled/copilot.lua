-- Copilot: Sugerencias inline (INSERT con Tab) + NES lineas verdes predictivas (NORMAL con Tab)
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
      panel = { enabled = false },
      server_opts_overrides = {
        settings = {
          advanced = {
            inlineSuggestCount = 3,
          },
        },
      },
    })

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
      if ok then nes.clear() end
    end, { noremap = true, desc = "NES: Rechazar" })
  end,

  init = function()
    -- Habilitar Copilot LSP al inicio (necesario para NES)
    if pcall(require, "copilot-lsp") then
      vim.lsp.enable("copilot_ls")
    end
  end,
}
