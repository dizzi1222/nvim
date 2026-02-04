-- =============================
-- KEYMAPS AI EN TERMUX 🤖
-- =============================
-- Soporta: aichat, tgpt
-- Similar a gemini-keys.lua pero para Termux

local keymap = vim.keymap

-- Detectar si aichat o tgpt están disponibles
local has_aichat = vim.fn.executable("aichat") == 1
local has_tgpt = vim.fn.executable("tgpt") == 1

if not has_aichat and not has_tgpt then
  return -- No hacer nada si ninguno está instalado
end

-- Elegir herramienta preferida (aichat > tgpt)
local ai_cmd = has_aichat and "aichat" or "tgpt"

-- Mapeo para salir del terminal con ESC
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

local function open_ai(prompt, input_text)
  local root = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  vim.cmd("vsplit | vertical resize 50")

  local cmd
  if ai_cmd == "aichat" then
    -- aichat con contexto del directorio
    cmd = 'cd "' .. root .. '" && aichat'
  else
    -- tgpt en modo interactivo
    -- cmd = 'tgpt -i'
    cmd = "tgpt"
  end

  vim.cmd("term " .. cmd)

  -- Enviar prompt + texto si existe
  if prompt and prompt ~= "" then
    local full_prompt = prompt
    if input_text and input_text ~= "" then
      full_prompt = prompt .. "\n\n```\n" .. input_text .. "\n```"
    end

    vim.defer_fn(function()
      vim.api.nvim_chan_send(vim.b.terminal_job_id, full_prompt .. "\n")
    end, 500)
  end

  vim.cmd("startinsert")
end

local function show_ai_menu(selected_text)
  local options = {
    "  󱋑  Revisar código",
    "  󱜨 Explicar código",
    "   Debuggear error",
    "  󰈏 Refactorizar",
    "  󰓅 Optimizar",
    "  󰔷 Agregar comentarios",
    "  󰙨 Escribir tests",
    "   󱋑 Personalizado [Prompt libre]",
  }

  vim.ui.select(options, {
    prompt = " 🤖 ~ Selecciona acción (" .. ai_cmd .. "):",
  }, function(choice, idx)
    if not choice then
      return
    end

    local prompts = {
      "Revisa este código y sugiere mejoras específicas:",
      "Explica este código línea por línea, en español:",
      "Este código tiene un error. Analízalo y dame la solución:",
      "Refactoriza este código para hacerlo más limpio y eficiente:",
      "Optimiza este código para mejor rendimiento:",
      "Agrega comentarios descriptivos a este código:",
      "Escribe tests unitarios para este código:",
      "", -- Personalizado
    }

    if idx == 8 then -- Opción personalizada
      vim.ui.input({
        prompt = "Tu prompt: ",
      }, function(input)
        if input and input ~= "" then
          open_ai(input, selected_text)
        end
      end)
    else
      open_ai(prompts[idx], selected_text)
    end
  end)
end

-- Mapeo para modo normal
keymap.set("n", "<leader>aA", function()
  show_ai_menu(nil)
end, {
  desc = " ~ Abrir AI (" .. ai_cmd .. ") con menú",
})

-- Mapeo para modo visual
keymap.set("v", "<leader>aA", function()
  -- Copiar texto seleccionado
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  show_ai_menu(selected_text)
end, {
  desc = " ~ Enviar selección a AI (" .. ai_cmd .. ")",
})

-- Mapeo adicional para abrir AI directamente (sin menú)
keymap.set("n", "<leader>ax", function()
  open_ai(nil, nil)
end, {
  desc = " ~ Abrir AI (" .. ai_cmd .. ") directo",
})

-- Mapeo para tgpt directo (sin interactivo)
keymap.set("n", "<leader>aX", function()
  local root = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  vim.cmd("vsplit | vertical resize 50")
  vim.cmd('term cd "' .. root .. '" && tgpt -i')
  -- vim.cmd('term cd "' .. root .. '" && tgpt')
  vim.cmd("startinsert")
end, {
  desc = "🤖 ~ tgpt directo (sin menú)",
})

-- Versión para visual (enviar selección a tgpt directo)
keymap.set("v", "<leader>aX", function()
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  local root = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  vim.cmd("vsplit | vertical resize 50")
  vim.cmd('term cd "' .. root .. '" && tgpt -i')
  -- vim.cmd('term cd "' .. root .. '" && tgpt')

  vim.defer_fn(function()
    vim.api.nvim_chan_send(vim.b.terminal_job_id, selected_text .. "\n")
  end, 500)

  vim.cmd("startinsert")
end, {
  desc = "🤖 ~ Enviar a tgpt directo",
})

-- Info sobre qué AI está activa
vim.api.nvim_create_user_command("AIInfo", function()
  local msg = "🤖 AI activa: " .. ai_cmd
  if has_aichat and has_tgpt then
    msg = msg .. "\n✅ Disponibles: aichat, tgpt"
  elseif has_aichat then
    msg = msg .. "\n✅ Solo aichat disponible"
  else
    msg = msg .. "\n✅ Solo tgpt disponible"
  end
  vim.notify(msg, vim.log.levels.INFO)
end, {})
