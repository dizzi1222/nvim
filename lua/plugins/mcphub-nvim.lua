return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
  config = function()
    require("mcphub").setup()
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>M", group = " 󰍔 MCP HUB", icon = { icon = "" } })
    end
  end,
}
