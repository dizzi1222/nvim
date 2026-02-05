-- =============================
-- KEYMAPS FITTENCODE  | 🐐🗣️🔥️✍️ NO REQUIERE API
-- =============================
-- Utilidades y atajos para Fittencode AI

local keymap = vim.keymap

-- Verificar que fittencode esté disponible
local has_fitten = pcall(require, 'fittencode')
if not has_fitten then
  return
end

local fitten = require('fittencode')

-- =============================
-- MENU INTERACTIVO
-- =============================

local function show_fitten_menu(selected_text)
  local options = {
    "  󱋑  Revisar código",
    "  󱜨 Explicar código",
    "   Encontrar bugs",
    "  󰈏 Refactorizar",
    "  󰓅 Optimizar",
    "  󰔷 Documentar código",
    "  󰙨 Generar tests",
    "  󰡱 Implementar features",
    "  󰗊 Traducir a español",
    "  󱋑 Iniciar chat",
  }

  vim.ui.select(options, {
    prompt = "🤖 Fittencode - Selecciona acción:",
  }, function(choice, idx)
    if not choice then return end

    local actions = {
      function() fitten.edit_code() end,
      function() fitten.explain_code() end,
      function() fitten.find_bugs() end,
      function() fitten.refactor_code() end,
      function() fitten.optimize_code() end,
      function() fitten.document_code() end,
      function() fitten.generate_unit_test() end,
      function() fitten.implement_features() end,
      function() fitten.translate_text_into_spanish() end,
      function() fitten.start_chat() end,
    }

    if actions[idx] then
      actions[idx]()
    end
  end)
end

-- =============================
-- KEYMAPS PRINCIPALES
-- =============================

-- Menú interactivo
keymap.set("n", "<leader>aff", show_fitten_menu, {
  desc = " 󰚩 Fittencode - Menú",
})

keymap.set("v", "<leader>aff", function()
  show_fitten_menu()
end, {
  desc = " 󰚩 Fittencode - Menú (selección)",
})

-- Chat
keymap.set("n", "<leader>afc", function()
  fitten.start_chat()
end, {
  desc = " Fittencode - Chat",
})

keymap.set("n", "<leader>afC", function()
  fitten.toggle_chat()
end, {
  desc = "󰍪 Fittencode - Toggle Chat",
})

-- =============================
-- ACCIONES RÁPIDAS
-- =============================

-- Explicar
keymap.set({"n", "v"}, "<leader>afe", function()
  fitten.explain_code()
end, {
  desc = "󱜨 Fittencode - Explicar",
})

-- Refactorizar
keymap.set({"n", "v"}, "<leader>afr", function()
  fitten.refactor_code()
end, {
  desc = "󰈏 Fittencode - Refactorizar",
})

-- Optimizar
keymap.set({"n", "v"}, "<leader>afo", function()
  fitten.optimize_code()
end, {
  desc = "󰓅 Fittencode - Optimizar",
})

-- Documentar
keymap.set({"n", "v"}, "<leader>afd", function()
  fitten.document_code()
end, {
  desc = "󰔷 Fittencode - Documentar",
})

-- Encontrar bugs
keymap.set({"n", "v"}, "<leader>afb", function()
  fitten.find_bugs()
end, {
  desc = " Fittencode - Find Bugs",
})

-- Generar tests
keymap.set({"n", "v"}, "<leader>aft", function()
  fitten.generate_unit_test()
end, {
  desc = "󰙨 Fittencode - Tests",
})

-- Editar código
keymap.set({"n", "v"}, "<leader>afE", function()
  fitten.edit_code()
end, {
  desc = "󱋑 Fittencode - Editar",
})

-- =============================
-- CONTROL DE AUTOCOMPLETADO
-- =============================

-- Toggle autocompletado
keymap.set("n", "<leader>afT", function()
  vim.cmd("Fitten disable_completions")
  vim.notify("󰚩 Fittencode - Autocompletado desactivado", vim.log.levels.INFO)
end, {
  desc = " 󰚩 Fittencode - Toggle OFF",
})

keymap.set("n", "<leader>afA", function()
  vim.cmd("Fitten enable_completions")
  vim.notify("󰚩 Fittencode - Autocompletado activado", vim.log.levels.INFO)
end, {
  desc = " 󰚩 Fittencode - Toggle ON",
})

-- Trigger manual
keymap.set("i", "<C-Space>", function()
  fitten.triggering_completion()
end, {
  desc = " 󰚩 Fittencode - Trigger manual",
})

-- =============================
-- UTILIDADES
-- =============================

-- Info del status
vim.api.nvim_create_user_command("FittenStatus", function()
  local status = fitten.get_current_status()
  local status_names = {
    [1] = "🚫 Desactivado",
    [2] = "⏸️  Idle",
    [3] = "⌛️ Generando",
    [4] = "⚠️  Error",
    [5] = "0️⃣  Sin sugerencias",
    [6] = "✅ Listo",
  }
  vim.notify(" 󰚩 Fittencode: " .. status_names[status], vim.log.levels.INFO)
end, {})

-- Login
keymap.set("n", "<leader>afl", function()
  vim.cmd("Fitten login") -- usuario: dizzi1222
end, {
  desc = "󰍃 Fittencode - Logout",
})
-- Logout/Login
keymap.set("n", "<leader>afL", function()
  vim.cmd("Fitten logout")
end, {
  desc = "󰍃 Fittencode - Logout",
})

