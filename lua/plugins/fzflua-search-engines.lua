-- ~/.config/nvim/lua/plugins/fzflua-search-engines.lua
-- VERSIÓN ALTERNATIVA: Solo FZF-Lua (sin Mini.pick)

local is_wsl = vim.fn.has("wsl") == 1

return {
  -- ============================================
  -- FZF-LUA (Único buscador)
  -- ============================================
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      -- 🔍 BÚSQUEDA PRINCIPAL
      { "<leader>fz", "<cmd>FzfLua files<cr>", desc = " 🔍 [FZF] Search Files" },
      { "<leader>fG", "<cmd>FzfLua live_grep<cr>", desc = " 🔍 [FZF] Live Grep" },

      -- 📂 UBICACIONES ESPECÍFICAS
      {
        "<leader>fw",
        function()
          if is_wsl then
            require("fzf-lua").files({ cwd = "/mnt/c/Users/diego/" })
          else
            require("fzf-lua").files({ cwd = "~" })
          end
        end,
        desc = "🔍 [FZF] Files HOME",
      },

      -- 📋 UTILIDADES
      { "<leader>h", "<cmd>FzfLua help_tags<cr>", desc = " 🔍 [FZF] Help" },
      { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = " 🔍 [FZF] Marks" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = " 🔍 [FZF] Keymaps" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = " 🔍 [FZF] Buffers" },
      { "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = " 🔍 [FZF] Old Files" },
      { "<leader>fC", "<cmd>FzfLua commands<cr>", desc = " 🔍 [FZF] Commands" },
      { "<leader>f:", "<cmd>FzfLua command_history<cr>", desc = " 🔍 [FZF] History" },

      -- 📁 EXTRAS
      { "<leader>fS", "<cmd>FzfLua tags<cr>", desc = " 🔍 [FZF] Tags" },
      {
        "<leader>fc",
        function()
          require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "🔍 [FZF] Config Files",
      },
    },
    config = function()
      require("fzf-lua").setup({
        files = {
          fd_opts = "--color=never --type f --hidden --follow "
            .. "--exclude .git --exclude node_modules --exclude no_repo "
            .. "--exclude .cache --exclude .vscode-server --exclude '*.log'",
        },
        grep = {
          rg_opts = "--column --line-number --no-heading --color=always --smart-case "
            .. "--glob '!.git' --glob '!node_modules' --glob '!no_repo' "
            .. "--glob '!.cache' --glob '!.vscode-server' -e",
        },
        winopts = {
          height = 0.85,
          width = 0.95,
          row = 0.35,
          col = 0.5,
          border = "single",
          preview = {
            scrollbar = "float",
            layout = "horizontal",
          },
        },
        keymap = {
          builtin = {
            ["<C-f>"] = "toggle-fullscreen",
            ["<C-q>"] = "select-all+accept",
            ["<C-t>"] = "tab",
            ["<C-x>"] = "split",
            ["<C-v>"] = "vsplit",
          },
        },
      })
    end,
  },
}
