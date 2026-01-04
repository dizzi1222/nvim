-- ~/.config/nvim/lua/plugins/fzflua-search-engines.lua
-- NO BORRES MIS COMENTARIOS ni mis DESC!
-- Space + Space = space + f+f para busqueda de archivos
return {
  -- ============================================
  -- FZF-LUA
  -- ============================================
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      -- 🔍 Buscar archivos
      { "<leader>sf", "<cmd>FzfLua files<cr>", desc = " 🔍 [FZF] Files (cwd)" },
      { "<leader>sz", "<cmd>FzfLua files<cr>", desc = " 🔍 [FZF] Files (cwd)" }, --  Z = [Fzf]
      -- Mismo atajo, pero uso Z (minúscula) para buscar archivos por que ff es usado por Telescope. Z = [Fzf]
      { "<leader>fz", "<cmd>FzfLua files<cr>", desc = " 🔍 [FZF] Files (cwd)" },

      -- 🔍 Buscar texto
      -- Espacio + f + Shift + G para buscar con grep FZF
      { "<leader>fG", "<cmd>FzfLua live_grep<cr>", desc = " 🔍 [FZF] Live Grep" },

      -- 📂 Buscar en ubicaciones específicas
      {
        "<leader>fw",
        function()
          require("fzf-lua").files({ cwd = "/mnt/c/Users/diego/" })
        end,
        desc = "🔍 [FZF] Files HOME / (Windows)",
      },
      -- En teoria seria lo mismo que lo de arriba, pero para WSL
      {
        "<leader>fH",
        function()
          require("fzf-lua").files({ cwd = "~" })
        end,
        desc = "🔍 [FZF] Files (Home)",
      },

      -- 📋 Otros buscadores FZF
      -- { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = " 🔍 [FZF] Buffers" },
      { "<leader>h", "<cmd>FzfLua help_tags<cr>", desc = " 🔍 [FZF] Help TagS" },
      { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = " 🔍 [FZF] Marks" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = " 🔍 [FZF] Keymaps" },
      { "<leader>fC", "<cmd>FzfLua commands<cr>", desc = " 🔍 [FZF] Commands" },
      { "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = " 🔍 [FZF] Old Files" },
      { "<leader>f:", "<cmd>FzfLua command_history<cr>", desc = " 🔍 [FZF] Command History" },
      -- Espacio + f + Shift + S para buscar tagS con FZF
      { "<leader>fS", "<cmd>FzfLua tags<cr>", desc = " 🔍 [FZF] TagS" },
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

  -- ============================================
  -- MINI.PICK (separado - es otro plugin)
  -- ============================================
  {
    "nvim-mini/mini.pick",
    keys = {
      -- Ⓜ️ Mini Pick - Varios atajos
      { "<leader>mp", "<cmd>Pick files<cr>", desc = "Ⓜ️📁 [Mini] Files Pro" },
      -- El unico atajo que uso de Mini para leader + f ya que ff es de Telescope y mi favorito.
      { "<leader>fP", "<cmd>Pick files<cr>", desc = "Ⓜ️📁 [Mini] Files Pro" },
      -- Espacio + s + Shift + P para buscar con Mini Files
      { "<leader>sP", "<cmd>Pick files<cr>", desc = "Ⓜ️📁 [Mini] Files Pro" },

      -- Ⓜ️ Otras funciones de Mini
      -- { "<leader>mP", "<cmd>Pick grep_live<cr>", desc = "Ⓜ️🔍 [Mini] Live Grep" },
      -- { "<leader>mb", "<cmd>Pick buffers<cr>", desc = "Ⓜ️📄 [Mini] Buffers" },
      -- { "<leader>mh", "<cmd>Pick help<cr>", desc = "Ⓜ️❓ [Mini] Help" },
      -- { "<leader>mo", "<cmd>Pick oldfiles<cr>", desc = "Ⓜ️📜 [Mini] Old Files" },
      -- { "<leader>mc", "<cmd>Pick commands<cr>", desc = "Ⓜ️⚡ [Mini] Commands" },
    },
    config = function()
      require("mini.pick").setup({
        mappings = {
          choose = "<CR>",
          choose_in_split = "<C-x>",
          choose_in_vsplit = "<C-v>",
          choose_in_tab = "<C-t>",
          go_to_item = "<C-g>",
        },
        options = {
          use_cache = true,
          content_from_bottom = false,
        },
        window = {
          config = {
            width = 0.8,
            height = 0.7,
            row = 0.4,
            col = 0.5,
          },
          prompt_prefix = "❯ ",
          prompt_postfix = "",
        },
      })
    end,
  },
}
