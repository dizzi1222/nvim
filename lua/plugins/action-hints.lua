-- ⚡ Action Hints (roobert/action-hints.nvim)
-- Muestra bajo el cursor qué acciones LSP hay para la palabra actual:
--   ⊛   → definición disponible        ↱N  → N referencias (gr)
-- El plugin NO registra keymaps (solo autocmds CursorMoved/I con request LSP
-- debounced 100ms) → no choca con agy (<leader>ag/G/gg) ni con git.
--
-- Atajos dedicados (evitan pisar gd/gr ya ocupados por copilot-chat/LazyVim):
--   gT  → go-to-definition   gR  → references
-- ⚠️ nvim usa gT por defecto para "previous tab"; queda reasignado (los tabs
-- siguen disponibles con [T / ]T como en LazyVim).
return {
  {
    "roobert/action-hints.nvim",
    config = function()
      require("action-hints").setup({
        template = {
          definition = { text = " ⊛", color = "#add8e6" },
          references = { text = " ↱%s", color = "#ff6666" },
        },
        use_virtual_text = true,
      })

      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "gt", function() -- similar a <leader>gd (go to definition)
        telescope.lsp_definitions()
      end, { desc = "⚡ Definición (LSP)", silent = true })
      vim.keymap.set("n", "gr", function() -- similar a <leader>sw (search word [RIPGREP])
        telescope.lsp_references()
      end, { desc = "⚡ Referencias (LSP)", silent = true })
      -- 🧠 Inspect e InspectTree NO son del plugin: son NATIVOS de LazyVim/LSP
      -- (builtins de nvim). Aparecen siempre en el menú de acciones al hacer
      -- click/saltar sobre una definición — estos atajos solo los hacen cómodos.
      --   <leader>gx → :Inspect      (nodo treesitter + grupos de highlight bajo el cursor)
      --   gX         → :InspectTree  (árbol treesitter completo del buffer)
      vim.keymap.set("n", "<leader>gx", "<cmd>Inspect<cr>", {
        desc = "⚡ Inspect: TS node + hl (nativo)",
        silent = true,
      })
      vim.keymap.set("n", "gX", "<cmd>InspectTree<cr>", {
        desc = "⚡ InspectTree: árbol de sintaxis TS (nativo)",
        silent = true,
      })
    end,
  },
}
