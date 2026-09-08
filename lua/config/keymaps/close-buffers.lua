-- Extract from: keymaps.lua
-- config/keymaps/close-buffers.lua

vim.g.mapleader = " "

local keymap = vim.keymap

-- MRU: retorna el buffer normal listado usado más recientemente (excluye el actual)
local function get_prev_buffer()
  local cur = vim.api.nvim_get_current_buf()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  local best, best_last = nil, -1
  for _, buf in ipairs(buffers) do
    local last = buf.lastused or 0
    if
      buf.bufnr ~= cur
      and last > best_last
      and vim.api.nvim_buf_is_valid(buf.bufnr)
      and vim.bo[buf.bufnr].buftype == ""
    then
      best, best_last = buf.bufnr, last
    end
  end
  return best
end

-- Cambia al buffer anterior por MRU y borra el actual manteniendo la ventana
local function close_buffer(bufnr)
  local prev = get_prev_buffer()
  if prev then
    vim.api.nvim_win_set_buf(0, prev)
    vim.cmd("bdelete " .. bufnr)
    return true
  end
  return false
end

-- =============================
-- CERRAR BUFFER (PASIVO)
-- Equivalente a: <leader>bd
-- =============================
vim.keymap.set("n", "<M-q>", function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not close_buffer(bufnr) then
    vim.cmd("enew")
    vim.cmd("bdelete " .. bufnr)
  end
end, { noremap = true, silent = true, desc = "Borrar buffer manteniendo ventana" })

-- =============================
-- CERRAR BUFFERS INTELIGENTE (+split)
-- Equivalente a: <leader>bD
-- =============================
--🛑 🗿 Cerrar pestaña Y buffer
keymap.set("n", "<C-q>", function()
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype
  local bufnr = vim.api.nvim_get_current_buf()

  -- Lista de ventanas especiales
  local special_filetypes = {
    "neo-tree",
    "NvimTree",
    "help",
    "qf",
    "quickfix",
    "terminal",
    "Avante",
    "AvanteInput",
    "AvanteAsk",
    "AvanteSelectedFiles",
    "copilot-chat",
    "opencode_output",
    "opencode_input",
  }

  -- Verificar si es ventana especial
  local is_special = vim.tbl_contains(special_filetypes, filetype) or buftype ~= ""

  if is_special then
    -- Cerrar ventana especial
    pcall(vim.cmd, "close")

    -- Eliminar buffer después de cerrar
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        pcall(function()
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
      end
    end, 100)
    return
  end

  -- Para buffers normales
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  local normal_buffers = vim.tbl_filter(function(buf)
    return vim.fn.getbufvar(buf.bufnr, "&buftype") == ""
  end, buffers)

  if #normal_buffers > 1 then
    local prev = get_prev_buffer()
    if prev then
      vim.api.nvim_win_set_buf(0, prev)
      vim.cmd("bdelete " .. bufnr)
    else
      vim.cmd("bnext")
      vim.cmd("bdelete " .. bufnr)
    end
  else
    vim.cmd("quit!")
  end
end, {
  noremap = true,
  silent = true,
  desc = "🛑 Cerrar split Y borrar buffer",
})

-- =============================
-- CERRAR SOLO BUFFER (nuevo atajo)
-- =============================
keymap.set("n", "<leader>bw", ":bdelete<CR>", {
  desc = "Cerrar buffer actual",
})

-- =============================
-- OCULTAR/MOSTRAR BUFFERS
-- =============================
keymap.set("n", "<leader>bh", ":hide<CR>", {
  desc = "Ocultar buffer (mantener en memoria)",
})

keymap.set("n", "<leader>ba", ":ls!<CR>", {
  desc = "All - Listar todos los buffers (incluyendo ocultos)",
})

keymap.set("n", "<leader>bz", ":buffers<CR>:buffer<Space>", {
  desc = "Zxy - Cambiar a buffer por número",
})

keymap.set("n", "<leader>bc", ":enew | bdelete #<CR>", {
  desc = "Cerrar buffer pero mantener ventana",
})
