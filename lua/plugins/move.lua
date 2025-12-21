-- En plugins/move.lua o donde tengas tus configuraciones de plugins
return {
  "fedepujol/move.nvim",
  config = function()
    require("move").setup({
      -- Configuración (opcional)
      line = {
        enable = true,
        indent = true, -- Auto-indentado al mover
      },
      block = {
        enable = true,
        indent = true,
      },
      word = {
        enable = true,
      },
    })

    -- ⚠️ =========================== NO ME FUNCIONABA move-line, opte por move.lua para Windows.
    local opts = { noremap = true, silent = true }

    -- Normal-mode commands
    vim.keymap.set("n", "<A-j>", ":MoveLine(1)<CR>", opts)
    vim.keymap.set("n", "<A-Down>", ":MoveLine(1)<CR>", opts)
    vim.keymap.set("n", "<A-Up>", ":MoveLine(-1)<CR>", opts)
    vim.keymap.set("n", "<A-k>", ":MoveLine(-1)<CR>", opts)
    vim.keymap.set("n", "<A-h>", ":MoveHChar(-1)<CR>", opts)
    vim.keymap.set("n", "<A-l>", ":MoveHChar(1)<CR>", opts)
    vim.keymap.set("n", "<leader>wf", ":MoveWord(1)<CR>", opts)
    vim.keymap.set("n", "<leader>wb", ":MoveWord(-1)<CR>", opts)

    -- Visual-mode commands
    vim.keymap.set("v", "<A-j>", ":MoveBlock(1)<CR>", opts)
    vim.keymap.set("v", "<A-Down>", ":MoveBlock(1)<CR>", opts)
    vim.keymap.set("v", "<A-Up>", ":MoveBlock(-1)<CR>", opts)
    vim.keymap.set("v", "<A-k>", ":MoveBlock(-1)<CR>", opts)
    vim.keymap.set("v", "<A-h>", ":MoveHBlock(-1)<CR>", opts)
    vim.keymap.set("v", "<A-l>", ":MoveHBlock(1)<CR>", opts)

    -- ✅ MAPEOS QUE SÍ FUNCIONAN EN WINDOWS - CONFIRMADOS
    vim.keymap.set("n", "<F2>", ":MoveLine(1)<CR>", opts) -- Mover línea ABAJO
    vim.keymap.set("n", "<F3>", ":MoveLine(-1)<CR>", opts) -- Mover línea ARRIBA
    vim.keymap.set("v", "<F2>", ":MoveBlock(1)<CR>", opts) -- Mover bloque ABAJO
    vim.keymap.set("v", "<F3>", ":MoveBlock(-1)<CR>", opts) -- Mover bloque ARRIBA
  end,
}
