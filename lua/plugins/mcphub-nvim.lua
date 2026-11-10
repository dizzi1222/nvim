return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
  config = function()
    -- Termux no tiene /usr/bin/env, así que el shebang de mcp-hub falla.
    -- Si el ejecutable no sirve, se lanza con node directamente.
    local opts = {}
    local cli = vim.fn.expand("~/.npm-global/lib/node_modules/mcp-hub/dist/cli.js")
    if vim.fn.filereadable(cli) == 1 then
      opts.cmd = "node"
      opts.cmdArgs = { cli }
    end
    require("mcphub").setup(opts)
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>M", group = " 󰍔 MCP HUB", icon = { icon = "" } })
    end
  end,
}
