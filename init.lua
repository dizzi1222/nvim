-- ~/.config/nvim/init.lua
-- Separo las FEATURE por N para acciones específicas

-- para que no guarde todo el texto/ moleste con el Space + Q + Q
vim.opt.shada = "!,'100,<50,s10,h" -- Config minimalista

-- Cambiado a > Help > Desactivar  busqueda por palabras clave
vim.opt.keywordprg = ":help" -- Space+K

-- 👈 anteriormente como init-vscode.lua
if vim.g.scode then
  -- CoPnfiguración específica para VSCode
  vim.g.mapleader = " "
  vim.opt.clipboard = "unnamedplus"
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Mapeos básicos
  -- causa conflicto en WINDOWS:
  -- vim.keymap.set({ "n", "v" }, "j", "h")
  -- vim.keymap.set({ "n", "v" }, "k", "j")
  -- vim.keymap.set({ "n", "v" }, "l", "k")
  -- vim.keymap.set({ "n", "v" }, ";", "l")
  vim.keymap.set("n", "'", ";")
  vim.keymap.set("v", "p", "P")
  vim.keymap.set("n", "U", "<C-r>")
  vim.keymap.set("n", "<Esc>", ":nohlsearch<cr>")
  vim.keymap.set("t", "<Esc>", ":nohlsearch<cr>")
  -- causa conflicto en WINDOWS:
  -- vim.cmd("nmap k gj")
  -- vim.cmd("nmap l gk")
  vim.cmd("nmap <leader>s :w<cr>")
  vim.cmd("nmap <leader>co :e ~/.config/nvim/init.lua<cr>")

  -- Luego cargar lazy
  require("config.lazy")

  -- Carga de Lazy.nvim (solo plugins compatibles con VSCode)
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  require("lazy").setup({
    { "mini.pairs" },
    { "mini.ai" },
    { "smear-cursor.nvim" },
    { "nvim-treesitter", enabled = false },
  })

  -- Mapeos específicos de VSCode
  local opts = { noremap = true, silent = true }
  local mappings = {
    -- ... tus mapeos de VSCode aquí
  }
  for _, mapping in ipairs(mappings) do
    local mode, key, command = mapping[1], mapping[2], mapping[3]
    vim.keymap.set(mode, key, function()
      vim.fn.VSCodeNotify(command)
    end, opts)
  end

  return -- Termina la ejecución si estamos en VSCode
end

-- ----------------------------------------------------------------------------
-- Configuración para Neovim normal (fuera de VSCode)
-- ----------------------------------------------------------------------------

-- PARA Configurar IAS, revisa:
--
-- config/lazy.lua
-- plugins/disabled
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua
--
-- KEYMAPS DE CHAT por IA FUNCIONAN AL SELECCIONAR TEXTO [v]
--
-- # Primero, arreglar PATH para binarios globales
--  🚨⚠ LO DE ABAJO ME JODE LA CONFIG DE WINDWOS!! Y TENGO PROBLEMA CON NODE POR AHORA: ENTER e ignorar 🚨⚠
--  -- Para linux:
-- vim.env.PATH = os.getenv("HOME") .. "/.npm-global/bin:" .. vim.env.PATH

-- Esto sirve solo en Windows
-- Node.js provider
-- vim.g.node_host_prog = "C:\\Users\\Diego.DESKTOP-0CQHRL5\\AppData\\Roaming\\npm\\node_modules\\neovim\\bin\\cli.js"
-- vim.env.PATH = "C:\\Users\\Diego.DESKTOP-0CQHRL5\\scoop\\apps\\nodejs-lts\\22.18.0;" .. vim.env.PATH

-- 🚨⚠ Detect OS - Funciona en Windows, Linux {en resumen lo de arriba} 🚨⚠
local is_windows = vim.fn.has("win32") == 1
local is_unix = vim.fn.has("unix") == 1

if is_windows then
  -- Configuración Windows
  vim.g.node_host_prog = "C:\\Users\\Diego.DESKTOP-0CQHRL5\\AppData\\Roaming\\npm\\node_modules\\neovim\\bin\\cli.js"
  vim.env.PATH = "C:\\Users\\Diego.DESKTOP-0CQHRL5\\scoop\\apps\\nodejs-lts\\22.18.0;" .. vim.env.PATH
  -- PowerShell config (evita error "unknown element received")
  vim.opt.shell = "pwsh.exe"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
  vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"

  -- Auto-pywal para Windows
  require("utils.Windows-pywal-wiwalAuto").setup() -- Auto-pywal para Windows 
elseif is_unix then
  -- Configuración Linux/macOS
  vim.g.node_host_prog = vim.fn.exepath("node") -- toma el node del PATH
  vim.env.PATH = os.getenv("HOME") .. "/.npm-global/bin:" .. vim.env.PATH
end

-- bootstrap lazy.nvim, LazyVim and your plugins
-- Requieres esenciales
require("config.lazy") --  .
require("config.keymaps") --  .

-- Requiere de Keymaps
require("config.keymaps.ollama-keys") -- keymaps para LocalAI [Ollama] 󰎣 🅾️ .
require("config.keymaps.gemini-keys") -- keymaps para Gemini AI 󰊭 .
-- require("config.keymaps.ai-termux-keys") -- keymaps para TermuxAI .
-- require("config.fittencode-keys") -- Keymaps para Termux AI Autocomplete .
require("config.keymaps.give-context") -- keymaps para utilidades IA  󰭹
require("config.keymaps.close-buffers") -- keymaps para manipular buffers  .
require("config.keymaps.open-explorer") -- keymaps para Abrir Explorer/CopyPaste  .
require("config.keymaps.fix-backspace") -- keymaps para arreglar backspace en terminales 󰌌 .

-- Requires de configuración
require("config.highlights") -- Colores personalizados para sugerencias de IA
require("utils.plugin-switcher") -- Cargador automático de Plugins en disabled.lua  .
require("config.options") --  .
require("config.autocmds") --  .
require("config.nodejs") -- Configuracion de NodeJS para Neovim  .

-- Resumen pochenkro de keymaps: keymapds.md    

-- # PARA HACER FUNCIONAR GENTLEMAN AIS
require("config.nodejs").setup({ silent = true })

-- [MUY OPCIONAL] LSP Progress - NO RECOMIENDO DESACTIVARLO, eso tiene que ver con tu PC y CPU que sea tan lento.. por sobrecargar la config
-- Aparte LSP progress solo se jecuta al modificar cosas de NVIM...
-- vim.lsp.handlers["$/progress"] = function() end -- si quieres desactivar LSP PROGRESS:

-- Configuracion del cursor - smear
local ok, smear = pcall(require, "smear_cursor")
if ok and smear and type(smear.setup) == "function" then
  smear.setup({
    cursor_color = "#49A3EC",
    stiffness = 0.3,
    trailing_stiffness = 0.1,
    trailing_exponent = 1,
    -- hide_target_hack = true, -- esto parpadea el cursor
    gamma = 1,
  })
else
  vim.notify("smear_cursor no disponible (plugin no instalado). Ignorando configuración.", vim.log.levels.WARN)
end
-- [OOKUVA AUTOSAVE ES MUCHO MEJOR UBICADO EN: lua/plugins/auto-save.lua]
-- al finar Empeze a probar otro autosave XD de ookuva
-- por cierto,hay que veces que ookuva se bugea o si sales muy rapido no guardara un carajo

-- [NO USO ESTE AUTOSAVE YA.]
-- Autosave nativo sin plugins,Pero empeze a usar autommands - NO FUNCIONA EN WINDOWS
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", "FocusLost" }, {
--   callback = function()
--     if vim.bo.modified and vim.bo.buftype == "" then
--       vim.cmd("silent write")
--     end
--   end,
-- })
-- bootstrap lazy.nvim, LazyVim and your plugins
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0

-- FEATURE: n1 - 2.0: Auto-sync opencode-nick si faltan módulos
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    -- Solo si opencode-nick está en la configuración
    local lazy = require("lazy")
    local spec = lazy.plugins()["opencode-nick"]

    if spec then
      local data_dir = vim.fn.stdpath("data")
      local opencode_dir = data_dir .. "/lazy/opencode-nick"
      local keymaps_file = opencode_dir .. "/lua/opencode/keymaps.lua"
      local promise_file = opencode_dir .. "/lua/opencode/promise.lua"

      -- Si faltan los módulos críticos, sincroniza desde lazy
      if vim.fn.filereadable(keymaps_file) == 0 or vim.fn.filereadable(promise_file) == 0 then
        vim.notify("opencode-nick: Faltaban módulos. Sincronizando...", vim.log.levels.WARN)
        lazy.sync({ names = { "opencode-nick" } })
      end
    end
  end,
})

-- FEATURE n2 - 3.0: Plugin Switcher (toggle Avante, Copilot, etc)
vim.keymap.set("n", "<leader>aD", function()
  require("utils.plugin-switcher").interactive_toggle()
end, { desc = "🔌 Toggle Plugins (Opencode/Avante/Claude/etc)" })

-- IA n3 - 3.0: Plugin Switcher (toggle Avante, Copilot, etc)
vim.keymap.set("n", "<leader>D", function()
  require("utils.plugin-switcher").interactive_toggle()
end, { desc = "🔌 Toggle Plugins (Opencode/Avante/Claude/etc)" })

-- 󰧑 󰮮 Optimización para AI completions multi-línea
vim.opt.updatetime = 100 -- Respuesta más rápida (default: 4000ms)
vim.opt.scrolloff = 8 -- Más contexto visible
vim.opt.synmaxcol = 500 -- Más columnas para análisis

