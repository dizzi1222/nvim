-- Al inicio de keymaps.lua

-- 🦈 <-- TRUCAZO DE OIL: --> ✨
-- Asi como existe :10 [line preview] tambien lo dispone OIL con:
-- {Navegar en directorio = -} + Ctrl + Q [puedes ver los archivos sin abrirlos]
-- 🦈 <-- TRUCAZO DE OIL. --> ✨

-- PARA Configurar IAS, revisa:
-- config/lazy.lua
-- plugins/disabled
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua
--
-- KEYMAPS DE CHAT por IA FUNCIONAN AL SELECCIONAR TEXTO [v]

-- =============================
-- CONFIG BASICA [+GUIA ATAJOS]
-- =============================
-- Detectar plataforma
local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

vim.g.mapleader = " "

local keymap = vim.keymap

-- keymap.set("i", "jj", "<ESC>") -- salir del modo insercion con jj
keymap.set("n", "<ESC>", ":noh<CR>")
vim.keymap.set("v", "<A-S-f>", vim.lsp.buf.format)
--💫 PARA OBTENER INFORMACION DE UN BUFFER Y SUS MAPEOS: UTILIZA:[2 puntos] :lua print(vim.inspect(vim.api.nvim_buf_get_keymap(0, "i")))
--
-- 🗣️ ATAJOS DE IA y OIL/snack_picker_list tree EXPLORER QUE DEBES SABER:
-- 🐐 1- ATAJO IMPORTANTE: - {minus -} [oil ~ requiere oil]-
-- te lleva al directorio en el que te encuentras [GOZZZZ]
-- 🐐 1.5 - ATAJO IMPORTANTE: Space E [mayus] \ o usa: Space + Shift + E [Abre oil flotante] ) \ AL SELECCIONAR TEXTO [v]-
-- 🐐 2- ATAJO IMPORTANTE: Space+e [minus] [snack ~ requiere: fd fd-find]
-- 🐐 3- ATAJO IMPORTANTE: Space+N  [notifaciones - como :mes pero mejor para depurar codigo!! ]
-- 🐐 4- ATAJO IMPORTANTE: Space+M ejecutar el markdown render ej Space + M+R
-- 🐐 5- accept Copilot/Tabnine etc = "<Tab>", -- acepta sugerencia
--       dismisss Copilot/Tabnine = "<C-c> o con ESC", -- cancela sugerencia
-- 🐐 6- abrir menu IA panel {claude api} = Space + A -- tambien puedesc crear un new file
-- keymap = {
--   accept = "<C-Tab>", -- acepta sugerencia
--   next = "<C-]>",
--   prev = "<C-[>",
--   dismiss = "<C-",

-- 🗣️ ATAJOS OIL tree EXLORER:
-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
-- keymaps =
--   {
--     ["g?"] = "actions.show_help",
--     ["<CR>"] = "actions.select",
--     ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
--     ["<C-v>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
-- ESTE NO LO RECOMIENDO, lo quite.     -- ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
--     ["<C-p>"] = "actions.preview",
--     ["<C-c>"] = "actions.close",
--     ["<C-r>"] = "actions.refresh",
--     ["-"] = "actions.parent",
--     ["_"] = "actions.open_cwd",
--     ["`"] = "actions.cd",
--     ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
--     ["gs"] = "actions.change_sort",
--     ["gx"] = "actions.open_external",
--     ["g."] = "actions.toggle_hidden",
--     ["g\\"] = "actions.toggle_trash",
--     -- Quick quit
--     ["q"] = "actions.close",
--   },
-- similar al EXPLORER snack_picker_list

-- =============================
-- ABRIR EXPLORER, EN macOS, wsl, Linux
-- =============================

-- Abrir el explorador de archivos o copiar la ruta del archivo actual
-- Tanto en Windows Explorer, Linux (Nautilus, Dolphin, Thunar) y macOS
-- Si, Dolphin es un explorer..

-- Abrir el explorador de archivos o copiar la ruta del archivo actual
local function open_file_manager(dir_path, file_path)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows nativo
    local windows_path = file_path:gsub("/", "\\")
    os.execute('explorer /select,"' .. windows_path .. '"')
  elseif vim.fn.has("wsl") == 1 then
    -- WSL: Abrir Windows Explorer
    local windows_path = vim.fn.system("wslpath -w " .. vim.fn.shellescape(file_path)):gsub("\n", "")
    vim.fn.jobstart({ "explorer.exe", "/select,", windows_path }, { detach = true })
  elseif vim.fn.has("unix") == 1 then
    -- Linux nativo (no WSL)
    if vim.fn.executable("nautilus") == 1 then
      local command = string.format(
        "dbus-send --session --print-reply --dest=org.freedesktop.FileManager1 "
          .. "/org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems "
          .. 'array:string:"file://%s" string:""',
        file_path
      )
      os.execute(command .. " >/dev/null 2>&1 &")
    elseif vim.fn.executable("dolphin") == 1 then
      vim.fn.jobstart({ "dolphin", "--select", file_path }, { detach = true })
    elseif vim.fn.executable("thunar") == 1 then
      vim.fn.jobstart({ "thunar", dir_path }, { detach = true })
    elseif vim.fn.executable("nemo") == 1 then
      vim.fn.jobstart({ "nemo", file_path }, { detach = true })
    else
      vim.notify("❌ No se encontró gestor de archivos. Instala nautilus/dolphin/thunar", vim.log.levels.ERROR)
    end
  elseif vim.fn.has("mac") == 1 then
    -- macOS
    vim.fn.jobstart({ "open", "-R", file_path }, { detach = true })
  end
end

-- El resto del código permanece igual
local function copy_file_path()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    vim.notify("No hay un archivo activo", vim.log.levels.WARN)
    return
  end

  -- Obtener información del archivo
  local absolute_path = vim.fn.expand("%:p")
  local relative_path = vim.fn.expand("%")
  local filename = vim.fn.expand("%:t")
  local dir_path = vim.fn.fnamemodify(absolute_path, ":h")

  -- Verificar si el archivo existe en el disco
  local file_exists = vim.fn.filereadable(absolute_path) == 1

  -- Opciones de copiado
  local options = {
    "📋 Ruta absoluta: " .. absolute_path,
    "📁 Ruta relativa: " .. relative_path,
    "📄 Nombre del archivo: " .. filename,
  }

  -- Solo mostrar la opción de abrir en el explorador si el archivo existe
  if file_exists then
    table.insert(options, "🚀 Abrir en el explorador de archivos")
  end

  -- Mostrar selector de opciones
  vim.ui.select(options, {
    prompt = "Selecciona qué acción realizar:",
  }, function(choice, idx)
    if not choice then
      return
    end

    if choice:find("explorador") then
      -- Abrir en el explorador de archivos
      open_file_manager(dir_path, absolute_path)
      vim.notify("Explorador abierto: " .. filename, vim.log.levels.INFO)
    else
      -- Copiar al portapapeles
      local text_to_copy = choice:gsub("^[^:]+: ", "")
      vim.fn.setreg("+", text_to_copy)
      vim.fn.setreg('"', text_to_copy)
      vim.notify("Copiado: " .. text_to_copy, vim.log.levels.INFO)
    end
  end)
end

-- Mapeo para Ctrl+Alt+R (como VSCode)
vim.keymap.set("n", "<C-A-r>", copy_file_path, { desc = "🔎Copiar ruta del archivo (VSCode style)" })
-- Opción A: <leader>r (Ruta)
vim.keymap.set("n", "<leader>r", copy_file_path, { desc = "🔎Copiar ruta del archivo (VSCode style)" })

-- Comando personalizado
vim.api.nvim_create_user_command("CopyPath", copy_file_path, {})

-- =============================
-- ABRIR, ADD TAB (Ctrl+T)
-- =============================

-- Mapear Ctrl+T y Space+A+N para {add new file} abrir una nueva pestaña - lo mismo que space + m + n

-- Crear nuevo archivo desde treesitter - arbol de archivo - lo mismo que Control + Ts
vim.keymap.set("n", "<leader>an", function()
  local dir = vim.fn.expand("%:p:h") -- ruta del buffer actual
  if dir == "" then
    dir = vim.loop.cwd() -- fallback si no hay archivo
  end
  local name = vim.fn.input("Nombre del archivo: ")
  if name ~= "" then
    vim.cmd("tabnew " .. dir .. "/" .. name)
  end
end, { noremap = true, silent = true, desc = "  Nuevo archivo [add new file]" })

-- keymap.set("n", "<C-t>", ":tabnew<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-t>", function()
  local dir = vim.fn.expand("%:p:h") -- ruta del buffer actual
  if dir == "" then
    dir = vim.loop.cwd() -- fallback si no hay archivo
  end
  local name = vim.fn.input("Nombre del archivo: ")
  if name ~= "" then
    -- abre un buffer normal en la carpeta actual con el nombre indicado
    vim.cmd("tabnew " .. dir .. "/" .. name)
  end
end, { noremap = true, silent = true })

-- =============================
-- BUFFERS VISUALES (PowerToys Compatible)
-- BUFFERS VISUALES (Alt + Número)
-- =============================
-- Cambiar a pestaña anterior con [b
if is_wsl or is_windows then
  keymap.set("n", "<C-P>", ":bprev<CR>", { noremap = true, silent = true })
else
  keymap.set("n", "<C-[>", ":bprev<CR>", { noremap = true, silent = true })
end
-- Cambiar a pestaña siguiente con ]b
keymap.set("n", "<C-]>", ":bnext<CR>", { noremap = true, silent = true })

-- Navegación de Buffers al estilo VSCode / Navegador
vim.keymap.set("n", "<C-PageUp>", ":bprev<CR>", { noremap = true, silent = true, desc = "Buffer anterior" })
vim.keymap.set("n", "<C-PageDown>", ":bnext<CR>", { noremap = true, silent = true, desc = "Siguiente buffer" })
-- En WSL con PowerToys, usar F1-F10 (mapeados desde Alt+1-9)
-- En Linux nativo, usar Alt+1-9 directamente
if is_wsl or is_windows then
  -- PowerToys KeyboardManager mapea Alt+1 → F1, etc.
  vim.keymap.set("n", "<F1>", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Buffer 1" })
  vim.keymap.set("n", "<F2>", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Buffer 2" })
  vim.keymap.set("n", "<F3>", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Buffer 3" })
  vim.keymap.set("n", "<F4>", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Buffer 4" })
  vim.keymap.set("n", "<F5>", "<cmd>BufferLineGoToBuffer 5<CR>", { desc = "Buffer 5" })
  vim.keymap.set("n", "<F6>", "<cmd>BufferLineGoToBuffer 6<CR>", { desc = "Buffer 6" })
  vim.keymap.set("n", "<F7>", "<cmd>BufferLineGoToBuffer 7<CR>", { desc = "Buffer 7" })
  vim.keymap.set("n", "<F8>", "<cmd>BufferLineGoToBuffer 8<CR>", { desc = "Buffer 8" })
  vim.keymap.set("n", "<F9>", "<cmd>BufferLineGoToBuffer 9<CR>", { desc = "Buffer 9" })
  vim.keymap.set("n", "<F10>", "<cmd>BufferLineGoToBuffer -1<CR>", { desc = "Último Buffer" }) -- Activar backspace+Control - MODO INSERCION COMO EN VSCODE!!! = Ctrl W
else
  -- Linux nativo: Alt+1-9 funciona perfectamente
  vim.keymap.set("n", "<A-1>", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Buffer 1" })
  vim.keymap.set("n", "<A-2>", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Buffer 2" })
  vim.keymap.set("n", "<A-3>", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Buffer 3" })
  vim.keymap.set("n", "<A-4>", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Buffer 4" })
  vim.keymap.set("n", "<A-5>", "<cmd>BufferLineGoToBuffer 5<CR>", { desc = "Buffer 5" })
  vim.keymap.set("n", "<A-6>", "<cmd>BufferLineGoToBuffer 6<CR>", { desc = "Buffer 6" })
  vim.keymap.set("n", "<A-7>", "<cmd>BufferLineGoToBuffer 7<CR>", { desc = "Buffer 7" })
  vim.keymap.set("n", "<A-8>", "<cmd>BufferLineGoToBuffer 8<CR>", { desc = "Buffer 8" })
  vim.keymap.set("n", "<A-9>", "<cmd>BufferLineGoToBuffer 9<CR>", { desc = "Buffer 9" })
  vim.keymap.set("n", "<A-0>", "<cmd>BufferLineGoToBuffer -1<CR>", { desc = "Último Buffer" }) -- Activar backspace+Control - MODO INSERCION COMO EN VSCODE!!! = Ctrl W
end

-- =============================
-- FIX DEL CONTROL Backspace
-- =============================

-- Activar backspace+Control - MODO INSERCION COMO EN VSCODE!!! = Ctrl W
vim.api.nvim_set_keymap("i", "<C-H>", "<C-W>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-BS>", "<C-W>", { noremap = true, silent = true })

-- 🚨📌🗿🔥Mapeo para Ctrl + backspace a Ctrl + W en el modo de línea de comandos (la : )🚨📌🗿🔥
-- Mapeo que usa una función para asegurar que funciona en la línea de comandos
if is_wsl or is_windows then
  vim.keymap.set("c", "<C-BS>", function()
    -- Cierra cualquier ventana de completado y luego ejecuta el comando Ctrl-W
    -- El comando \b borra una palabra hacia atrás
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-W>", true, true, true), "n", true)
  end, { noremap = true, silent = true })
else
  vim.keymap.set("c", "<C-H>", function()
    -- Cierra cualquier ventana de completado y luego ejecuta el comando Ctrl-W
    -- El comando \b borra una palabra hacia atrás
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-W>", true, true, true), "n", true)
  end, { noremap = true, silent = true })
end

-- ---------------------------------------------------|-
--👹📌🗿🔥Mismo mapeo pero para el modo de inserción en buffers normales👹📌🗿🔥
-- Función mejorada para borrar palabras en buffers de snacks
local function delete_previous_word()
  -- Obtener posición actual
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]
  local line = vim.api.nvim_get_current_line()

  -- Encontrar el inicio de la palabra anterior
  local word_start = col
  while word_start > 0 and line:sub(word_start, word_start):match("%s") do
    word_start = word_start - 1
  end

  while word_start > 0 and not line:sub(word_start, word_start):match("%s") do
    word_start = word_start - 1
  end

  -- Ajustar índices (Lua es 1-indexed, Neovim API es 0-indexed)
  word_start = word_start + 1

  -- Borrar la palabra
  if word_start <= col then
    vim.api.nvim_buf_set_text(0, row - 1, word_start - 1, row - 1, col, { "" })
    vim.api.nvim_win_set_cursor(0, { row, word_start - 1 })
  end
end

-- Aplicar a TODOS los tipos de buffers de snacks
local snack_filetypes = {
  "snacks_picker_input",
  "snacks_picker_list",
  "snacks_picker_recent",
  "snacks_picker_files",
  "snacks_picker_smart",
}

for _, ft in ipairs(snack_filetypes) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      -- Habilitar modifiable temporalmente
      vim.bo.modifiable = true

      -- Mapear Ctrl+Backspace y Ctrl+H
      vim.keymap.set("i", "<C-BS>", delete_previous_word, {
        buffer = true,
        noremap = true,
        silent = true,
        desc = "Borrar palabra anterior",
      })

      vim.keymap.set("i", "<C-H>", delete_previous_word, {
        buffer = true,
        noremap = true,
        silent = true,
        desc = "Borrar palabra anterior",
      })
    end,
  })
end

-- =============================
-- CERRAR BUFFERS, VENTANAS
-- =============================

--🛑 🗿 Cerrar pestaña

keymap.set("n", "<C-q>", function()
  -- Cierra el buffer actual sin preguntar, forzando el cierre
  -- para cerrar ventanas molestas usa: :q! o :q
  vim.cmd("bdelete!")
end, { noremap = true, silent = true })

-- # MUCHOS DE ESTOS COMANDOS EQUIVALEN A:
--  [ + b > cambiar pestaña prev {osea tabear}
--  ] + b > cambiar pestaña next {osea tabear}
--  space + b + b = la unica forma de ctrl tab
--
--    |
-- 	  ╰─❯ CTrl + [] > cabra a buffer prev!!
--        [lomejor] Ctrl + ] > cambiar a buffer sigueinte [ctrl tab!! en buffer]

-- # y otros que NO MODIFIQUE COMO:
-- Ctrl + V > Grabar Tecla - Util para averiguar la tecla [Record key] {Similar a cat -v}
-- Ctrl + Shif + C > Copiar en Modo Insercion
-- Ctrl + Shif + V > Pegar en Modo Insercion
-- ╰❯ [Ctrl + W > Guia de Window]
-- 	╰─❯ {recomiendo}
-- 	  ╰─❯ Ctrl + W + W > cambiar ventana {osea tabear}
-- 	  ╰─❯  Ctrl + W + J > Cambiar ventana {abajo}
-- 	  ╰─❯  Ctrl + W + H > Cambiar ventana {izquierda,
-- 	  ╰─❯  Ctrl + Space [lo mejor] > Cambiar entre TODAS las ventana [shift tab!!! en ventana],
--
--    |
-- 	  ╰─❯  Ctrl + H [lo mejor] > Cambiar entre ventana [ctrl tab!!! en ventana],

--     Ctrl + W + O > cierra tod@s las ventanas divididas/o Explorer
--   	Ctrl + W + > S > split dividir {mas lento que space}

-- Mapea la tecla 'p' en modo visual para pegar sin copiar lo que reemplazas!!!
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true })

-- Cambiar de tema con Telescope colorscheme = Space + C + T                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/colorscheme.lua
-- Cambiar a Pywal color de fondo = Space + P                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/pywal-nvim.lua
-- Cambiar a Pywal color de fondo = Space + P+W                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/pywal-nvim.lua
-- Cambiar a Pywal color de fondo = Soace + C + T escribe Pywal, gruv o el tema que gustes.                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/colorscheme.lua

-- 🧺   ELIMINE LOS SIGUIENTES plugins (~ [basura]/):⚠
-- Usar minty para generar colorschemes? idk activa Huefy = Space + M + H                   # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau
-- Usar minty para generar colorschemes? idk activa Shades = Space + M + S                  # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau
-- Usar minty para generar colorschemes? idk = Space + M + H                  # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau

-- CAMBIAR color con Teclado = C+P                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins.lua
-- CAMBIAR color con Mouse + C+V                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/color-picker.lua
-- ABRIR KEYMAPS *otra forma con* = Space + S + K
-- ABRIR EL DASHBOARD:
vim.keymap.set("n", "<leader>dd", function()
  require("snacks").dashboard.open()
end, { desc = "Abrir dashboard de Snacks" })

-- ==================================================================
-- [⚠ BETA⚠!] KEYMAPS OLLAMA AI (LOCAL) 󰎣 🦙🤖🔥️ NO REQUIERE INTERNET
-- ==================================================================
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

local function open_ollama(prompt, input_text, use_nothink)
  local cmd_exec = get_ollama_cmd()
  if not cmd_exec then
    vim.notify("❌ Ollama no encontrado. Asegúrate de tenerlo instalado y en tu PATH.", vim.log.levels.ERROR)
    return
  end

  local model = vim.g.ollama_model
  vim.cmd("vsplit | vertical resize 50")

  -- Si usamos WSL wrapper, necesitamos quotear el comando completo
  local full_cmd
  if cmd_exec:match("^wsl.*-lic$") then
    full_cmd = cmd_exec .. " 'ollama run " .. model .. "'"
  else
    full_cmd = cmd_exec .. " run " .. model
  end

  vim.cmd("term " .. full_cmd)

  local final_prompt = ""

  -- 🔥 AGREGAR /set nothink SI SE SOLICITA
  if use_nothink then
    final_prompt = "/set nothink\n"
  end

  if input_text and input_text ~= "" then
    final_prompt = prompt .. "\n\nAnaliza este código:\n" .. input_text
  end

  vim.defer_fn(function()
    if vim.b.terminal_job_id then
      vim.api.nvim_chan_send(vim.b.terminal_job_id, final_prompt .. "\n")
    end
  end, 800)

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
    "# 📝 MODELFILE DE: " .. model,
    "# ",
    "# 🔧 EDITA ESTE ARCHIVO Y GUARDA CON :w",
    "# ⚡ APLICA CAMBIOS: :OllamaApply  Esto descarga el modelo custom",
    "# ",
    "# 󰧑 🔧¿Como desactivar NOTHINK? ",

    "# ",
    " Solución 1: Usa /set nothink en CLI (Más Simple), Ej:",
    "# ollama run deepseek-v3.1:671b-cloud",
    "# >>> /set nothink",
    "# >>> Tu pregunta aqui.",

    " Solución 2: Usar el archivo de modelfile (Más Complejo), Ej:",
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
  end, { desc = " 󰎣 Crear modelo personalizado desde este Modelfile" })

  vim.notify("📝 Edita el Modelfile. Aplica con :OllamaApply", vim.log.levels.INFO)
end

local function show_ollama_menu(selected_text)
  local current_model = vim.g.ollama_model or "deepseek-r1"
  local options = {
    "🔍 [Local] Revisar código",
    "📚 [Local] Explicar código",
    "🐛 [Local] Debuggear error",
    "♻️ [Local] Refactorizar",
    "⚡ [Local] Optimizar",
    "💬 [Local] Chat Libre",
    "📄 [Local] Ver/Editar Modelfile (" .. current_model .. ")",
    "📋 [Local] Listar modelos instalados",
    "⚙️ [Local] Cambiar modelo (" .. current_model .. ")",
    "💬 [Local] Logearte con Ollama + API para usar CLOUD",
  }

  vim.ui.select(options, {
    prompt = " 󰎣 ⭕ ~ Ollama (" .. current_model .. "):",
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

-- Mapeos
vim.keymap.set("n", "<leader>ao", function()
  show_ollama_menu(nil)
end, { desc = " 󰎣 🅾️ 🦙 Abrir Ollama" })

vim.keymap.set("v", "<leader>ao", function()
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  show_ollama_menu(selected_text)
end, { desc = " 󰎣 🅾️ 🦙 Enviar selección a Ollama" })

-- Comandos
vim.api.nvim_create_user_command("OllamaModel", function()
  vim.notify(" 󰎣 🅾️ 🦙 Modelo actual: " .. vim.g.ollama_model, vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("OllamaList", function()
  show_ollama_list()
end, {})

-- Mapeos directos
vim.keymap.set("n", "<leader>am", function()
  show_ollama_modelfile()
end, { desc = " 󰎣 🅾️ 🦙 Ver/Editar Modelfile" })

vim.keymap.set("n", "<leader>al", function()
  show_ollama_list()
end, { desc = " 󰎣 🅾️ 🦙 Listar modelos" })

-- Switch / Cambiar Modelo ~ <leader>as
vim.keymap.set("n", "<leader>as", function()
  local current_model = vim.g.ollama_model or "deepseek-r1"
  vim.ui.input({
    prompt = " 󰎣 🅾️ 🦙 Nuevo modelo (actual: " .. current_model .. "): ",
    default = current_model,
  }, function(input)
    if input and input ~= "" then
      vim.g.ollama_model = input
      save_ollama_model(input)
      vim.notify("✅ Modelo guardado: " .. input, vim.log.levels.INFO)
    end
  end)
end, { desc = " 󰎣 🅾️ 🦙 Switch/Cambiar modelo de Ollama rápido" })

-- ===================================================================================
-- Utilidades para Claude v2.1.6] ~ [by dizzi1222] - Yanked proyecto, copiar Proyecto
-- ===================================================================================
-- Función helper para obtener información del repositorio Git
local function get_repo_context()
  local cwd = vim.fn.getcwd()
  local git_root = vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel 2>/dev/null")

  if vim.v.shell_error == 0 then
    git_root = git_root:gsub("\n", "")
    local repo_name = vim.fn.fnamemodify(git_root, ":t")
    local branch = vim.fn
      .system("git -C " .. vim.fn.shellescape(git_root) .. " rev-parse --abbrev-ref HEAD 2>/dev/null")
      :gsub("\n", "")

    return {
      is_git = true,
      root = git_root,
      name = repo_name,
      branch = branch,
      relative_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:."),
    }
  end

  return {
    is_git = false,
    root = cwd,
    name = vim.fn.fnamemodify(cwd, ":t"),
    relative_path = vim.fn.expand("%:t"),
  }
end

-- Función para construir contexto rico para Claude
local function build_claude_context(selected_text, custom_instruction)
  local repo = get_repo_context()
  local file_path = vim.fn.expand("%:p")
  local file_type = vim.bo.filetype
  local line_num = vim.fn.line(".")

  -- Convertir ruta de WSL a Windows si es necesario
  local display_path = file_path
  if vim.fn.has("wsl") == 1 then
    display_path = vim.fn.system("wslpath -w " .. vim.fn.shellescape(file_path)):gsub("\n", "")
  end

  local context = "📁 Proyecto: " .. repo.name .. "\n"

  if repo.is_git then
    context = context .. "🌿 Branch: " .. repo.branch .. "\n"
  end

  context = context .. "📄 Archivo: " .. repo.relative_path .. "\n"
  context = context .. "🔤 Tipo: " .. (file_type ~= "" and file_type or "text") .. "\n"
  context = context .. "📍 Línea: " .. line_num .. "\n"
  context = context .. "💻 Sistema: " .. (vim.fn.has("wsl") == 1 and "WSL" or vim.loop.os_uname().sysname) .. "\n\n"

  if custom_instruction then
    context = context .. "📝 Instrucción: " .. custom_instruction .. "\n\n"
  end

  if selected_text and selected_text ~= "" then
    context = context .. "```" .. file_type .. "\n" .. selected_text .. "\n```\n"
  end

  return context
end
-- =============================
-- KEYMAPS PARA CLAUDE AI
-- =============================
-- Atajo rápido: Copiar TODO el contexto actual al portapapeles
vim.keymap.set("n", "<leader>ay", function()
  local repo = get_repo_context()
  local full_file = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local context = build_claude_context(full_file, "Aquí está el archivo completo:")

  vim.fn.setreg("+", context)
  vim.notify("📋 Archivo completo + contexto copiado\n📁 " .. repo.name, vim.log.levels.INFO)
end, { desc = "  📋 Copiar archivo completo con contexto" })

-- Atajo ultra-rápido: Solo copiar código seleccionado (sin abrir navegador)
vim.keymap.set("v", "<leader>ay", function()
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  local context = build_claude_context(selected_text, nil)

  vim.fn.setreg("+", context)
  vim.notify("✅ Código + contexto copiado al portapapeles", vim.log.levels.INFO)
end, { desc = "  📋 Copiar selección con contexto (sin abrir)" })

-- Comando para ver información del repositorio actual
vim.api.nvim_create_user_command("ClaudeInfo", function()
  local repo = get_repo_context()
  local info = "📊 INFORMACIÓN DEL PROYECTO\n\n"
  info = info .. "📁 Nombre: " .. repo.name .. "\n"
  info = info .. "📂 Root: " .. repo.root .. "\n"

  if repo.is_git then
    info = info .. "🌿 Branch: " .. repo.branch .. "\n"
    info = info .. "✅ Git: Sí\n"
  else
    info = info .. "❌ Git: No\n"
  end

  info = info .. "📄 Archivo: " .. repo.relative_path .. "\n"
  info = info .. "💻 Sistema: " .. (vim.fn.has("wsl") == 1 and "WSL" or vim.loop.os_uname().sysname)

  vim.notify(info, vim.log.levels.INFO)
end, { desc = "Ver info del proyecto para Claude" })

-- =============================
-- KEYMAPS GEMINI AI 🐐🗣️🔥️✍️ NO REQUIERE API
-- =============================
-- Aqui veras:
-- Gemini-cli que abre al lado en vertical [Gemini > Copilot, ofrece mas prompts GRATIS]
-- Funcion que selecciona y copia el texto para enviarlo a Gemini
-- Mapeo para salir del terminal con ESC
-- La función open_gemini modificada para usar comillas dobles
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

local function open_gemini(prompt, input_text)
  local root = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  vim.cmd("vsplit | vertical resize 50")
  local cmd = 'gemini --prompt-interactive "' .. prompt .. '" --include-directories "' .. root .. '"'
  vim.cmd("term " .. cmd)
  if input_text and input_text ~= "" then
    vim.defer_fn(function()
      vim.api.nvim_chan_send(vim.b.terminal_job_id, input_text .. "\n")
    end, 500)
  end
  vim.cmd("startinsert")
end

local function show_gemini_menu(selected_text)
  local options = {
    "🔍 Revisar código",
    "📚 Explicar código",
    "🐛 Debuggear error",
    "♻️ Refactorizar",
    "⚡ Optimizar",
    "💬 Personalizado [Abrir gemini]",
  }

  vim.ui.select(options, {
    prompt = " 󰊭 ~ Selecciona acción:",
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
      "", -- Personalizado
    }

    if idx == 6 then -- Opción personalizada
      vim.ui.input({
        prompt = "Tu prompt: ",
      }, function(input)
        if input and input ~= "" then
          open_gemini(input, selected_text)
        end
      end)
    else
      open_gemini(prompts[idx], selected_text)
    end
  end)
end

-- Mapeo para modo normal
keymap.set("n", "<leader>ag", function()
  show_gemini_menu(nil)
end, {
  desc = " 󰊭 ~ Abrir Gemini con menú",
})

-- Mapeo para modo visual
keymap.set("v", "<leader>ag", function()
  -- Copiar texto seleccionado al portapapeles del sistema
  vim.cmd('normal! "+y')
  local selected_text = vim.fn.getreg('"')
  show_gemini_menu(selected_text)
end, {
  desc = " 󰊭 ~ Enviar selección a Gemini",
})
-- Mapeos para el plugin de Geminia.lua gentleman (si está instalado) ~[💸💳💰REQUIERE API:]
local has_gemini, gemini_chat = pcall(require, "gemini.chat")
if has_gemini then
  keymap.set("n", "<leader>gg", function()
    gemini_chat.prompt_current()
  end, { desc = " 󰊭 Gemini: prompt en buffer actual" })

  keymap.set("v", "<leader>g", function()
    gemini_chat.prompt_selected()
  end, { desc = " 󰊭 Gemini: prompt con texto seleccionado" })

  keymap.set("n", "<leader>gl", function()
    gemini_chat.prompt_line()
  end, { desc = " 󰊭 Gemini: prompt con línea actual" })
end

-- =============================
-- -- Solo en Arhcivos.MD | MARKDown (Gentleman config) - {no funciona bien}
-- =============================
-- KEYMAPS CORRECTOS:
keymap.set("n", "<leader>mr", function()
  require("render-markdown").toggle()
end, { desc = "Toggle Markdown Render" })

keymap.set("n", "<leader>me", function()
  require("render-markdown").enable()
end, { desc = "Enable Markdown Render" })

keymap.set("n", "<leader>md", function()
  require("render-markdown").disable()
end, { desc = "Disable Markdown Render" })

-- =============================
-- INSERT MODE (Gentleman config)
-- =============================
keymap.set("i", "<C-b>", "<C-o>de") -- Ctrl+b: borrar hasta fin de palabra
keymap.set("i", "<C-c>", [[<C-\><C-n>]]) -- Ctrl+c escape
vim.api.nvim_set_keymap("i", "<A-j>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-k>", "<Nop>", { noremap = true, silent = true })

-- =============================
-- NORMAL MODE (Gentleman config)
-- =============================
keymap.set("n", "<C-s>", ":lua SaveFile()<CR>") -- guardar con función

-- =============================
-- VISUAL MODE (Gentleman config)
-- =============================
keymap.set("v", "<C-c>", [[<C-\><C-n>]]) -- escape
vim.api.nvim_set_keymap("x", "<A-j>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "<A-k>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "J", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "K", "<Nop>", { noremap = true, silent = true })

-- =============================
-- LEADER KEYS (Gentleman config)
-- =============================
keymap.set("n", "<leader>uk", "<cmd>Screenkey<CR>")
keymap.set("n", "<leader>bq", '<Esc>:%bdelete|edit #|normal`"<CR>', { desc = "Delete other buffers" })
keymap.set("n", "<leader>md", function()
  vim.cmd("delmarks!")
  vim.cmd("delmarks A-Z0-9")
  vim.notify("All marks deleted")
end, { desc = "Delete all marks" })

-- =============================
-- TMUX NAVIGATION (Gentleman config)
-- =============================
-- Línea 364 aprox en keymaps.lua
if not is_vscode and not is_windows then
  local ok, nvim_tmux_nav = pcall(require, "nvim-tmux-navigation")
  if ok then
    -- Setup del plugin
    nvim_tmux_nav.setup({
      disable_when_zoomed = true,
    })

    -- Mapeos de navegación
    keymap.set("n", "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
    keymap.set("n", "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
    keymap.set("n", "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
    keymap.set("n", "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
    keymap.set("n", "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
    keymap.set("n", "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
  end
end

-- =============================
-- OBSIDIAN (Gentleman config)
-- =============================
keymap.set("n", "<leader>oc", "<cmd>ObsidianCheck<CR>")
keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>")
keymap.set("n", "<leader>oo", "<cmd>Obsidian Open<CR>")
keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>")
keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>")
keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>")
keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>")
keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>")

-- =============================
-- OIL (Gentleman config)
-- =============================
keymap.set("n", "-", "<CMD>Oil<CR>")

-- =============================
-- FUNCIONES (Gentleman config)
-- =============================
function SaveFile()
  if vim.fn.empty(vim.fn.expand("%:t")) == 1 then
    vim.notify("No file to save", vim.log.levels.WARN)
    return
  end
  local filename = vim.fn.expand("%:t")
  local ok, err = pcall(function()
    vim.cmd("silent! write")
  end)
  if ok then
    vim.notify(filename .. " Saved!")
  else
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end

-- =============================
-- KEYMAPS GENTLEMAN / CLAUDE (SEPARADO) \ AL SELECCIONAR TEXTO [v]
-- =============================
local has_claude, claude = pcall(require, "claude-code")
if has_claude then
  -- Visual: completar selección con Claude
  vim.keymap.set("v", "<leader>ac", function()
    claude.complete_selection()
  end, { desc = "  Claude: completar selección" })

  -- Normal: abrir panel de Claude
  vim.keymap.set("n", "<leader>aa", function()
    claude.open_panel()
  end, { desc = "  Claude: abrir panel" })

  -- Optional: enviar línea actual a Claude y obtener respuesta
  vim.keymap.set("n", "<leader>al", function()
    claude.complete_line()
  end, { desc = "  Claude: completar línea actual" })

  -- Optional: cerrar panel de Claude
  vim.keymap.set("n", "<leader>ax", function()
    claude.close_panel()
  end, { desc = "  Claude: cerrar panel" })
end

-- =============================
-- LIVE SERVER, deploy, DOCKER 
-- =============================

-- Launch live-server [Space + L + ?] {Equivalente a Ctrl+O en VSCODE}
-- Para proyectos / HTML estaticos
keymap.set("n", "<leader>ll", ":cd %:h | term live-server<CR>", { desc = "Launch Live Server [Html Estatico]" })

-- Para proyectos de React
vim.keymap.set("n", "<leader>ls", ":cd %:p:h | term npm start<CR>", { desc = "React Start" })

-- Para DEPURAR Proyectos de Producción
vim.keymap.set("n", "<leader>lb", ":cd %:p:h | term npm run build<CR>", { desc = "Run Build / Depurar" })

-- Para SERVIR Proyectos de Producción
vim.keymap.set("n", "<leader>lv", ":cd %:p:h | term npm run serve<CR>", { desc = "Run Serve / Depurar" })

-- Para deployar proyectos
vim.keymap.set("n", "<leader>ld", ":cd %:p:h | term npm run deploy<CR>", { desc = "Run Deploy" })

-- Launch live-server [Space + L + S] {Equivalente a Ctrl+O en VSCODE}
keymap.set("n", "<leader>ls", function()
  -- Verificar si live-server está instalado
  if vim.fn.executable("live-server") == 0 then
    vim.notify("❌ live-server no está instalado. Instala con: npm i -g live-server", vim.log.levels.ERROR)
    return
  end
  vim.cmd("cd %:h | term live-server")
end, { desc = "Launch Live Server" })

-- Docker Compose Up [Space + L + D]
keymap.set("n", "<leader>ld", function()
  -- Detectar si está en WSL
  local is_wsl = vim.fn.has("wsl") == 1
  local docker_cmd = is_wsl and "docker.exe" or "docker"

  if vim.fn.executable(docker_cmd) == 0 then
    vim.notify("❌ Docker no está instalado", vim.log.levels.ERROR)
    return
  end
  vim.cmd("cd %:h | term " .. docker_cmd .. " compose up")
end, { desc = "Docker Compose Up" })

-- =============================
-- MOVIMIENTO, REIDENTADO
-- =============================

-- Movimiento de líneas con reindentado automático
-- O Instala: "ziontee113/move.nvim"

local function move_line(direction)
  local line = vim.fn.line(".")
  if direction == "up" and line > 1 then
    vim.cmd("m .-2")
  elseif direction == "down" and line < vim.fn.line("$") then
    vim.cmd("m .+1")
  end
  vim.cmd("normal! ==")
end

vim.keymap.set("n", "<A-Up>", function()
  move_line("up")
end, { desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", function()
  move_line("down")
end, { desc = "Move line down" })

-- =============================
-- TABEAR ENTRE VENTANAS (TMUX) 
-- =============================

-- FORZAR Ctrl+Space para TABEAR -- ✅ CORRECTO - Fíjate en los cierres
-- Configuración de navegación TMUX con Ctrl+Space
vim.defer_fn(function()
  -- Mapear Ctrl+Space para navegación en modo normal, visual e insert
  local modes = { "n", "v", "i" }
  for _, mode in ipairs(modes) do
    vim.keymap.set(mode, "<C-Space>", function()
      require("nvim-tmux-navigation").NvimTmuxNavigateNext()
    end, {
      noremap = true,
      silent = true,
      desc = "TMUX Navigate Next",
    })
  end
end, 100)

-- Configuración de navegación TMUX con Ctrl+H
vim.defer_fn(function()
  -- Mapear Ctrl+H para navegación en modo normal, visual e insert
  local modes = { "n", "v", "i" }
  for _, mode in ipairs(modes) do
    vim.keymap.set(mode, "<C-h>", function()
      require("nvim-tmux-navigation").NvimTmuxNavigateLastActive()
    end, {
      noremap = true,
      silent = true,
      desc = "TMUX Navigate Back",
    })
  end
end, 110) -- FORZAR Ctrl+Space para TABEAR -- ✅ CORRECTO - Fíjate en los cierres

-- =============================
-- OCULTAR/MOSTRAR BUFFERS
-- =============================

-- Ocultar buffer actual (sin cerrarlo)
keymap.set("n", "<leader>bh", ":hide<CR>", {
  desc = "Ocultar buffer (mantener en memoria)",
})

-- Mostrar lista de buffers ocultos
keymap.set("n", "<leader>ba", ":ls!<CR>", {
  desc = "All - Listar todos los buffers (incluyendo ocultos)",
})

-- Cambiar a buffer específico (incluso si está oculto)
keymap.set("n", "<leader>bz", ":buffers<CR>:buffer<Space>", {
  desc = "Zxy - Cambiar a buffer por número",
})

-- Cerrar buffer ACTUAL pero mantener ventana (usando enew)
keymap.set("n", "<leader>bc", ":enew | bdelete #<CR>", {
  desc = "Cerrar buffer pero mantener ventana",
})

-- Para dividir la pantalla/buffers:
-- <space>+| > Split horizontal
-- <space>+--  > Split vertical
-- <space>+bh > Revertir DIVISION
-- <space>+wm > Maximizar ventana [FULLSCREEN]
-- Ctrl+<,>,up,down > POSICIONAR VENTANA
-- Ctrl+W > Acceder a modo ventanas
-- Ctrl+h,k,l,j > Navegación entre ventanas
--
