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
vim.keymap.set("n", "<C-q>", function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not close_buffer(bufnr) then
    vim.cmd("enew")
    vim.cmd("bdelete " .. bufnr)
  end
end, { noremap = true, silent = true, desc = "Borrar buffer manteniendo ventana" })

-- =============================
-- 🛑 CERRAR PESTAÑA / SPLIT + BUFFER
-- Prioridad: split > tab > buffer (fallback MRU)
-- =============================

-- Ventanas especiales (no-file) que se cierran a sí mismas
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

--- Determina si el buffer actual pertenece a una ventana especial (no-file)
---@param buftype string buftype del buffer actual
---@param filetype string filetype del buffer actual
---@return boolean
local function is_special_win(buftype, filetype)
  return vim.tbl_contains(special_filetypes, filetype) or buftype ~= ""
end

--- Cierra el split de una ventana especial y borra su buffer.
--- Si es la única ventana, reemplaza el contenido en vez de cerrar.
---@param bufnr number buffer especial a cerrar
local function close_special(bufnr)
  if vim.fn.winnr("$") > 1 then
    local wins_before = vim.fn.winnr("$")
    pcall(vim.cmd, "close")
    -- Solo borrar si el split realmente se cerró
    if vim.fn.winnr("$") < wins_before and vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  else
    -- Última ventana: no se puede close → reemplazar contenido y borrar
    local prev = get_prev_buffer()
    if prev then
      vim.api.nvim_win_set_buf(0, prev)
    else
      vim.cmd("enew")
    end
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

keymap.set("n", "<M-q>", function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 1) Ventana especial → cerrar split + borrar buffer
  if is_special_win(vim.bo.buftype, vim.bo.filetype) then
    close_special(bufnr)
    return
  end

  -- 2) Más de una ventana en esta tab → cerrar el split y borrar el buffer
  if vim.fn.winnr("$") > 1 then
    local wins_before = vim.fn.winnr("$")
    vim.cmd("confirm close")
    if vim.fn.winnr("$") < wins_before and vim.api.nvim_buf_is_valid(bufnr) then
      vim.cmd("silent! bdelete! " .. bufnr)
    end
    return
  end

  -- 3) Única ventana pero más de una tab → cerrar la pestaña y borrar el buffer
  if vim.fn.tabpagenr("$") > 1 then
    local tabs_before = vim.fn.tabpagenr("$")
    vim.cmd("confirm tabclose")
    if vim.fn.tabpagenr("$") < tabs_before and vim.api.nvim_buf_is_valid(bufnr) then
      vim.cmd("silent! bdelete! " .. bufnr)
    end
    return
  end

  -- 4) Última ventana → saltar al MRU y borrar el buffer
  local prev = get_prev_buffer()
  if prev then
    vim.api.nvim_win_set_buf(0, prev)
  else
    vim.cmd("enew")
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.cmd("confirm bdelete " .. bufnr)
  end
end, {
  noremap = true,
  desc = "🛑 Cerrar tab/split y borrar buffer",
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
