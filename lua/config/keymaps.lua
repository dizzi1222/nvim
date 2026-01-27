-- Extract from: keymaps.lua
-- Resumen pochenkro en: ../../docs/neovim-keymaps.md    

-- Al inicio de keymaps.lua
-- Detectar plataforma
local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

vim.g.mapleader = " "

local keymap = vim.keymap

-- keymap.set("i", "jj", "<ESC>") -- salir del modo insercion con jj
keymap.set("n", "<ESC>", ":noh<CR>")
vim.keymap.set("v", "<A-S-f>", vim.lsp.buf.format)

-- Mapea la tecla 'p' en modo visual para pegar sin copiar lo que reemplazas!!!
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true })

-- ABRIR EL DASHBOARD:
vim.keymap.set("n", "<leader>dd", function()
  require("snacks").dashboard.open()
end, { desc = "Abrir dashboard de Snacks" })

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
-- -- Solo en Arhcivos.MD | MARKDown (Gentleman config) - {no funciona bien}
-- =============================
keymap.set("n", "<leader>mr", function()
  require("render-markdown").toggle()
  local state = require("render-markdown.state")
  if state.enabled then
    vim.notify("Render Markdown: ON", vim.log.levels.INFO)
  else
    vim.notify("Render Markdown: OFF", vim.log.levels.INFO)
  end
end, { desc = "Toggle Markdown Render" })

keymap.set("n", "<leader>me", function()
  require("render-markdown").enable()
  vim.notify("✅ Render Markdown: ENABLED", vim.log.levels.INFO)
end, { desc = "Enable Markdown Render" })

keymap.set("n", "<leader>md", function()
  require("render-markdown").disable()
  vim.notify("🚫 Render Markdown: DISABLED", vim.log.levels.INFO)
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
    vim.keymap.set("n", "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext) -- Navigate to the next pane
  end
end

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
  local modes = { "n", "v", "i", "t" }
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
-- NOICE CMDLINE PERSONALIZADA
-- =============================
vim.keymap.set("n", "<leader>nd", "<cmd>NoiceDismiss<CR>", { desc = "Dismiss Noice" }) -- Para borrar notis si se BUGEA
vim.keymap.set("n", "<leader>M", "<cmd>MCP<CR>", { desc = "  MCP HUB" }) -- Para GESTIONAR MCPHUB
