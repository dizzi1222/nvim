-- Extract from: keymaps.lua
-- ==================================================================
-- [⚠ BETA⚠!] KEYMAPS OLLAMA AI (LOCAL) 󰎣 🦙🤖🔥️ NO REQUIERE INTERNET
-- ==================================================================
-- Detectar plataforma
local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

vim.g.mapleader = " "

local keymap = vim.keymap

-- Como agrego: /set nothink
-- En los 6 primeras opciones de Ollama, agrego: set nothink
-- Ruta del archivo de configuración
local config_dir = vim.fn.stdpath("data") .. "/ollama"
local config_file = config_dir .. "/model.txt"

-- Función para cargar el modelo guardado
local function load_ollama_model()
  if vim.fn.filereadable(config_file) == 1 then
    local model = vim.fn.readfile(config_file)[1]
    if model and model ~= "" then
      return model
    end
  end
  return "deepseek-r1" -- Modelo por defecto
end

-- Función para guardar el modelo
local function save_ollama_model(model)
  vim.fn.mkdir(config_dir, "p")
  vim.fn.writefile({ model }, config_file)
end

-- Helper para buscar el comando de ollama (WSL/Windows/Linux)
local function get_ollama_cmd()
  -- 1. Verificar si hay comando custom
  if vim.g.ollama_cmd_custom then
    return vim.g.ollama_cmd_custom
  end

  -- 2. Buscar ollama nativo
  if vim.fn.executable("ollama") == 1 then
    return vim.fn.exepath("ollama")
  end

  -- 3. En Windows, buscar ollama.exe
  if is_windows and vim.fn.executable("ollama.exe") == 1 then
    return vim.fn.exepath("ollama.exe")
  end

  -- 4. En WSL, intentar usar ollama de Windows
  if is_wsl and vim.fn.executable("wsl") == 1 then
    return "wsl $SHELL -lic"
  end

  return nil
end

-- Cargar modelo al iniciar
vim.g.ollama_model = load_ollama_model()

-- 🔥 FUNCIÓN CORREGIDA: Envío secuencial para /set nothink
local function open_ollama(prompt, input_text, use_nothink)
  local cmd_exec = get_ollama_cmd()
  if not cmd_exec then
    vim.notify("❌ Ollama no encontrado. Asegúrate de tenerlo instalado y en tu PATH.", vim.log.levels.ERROR)
    return
  end

  local model = vim.g.ollama_model
  vim.cmd("vsplit | vertical resize 50")

  local full_cmd
  if cmd_exec:match("^wsl.*-lic$") then
    full_cmd = cmd_exec .. " 'ollama run " .. model .. "'"
  else
    full_cmd = cmd_exec .. " run " .. model
  end

  vim.cmd("term " .. full_cmd)

  -- 🎯 CONSTRUIR EL MENSAJE COMPLETO
  local full_message = prompt
  if input_text and input_text ~= "" then
    full_message = full_message .. "\n\nAnaliza este código:\n" .. input_text
  end

  -- ⚡ ENVÍO SECUENCIAL
  if use_nothink then
    -- PASO 1: Enviar /set nothink (esperar 800ms)
    vim.defer_fn(function()
      if vim.b.terminal_job_id then
        vim.api.nvim_chan_send(vim.b.terminal_job_id, "/set nothink\n")

        -- PASO 2: Enviar el mensaje real (esperar otros 1200ms)
        vim.defer_fn(function()
          if vim.b.terminal_job_id then
            vim.api.nvim_chan_send(vim.b.terminal_job_id, full_message .. "\n")
          end
        end, 1200) -- ⏱️ Esperar a que Ollama procese /set nothink
      end
    end, 800)
  else
    -- Sin nothink: enviar directo
    vim.defer_fn(function()
      if vim.b.terminal_job_id then
        vim.api.nvim_chan_send(vim.b.terminal_job_id, full_message .. "\n")
      end
    end, 800)
  end

  vim.cmd("startinsert")
end

-- 🆕 Función para listar modelos
local function show_ollama_list()
  local cmd_exec = get_ollama_cmd()
  if not cmd_exec then
    vim.notify("❌ Ollama no encontrado.", vim.log.levels.ERROR)
    return
  end

  vim.cmd("split")

  -- Si usamos WSL wrapper, necesitamos quotear el comando
  local full_cmd
  if cmd_exec:match("^wsl.*-lic$") then
    full_cmd = cmd_exec .. " 'ollama list'"
  else
    full_cmd = cmd_exec .. " list"
  end

  vim.cmd("term " .. full_cmd)
  vim.cmd("startinsert")
end

-- 🔥 FUNCIÓN MEJORADA: Ver Y EDITAR Modelfile
local function show_ollama_modelfile()
  local model = vim.g.ollama_model

  -- Crear directorio para Modelfiles
  local modelfile_dir = vim.fn.stdpath("data") .. "/ollama/modelfiles"
  vim.fn.mkdir(modelfile_dir, "p")

  -- Nombre del archivo (reemplazar : por _)
  local safe_model_name = model:gsub(":", "_")
  local modelfile_path = modelfile_dir .. "/" .. safe_model_name .. ".modelfile"

  -- 1️⃣ Extraer Modelfile con sistema operativo detectado
  -- 1️⃣ Extraer Modelfile con sistema operativo detectado y comando validado
  local cmd_exec = get_ollama_cmd()
  if not cmd_exec then
    vim.notify("❌ Ollama no encontrado.", vim.log.levels.ERROR)
    return
  end

  local extract_cmd
  -- Si usamos WSL wrapper, necesitamos quotear el comando completo
  if cmd_exec:match("^wsl.*-lic$") then
    -- Convertir ruta de Windows a WSL (C:\... -> /mnt/c/...)
    local wsl_path = modelfile_path:gsub("\\", "/"):gsub("^(%a):", function(drive)
      return "/mnt/" .. drive:lower()
    end)

    extract_cmd = string.format('%s "ollama show %s --modelfile > %s"', cmd_exec, model, wsl_path)
  else
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- Windows CMD
      extract_cmd = string.format('%s show %s --modelfile > "%s"', cmd_exec, model, modelfile_path)
    else
      -- Linux/WSL/macOS
      extract_cmd = string.format("%s show %s --modelfile > %s", cmd_exec, model, vim.fn.shellescape(modelfile_path))
    end
  end

  vim.notify("📥 Extrayendo Modelfile de: " .. model, vim.log.levels.INFO)
  vim.fn.system(extract_cmd)

  -- Verificar si se extrajo correctamente
  if vim.v.shell_error ~= 0 then
    vim.notify("❌ Error al extraer Modelfile. ¿Existe el modelo " .. model .. "?", vim.log.levels.ERROR)
    return
  end

  -- 2️⃣ Abrir el archivo en Neovim
  vim.cmd("split " .. vim.fn.fnameescape(modelfile_path))

  -- 3️⃣ Configurar el buffer
  vim.bo.filetype = "dockerfile" -- Syntax highlighting

  -- 4️⃣ Agregar instrucciones al inicio
  local instructions = {
    "# 󱜨 MODELFILE DE: " .. model,
    "# ",
    "# 🔧 EDITA ESTE ARCHIVO Y GUARDA CON :w",
    "# 󰉁 APLICA CAMBIOS: :OllamaApply  Esto descarga el modelo custom",
    "# ",
    "# 󰧑 🔧¿Como desactivar NOTHINK? ",

    "# ",
    "# Solución 1: Usa /set nothink en CLI (Más Simple), Ej:",
    "# ollama run deepseek-v3.1:671b-cloud",
    "# >>> /set nothink",
    "# >>> Tu pregunta aqui.",

    "# Solución 2: Usar el archivo de modelfile (Más Complejo), Ej:",
    "# ",
    "# 📚 Docs: https://github.com/ollama/ollama/blob/main/docs/modelfile.md",
    "# ",
    "# EJEMPLOS DE PERSONALIZACIÓN:",
    "# PARAMETER temperature 0.7    # Creatividad (0.0 = conservador, 1.0 = creativo)",
    "# PARAMETER num_ctx 16384        # Contexto (tokens de memoria)",
    "# PARAMETER stop '<think>' # Para evitar que el modelo se preocupe por preguntas",
    "# PARAMETER stop '</think>'",

    "# SYSTEM 'Eres un experto en...'' # Prompt del sistema",
    "# SYSTEM 'Eres un asistente de programación experto en MERN stack. Responde de forma directa sin mostrar tu proceso de pensamiento interno.'",
    "# ",
    "",
  }

  vim.api.nvim_buf_set_lines(0, 0, 0, false, instructions)

  -- 5️⃣ Crear comando :OllamaApply (solo en este buffer)
  vim.api.nvim_buf_create_user_command(0, "OllamaApply", function()
    -- Guardar cambios primero
    vim.cmd("write")

    vim.ui.input({
      prompt = "Nombre del nuevo modelo (Enter = " .. model .. "-custom): ",
      default = model .. "-custom",
    }, function(input)
      if not input or input == "" then
        return
      end

      local create_cmd = string.format("%s create %s -f %s", cmd_exec, input, vim.fn.shellescape(modelfile_path))
      vim.notify("🔨 Creando modelo: " .. input .. " ...", vim.log.levels.INFO)

      -- Ejecutar en terminal
      vim.cmd("split")
      vim.cmd("term " .. create_cmd)

      -- Actualizar modelo activo después de 2 segundos
      vim.defer_fn(function()
        vim.g.ollama_model = input
        save_ollama_model(input)
        vim.notify("✅ Modelo creado y activado: " .. input, vim.log.levels.INFO)
      end, 2000)
    end)
  end, { desc = " 󰎣  Crear modelo personalizado desde este Modelfile" })

  vim.notify("󱜨 Edita el Modelfile. Aplica con :OllamaApply", vim.log.levels.INFO)
end

local function show_ollama_menu(selected_text)
  local current_model = vim.g.ollama_model or "deepseek-r1"
  local options = {
    "󰎣  Revisar código ",
    "󰎣 󱜨 [Local] Explicar código ",
    "󰎣  [Local] Debuggear error ",
    "󰎣 󰈏 [Local] Refactorizar ",
    "󰎣 󰓅 [Local] Optimizar ",
    "󰎣 󱋑 [Local] Chat Libre ",
    "󰎣 󱁻 [Local] Ver/Editar Modelfile (" .. current_model .. ") ",
    "󰎣 󰊾🐐 [Local] Listar modelos instalados ",
    "󰎣 󰓡 [Local] Cambiar modelo (" .. current_model .. ") ",
    "󰎣 󰍂 [Local] Logearte con Ollama + API para usar CLOUD ",
  }

  vim.ui.select(options, {
    prompt = " 󰎣  ~ Ollama (" .. current_model .. "):",
  }, function(choice, idx)
    if not choice then
      return
    end

    local prompts = {
      "Revisa este código y sugiere mejoras:",
      "Explica este código paso a paso:",
      "Debuggea este error:",
      "Refactoriza este código:",
      "Optimiza este código:",
      "",
    }

    -- Opciones que usan /set nothink (primeras 5)
    local use_nothink = idx >= 1 and idx <= 5

    if idx == 7 then -- Ver/Editar Modelfile
      show_ollama_modelfile()
    elseif idx == 8 then -- Listar modelos
      show_ollama_list()
    elseif idx == 9 then -- Cambiar modelo
      vim.ui.input({
        prompt = "Nuevo modelo (ej: llama3, mistral, qwen2.5-coder): ",
        default = current_model,
      }, function(input)
        if input and input ~= "" then
          vim.g.ollama_model = input
          save_ollama_model(input)
          vim.notify("✅ Modelo guardado: " .. input, vim.log.levels.INFO)
        end
      end)
    elseif idx == 10 then -- Login + Cloud
      vim.cmd("vsplit | vertical resize 50")
      -- 🎨 Con colores
      vim.cmd("term unbuffer ollama signin | bat --color=always --style=plain")
      vim.notify("🚀 Ejecutando signin con colores", vim.log.levels.INFO)
    elseif idx == 6 then -- Chat Libre
      vim.ui.input({ prompt = "Ollama Prompt: " }, function(input)
        if input and input ~= "" then
          -- Preguntar si quiere usar /set nothink
          vim.ui.select({ "Sí, desactivar reasoning", "No, mostrar reasoning" }, {
            prompt = "¿Desactivar reasoning (/set nothink)?",
          }, function(choice2, idx2)
            open_ollama(input, selected_text, idx2 == 1)
          end)
        end
      end)
    else -- Usar prompt con o sin /set nothink según la opción
      open_ollama(prompts[idx], selected_text, use_nothink)
    end
  end)
end

-- MAPEOS
vim.keymap.set("n", "<leader>al", function()
  show_ollama_list()
end, { desc = " 󰎣  🦙 Listar modelos" })

vim.keymap.set("v", "<leader>aO", function()
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  show_ollama_menu(selected_text)
end, { desc = " 󰎣  🦙 Enviar selección a Ollama" })

-- Mapeos DESACTIVADOS TEMPORALMENTE!!!
-- vim.keymLap.set("n", "<leader>aO", function()
--   show_ollama_menu(nil)
-- end, { desc = " 󰎣  🦙 Abrir Ollama" })

-- Comandos
vim.api.nvim_create_user_command("OllamaModel", function()
  vim.notify(" 󰎣  🦙 Modelo actual: " .. vim.g.ollama_model, vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("OllamaList", function()
  show_ollama_list()
end, {})

-- Mapeos directos
-- vim.keymap.set("n", "<leader>am", function()
--   show_ollama_modelfile()
-- end, { desc = " 󰎣  🦙 Ver/Editar Modelfile" })

-- Switch / Cambiar Modelo ~ <leader>as
-- vim.keymap.set("n", "<leader>as", function()
--   local current_model = vim.g.ollama_model or "deepseek-r1"
--   vim.ui.input({
--     prompt = " 󰎣  🦙 Nuevo modelo (actual: " .. current_model .. "): ",
--     default = current_model,
--   }, function(input)
--     if input and input ~= "" then
--       vim.g.ollama_model = input
--       save_ollama_model(input)
--       vim.notify("✅ Modelo guardado: " .. input, vim.log.levels.INFO)
--     end
--   end)
-- end, { desc = " 󰎣  🦙 Switch/Cambiar modelo de Ollama rápido" })
