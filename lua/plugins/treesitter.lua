-- Detectar plataforma
local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

if is_wsl or is_windows then
  -- PARA WINDOWS O WSL
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      config = function()
        -- Silenciar errores de treesitter
        -- No recomendable, pero no me quedo de otra [En Windows].
        local status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
        if not status_ok then
          return
        end

        treesitter.setup({
          auto_install = true,
          indent = { enable = true },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        })
      end,
    },
  }
else
  -- PARA LINUX
  return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = {
        enable = true,
        disable = { "snacks_picker_list", "snacks_picker", "snacks_input", "snacks_notif" },
      },
    },
  }
end
