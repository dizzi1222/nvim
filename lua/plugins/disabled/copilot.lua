-- 🐐 Copilot UNIFICADO: Sugerencias Inline + NES Predictivo
-- Autocompletado en INSERT + Líneas verdes NES en NORMAL

return {
  "zbirenbaum/copilot.lua",
  dependencies = {
    "copilotlsp-nvim/copilot-lsp", -- NES predictivo (líneas verdes)
  },
  event = "InsertEnter",
  config = function()
    -- ═══════════════════════════════════════════════════════════
    -- COPILOT.LUA: Sugerencias inline en INSERT
    -- ═══════════════════════════════════════════════════════════
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<Tab>", -- Tab para aceptar en INSERT
          accept_word = "<C-Right>", -- Aceptar palabra
          accept_line = "<C-j>", -- Aceptar línea completa
          dismiss = "<C-]>", -- Rechazar sugerencia
          next = "<M-]>", -- Siguiente sugerencia
          prev = "<M-[>", -- Sugerencia anterior
        },
      },

      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = {
          position = "bottom", -- top | bottom | left | right
          ratio = 0.4,
        },
      },

      filetypes = {
        -- Deshabilitados en ciertos tipos de archivo
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,

        -- Habilitados (agregar más si quieres)
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
        rust = true,
        go = true,
        bash = true,
        sh = true,
        zsh = true,
      },

      server_opts_overrides = {
        settings = {
          advanced = {
            inlineSuggestCount = 3, -- Número de sugerencias
            listCount = 10, -- Tamaño de lista
            authProvider = "github",
          },
        },
      },
    })

    -- ═══════════════════════════════════════════════════════════
    -- COPILOT-LSP: NES Predictivo (Líneas verdes en NORMAL)
    -- ═══════════════════════════════════════════════════════════
    vim.g.copilot_nes_debounce = 500

    -- Tab en NORMAL: acepta NES predictivo o fallback a C-i
    vim.keymap.set("n", "<Tab>", function()
      local nes = require("copilot-lsp.nes")
      -- Si hay NES disponible, aplicarlo
      if nes.apply_pending_nes() then
        nes.walk_cursor_end_edit()
        return nil
      else
        -- Fallback: C-i (jump forward en buffer)
        return "<C-i>"
      end
    end, { expr = true, noremap = true, desc = "Accept Copilot NES or C-i" })

    -- Esc en NORMAL: limpiar NES o nohlsearch
    vim.keymap.set("n", "<Esc>", function()
      local nes = require("copilot-lsp.nes")
      if not nes.clear() then
        vim.cmd("nohlsearch")
      end
    end, { noremap = true, desc = "Clear NES or nohlsearch" })

    -- Leader+p: aceptar y mover cursor (alternativa)
    vim.keymap.set("n", "<leader>p", function()
      local nes = require("copilot-lsp.nes")
      nes.apply_pending_nes()
      nes.walk_cursor_end_edit()
    end, { noremap = true, desc = "Accept NES and move cursor" })

    -- Shift+Tab: rechazar NES
    vim.keymap.set("n", "<S-Tab>", function()
      require("copilot-lsp.nes").clear()
    end, { noremap = true, desc = "Reject NES" })

    -- ═══════════════════════════════════════════════════════════
    -- PANEL Y COMANDOS
    -- ═══════════════════════════════════════════════════════════

    -- Panel de Copilot (mostrar todas las sugerencias)
    vim.keymap.set("n", "<leader>cp", ":Copilot panel<CR>", { noremap = true, desc = "Copilot panel" })

    -- Autenticar con GitHub
    vim.keymap.set("n", "<leader>ca", ":Copilot auth<CR>", { noremap = true, desc = "Copilot auth" })

    -- Toggle Copilot
    vim.keymap.set("n", "<leader>ct", ":Copilot toggle<CR>", { noremap = true, desc = "Copilot toggle" })

    -- print("✅ Copilot Unificado cargado (Inline + NES)")
  end,

  init = function()
    -- Habilitar Copilot LSP al inicio
    if pcall(require, "copilot-lsp") then
      vim.lsp.enable("copilot_ls")
    end
  end,
}
