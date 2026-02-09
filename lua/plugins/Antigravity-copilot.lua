-- Plugin 2: copilot-lsp para NES en NORMAL mode (lineas verdes)
return {
  "copilotlsp-nvim/copilot-lsp",
  init = function()
    vim.g.copilot_nes_debounce = 500
    vim.lsp.enable("copilot_ls")

    -- Tab en Normal: acepta NES o fallback a C-i
    vim.keymap.set("n", "<Tab>", function()
      local state = vim.b[vim.api.nvim_get_current_buf()].nes_state
      if state then
        local nes = require("copilot-lsp.nes")
        local _ = nes.walk_cursor_start_edit() or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
        return nil
      else
        return "<C-i>"
      end
    end, { expr = true, desc = "Accept Copilot NES" })

    -- Esc limpia sugerencias NES
    vim.keymap.set("n", "<Esc>", function()
      if not require("copilot-lsp.nes").clear() then
        vim.cmd("nohlsearch") -- fallback: limpiar highlight de busqueda
      end
    end, { desc = "Clear NES or nohlsearch" })
  end,
}
