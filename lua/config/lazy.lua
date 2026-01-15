-- CONFIGURAR IA EN LA LINEA: 30
-- 💸💳💰 DONDE ESTA CHATGPT? COMO IA ES TREMENDA.. PERO NO ES GRATIS PARA INTEGRARLO EN NVIM DIRECTAMENTE. Al igual que Avante [avane/cursor es mejor]
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/plugins/copilot.lua [opcional usa copilot-chat.lua]
--   - .config/nvim/lua/plugins/supermaven.lua {etc..}
--
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua--
--- 🔧 CONFIGURACIÓN UNIFICADA: lazy.lua para WSL + Arch Linux
-- Detecta automáticamente el entorno y aplica configuraciones específicas

-- ========================================
-- 📍 DETECCIÓN DE PLATAFORMA
-- ========================================
local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

-- ========================================
-- 🔧 CONFIGURACIONES ESPECÍFICAS DE PLATAFORMA
-- ========================================

-- Node.js configuration (WSL específico)
if is_wsl or is_windows then
  vim.g.node_host_prog = vim.fn.exepath("node") or "/usr/local/bin/node"
end

-- Spell-checking (todas las plataformas)
vim.opt.spell = true
vim.opt.spelllang = { "en" }

-- ========================================
-- 📦 BOOTSTRAP DE LAZY.NVIM
-- ========================================
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

-- ========================================
-- 📋 FIX CLIPBOARD EN WSL (CRÍTICO)
-- ========================================
vim.opt.clipboard = "unnamedplus"

if is_wsl then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = false,
  }
end

-- ========================================
-- 🚀 LAZY.NVIM SETUP
-- ========================================
require("lazy").setup({
  spec = {
    -- Base LazyVim
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- 🔹 Editor plugins (solo en Arch Linux - opcional en WSL)
    -- Descomenta si quieres marcadores:
    -- { import = "lazyvim.plugins.extras.editor.harpoon2" },

    -- Snacks picker (recomendado para ambas plataformas)
    { import = "lazyvim.plugins.extras.editor.snacks_picker" },

    -- 🔹 MERN stack: formatter, linter y lenguajes
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.markdown" },

    -- 🔹 Otros lenguajes (descomentá si los necesitás)
    -- { import = "lazyvim.plugins.extras.formatting.biome" },
    -- { import = "lazyvim.plugins.extras.lang.angular" },
    -- { import = "lazyvim.plugins.extras.lang.astro" },
    -- { import = "lazyvim.plugins.extras.lang.go" },
    -- { import = "lazyvim.plugins.extras.lang.nix" },
    -- { import = "lazyvim.plugins.extras.lang.toml" },

    -- 🔹 AI (Copilot y Chat)
    { import = "lazyvim.plugins.extras.ai.copilot" },
    { import = "lazyvim.plugins.extras.ai.copilot-chat" },
    -- 💡 Si querés usar Avante o Claude Code, desactivá copilot-chat arriba

    -- 🔹 Render Markdown
    {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      ft = { "markdown", "md" },
      event = "BufReadPre",
      config = function()
        require("render-markdown").setup({
          heading = {
            enabled = true,
            sign = true,
            style = "full",
            icons = { "① ", "② ", "③ ", "④ ", "⑤ ", "⑥ " },
            left_pad = 1,
          },
          bullet = {
            enabled = true,
            icons = { "●", "○", "◆", "◇" },
            right_pad = 1,
            highlight = "render-markdownBullet",
          },
        })

        -- Auto-activar al cargar archivos markdown
        vim.schedule(function()
          if vim.bo.filetype == "markdown" then
            require("render-markdown").enable()
          end
        end)
      end,
    },

    -- 🔹 Plugins personalizados
    { import = "plugins" },
    { "fedepujol/move.nvim" },
  },

  defaults = {
    lazy = false,
    version = false,
  },

  install = {
    colorscheme = { "tokyonight", "habamax" },
  },

  checker = {
    enabled = true,
    notify = false,
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- ========================================
-- ℹ️ INFORMACIÓN DEL SISTEMA (DEBUG)
-- ========================================
-- Descomenta para ver info de tu entorno al iniciar
-- vim.notify(string.format("Sistema: %s | WSL: %s",
--   is_linux and "Linux" or (is_wsl and "WSL" or "Windows"),
--   is_wsl and "Sí" or "No"
-- ), vim.log.levels.INFO)-
