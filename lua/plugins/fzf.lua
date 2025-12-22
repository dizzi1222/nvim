-- ~/.config/nvim/lua/plugins/fzf.lua
return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>sf", "<cmd>FzfLua files<cr>", desc = "Files (cwd)" },
    { "<leader>sg", "<cmd>FzfLua live_grep<cr>", desc = "Grep (cwd)" },
    {
      "<leader>sw",
      function()
        require("fzf-lua").files({ cwd = "/mnt/c/Users/diego/" })
      end,
      desc = "Files (Windows)",
    },
    {
      "<leader>sh",
      function()
        require("fzf-lua").files({ cwd = "~" })
      end,
      desc = "Files (Home)",
    },
  },
  opts = {
    files = {
      fd_opts = "--color=never --type f --hidden --follow " ..
                "--exclude .git --exclude node_modules --exclude no_repo " ..
                "--exclude .cache --exclude .vscode-server --exclude '*.log'",
    },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case " ..
                "--glob '!.git' --glob '!node_modules' --glob '!no_repo' " ..
                "--glob '!.cache' --glob '!.vscode-server' -e",
    },
  },
}
