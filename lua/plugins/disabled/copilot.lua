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

    -- 🔥 Desactivar Copilot en buffers sin archivo (como Avante, terminal, etc)
    local copilot_state = {} -- Rastrear estado para evitar comandos repetidos

    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local should_disable = buf_name == ""

        -- Solo ejecutar comando si el estado cambió
        if copilot_state.disabled ~= should_disable then
          if should_disable then
            vim.cmd("Copilot disable")
          else
            vim.cmd("Copilot enable")
          end
          copilot_state.disabled = should_disable
        end
      end,
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
