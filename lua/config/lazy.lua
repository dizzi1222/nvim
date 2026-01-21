-- CONFIGURAR IA EN LA LINEA: 30
-- 💸💳💰 DONDE ESTA CHATGPT? COMO IA ES TREMENDA.. PERO NO ES GRATIS PARA INTEGRARLO EN NVIM DIRECTAMENTE. Al igual que Avante [avane/cursor es mejor]

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
-- This file contains the configuration for setting up the lazy.nvim plugin manager in Neovim.

-- Node.js configuration - always use latest stable version
vim.g.node_host_prog = vim.fn.exepath("node") or "/usr/local/bin/node"

-- Spell-checking
vim.opt.spell = true -- activa spell checker
vim.opt.spelllang = { "en" }

-- Define the path to the lazy.nvim plugin
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Check if the lazy.nvim plugin is not already installed
if not vim.loop.fs_stat(lazypath) then
    -- Bootstrap lazy.nvim by cloning the repository
    -- stylua: ignore
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
        lazypath })
end

-- Prepend the lazy.nvim path to the runtime path
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Fix copy and paste in WSL (Windows Subsystem for Linux)
vim.opt.clipboard = "unnamedplus" -- Use the system clipboard for all operations
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank", -- Use win32yank for clipboard operations
    copy = {
      ["+"] = "win32yank.exe -i --crlf", -- Command to copy to the system clipboard
      ["*"] = "win32yank.exe -i --crlf", -- Command to copy to the primary clipboard
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf", -- Command to paste from the system clipboard
      ["*"] = "win32yank.exe -o --lf", -- Command to paste from the primary clipboard
    },
    cache_enabled = false, -- Disable clipboard caching
  }
end

-- Setup lazy.nvim with the specified configuration
require("lazy").setup({
  spec = {
    -- Add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Import any extra modules here
    -- Editor plugins
    -- { import = "lazyvim.plugins.extras.editor.harpoon2" },
    { import = "lazyvim.plugins.extras.editor.mini-files" },
    { import = "lazyvim.plugins.extras.editor.snacks_explorer" },
    { import = "lazyvim.plugins.extras.editor.snacks_picker" },

    -- Debgugging plugins
    { import = "lazyvim.plugins.extras.dap.core" },

    -- Formatting plugins
    { import = "lazyvim.plugins.extras.formatting.biome" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },

    -- Linting plugins
    { import = "lazyvim.plugins.extras.linting.eslint" },

    -- Language support plugins
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },

    -- Coding plugins
    { import = "lazyvim.plugins.extras.coding.mini-surround" },
    { import = "lazyvim.plugins.extras.editor.mini-diff" },
    { import = "lazyvim.plugins.extras.coding.blink" },

    -- Utility plugins
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },

    -- AI plugins
    -- { import = "lazyvim.plugins.extras.ai.copilot-chat" },
    -- 💡 Si querés usar Avante o Claude Code, desactivá copilot-chat arriba
    { import = "lazyvim.plugins.extras.ai.copilot" },
    --
    -- Import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot of the plugins that support versioning
    -- have outdated releases, which may break your Neovim install.
    version = false, -- Always use the latest git commit
    -- version = "*", -- Try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } }, -- Specify colorschemes to install
  -- No me importan las updates hdp .
  checker = { enabled = false }, -- Automatically check for plugin updates
  performance = {
    rtp = {
      -- Disable some runtime path plugins to improve performance
      disabled_plugins = {
        -- Para usar el de avante
        "markdown", -- Deshabilita el extra de markdown de LazyVim
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
