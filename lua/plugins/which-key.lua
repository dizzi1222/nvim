local delete_current_file = function()
  vim.cmd("!rm %")
  vim.cmd("bd")
end

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- Especificación de grupos y mappings
    spec = {
      -- Grupos principales con íconos
      { "<leader>c", group = " Code" },
      { "<leader>d", group = " Debug" },
      { "<leader>f", group = " File/Find" },
      { "<leader>g", group = "󰊢 Git" },
      { "<leader>l", group = "󰒲 Lazy" },
      { "<leader>n", group = " Notifications" },
      -- Sintaxis correcta con color
      { "<leader>i", group = "󰋩 Imágenes Clipboard", icon = { icon = "󰋩", color = "green" } },
      { "<leader>a", icon = { icon = "" } },
      -- [Visual Mode] Hacer mapeos por modos visuales [mode = "x"]
      { "<leader>ay", icon = { icon = "󰆏" } },
      { "<leader>a", mode = "x", group = " AI Send To", icon = { icon = "" } },
      { "<leader>aG", icon = { icon = "" } },
      { "<leader>G", icon = { icon = "" } },
      { "<leader>gg", icon = { icon = "" } },
      { "<leader>ag", group = "Antigravity prompt", icon = { icon = "" } },
      -- Opencode Send To AI
      { "<leader>aC", icon = { icon = "󰮮" } },
      { "<leader>ak", icon = { icon = "󰮮" } },
      { "<leader>al", icon = { icon = "󰮮" } },
      { "<leader>aL", icon = { icon = "󰮮" } },
      { "<leader>am", icon = { icon = "󰮮" } },
      { "<leader>ao", icon = { icon = "󰮮" } },
      { "<leader>ar", icon = { icon = "󰮮" } },
      { "<leader>aF", icon = { icon = "󰮮" } },
      { "<leader>as", icon = { icon = "󰮮" } },
      { "<leader>au", icon = { icon = "󰮮" } },
      { "<leader>ax", icon = { icon = "󰮮" } },
      { "<leader>ap", icon = { icon = "󰮮" } },
      -- [Visual Mode] Atajos para Avante Send To AI en modo visual
      { "<leader>ae", mode = "x", group = "avante: edit", icon = { icon = "" } },
      { "<leader>an", mode = "x", group = "avante: new ask", icon = { icon = "" } },
      { "<leader>aa", mode = "x", group = "avante: ask", icon = { icon = "" } },
      -- { "<leader>aA", group = " ~ Abrir AI (aichat) con menú", icon = { icon = "" } },
      { "<leader>aO", group = "🦞 ~ Abrir Clawdbot Openclawd", icon = { icon = "🦞" } },
      -- { "<leader>af", group = " ~ Abrir AI FittenCode Autocomplete", icon = { icon = "" } },
      -- { "<leader>af", mode = "x", group = " ~ Abrir AI FittenCode Autocomplete", icon = { icon = "" } },
      {
        "<leader>em",
        mode = "x",
        group = "Engram: Memory Persistent [Opencode, AI]",
        icon = { icon = "󰍛", color = "pink" },
      },
      { "<leader>af", icon = { icon = "" } },
      { "<leader>ab", icon = { icon = "" } },
      { "<leader>aB", icon = { icon = "" } },
      { "<leader>b", group = "󰓩 Buffer", icon = { icon = "󰓩" } },
      { "<leader>h", group = "󰓹 Tag Menu", icon = { icon = "󰛢" } },
      { "<leader>m", group = "󰍔 Markdown", icon = { icon = "󰍔" } },
      { "<leader>?", group = "show all keymaps", icon = { icon = "󰌌" } },
      { "<leader>k", group = "󰌌 screenkey", icon = { icon = "󰳽" } },
      { "<leader>K", group = "󰌌 Help Keywordprg", icon = { icon = "󰘦" } },
      { "<leader>o", group = "󰇈 Obsidian", icon = { icon = "󰇈" } },
      { "<leader>p", group = "󱥒  Toggle Pywal", icon = { icon = "" } },
      { "<leader>M", group = "  MCP HUB", icon = { icon = "" } },
      { "<leader>v", group = "󰉦 󰇀 Color pick", icon = { icon = "" } },
      -- [FIN] Sintaxis correcta con color
      { "<leader>q", group = "󰗼 Quit/Session" },
      { "<leader>s", group = "󰍉 Search" },
      { "<leader>u", group = " UI" },
      { "<leader>w", group = "󱂬 Windows" },
      { "<leader>x", group = "󰁨 Diagnostics/Quickfix" },
      -- Ocultar del dashboard los duplicados de "f" (/fork): "F".
      -- La key vive igual pero no se lista en which-key.
      { mode = "n", "<leader>agF", hidden = true },
      { mode = "n", "<leader>GF", hidden = true },
      { mode = "n", "<leader>ggF", hidden = true },
      { mode = "n", "<leader>agg", hidden = true },
      { mode = "n", "<leader>Gg", hidden = true },
      { mode = "n", "<leader>ggg", hidden = true },
      { mode = "n", "<leader>agG", hidden = true },
      { mode = "n", "<leader>GG", hidden = true },
      { mode = "n", "<leader>ggG", hidden = true },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = true })
      end,
      desc = "show all keymaps",
    },
    -- Buffer keymaps
    { "<leader>bN", "<cmd>enew<CR>", desc = "New buffer" },
    { "<leader>b[", "<cmd>bp<CR>", desc = "Previous buffer" },
    { "<leader>b]", "<cmd>bn<CR>", desc = "Next buffer " },
    { "<leader>bl", "<C-^>", desc = "Switch to last buffer" },
    { "<leader>bn", "<cmd>bn<CR>", desc = "Next buffer" },
    { "<leader>bp", "<cmd>bn<CR>", desc = "Next buffer" },
    -- File keymaps
    {
      "<leader>fd",
      function()
        delete_current_file()
      end,
      desc = "Delete current file",
    },
    -- Window keymaps
    { "<leader>w=", "<C-W>=", desc = "balance-windows" },
    { "<leader>w?", "Windows", desc = "fzf-window" },
    { "<leader>wH", "<C-W>5<", desc = "expand-window-left" },
    { "<leader>wJ", ":resize +5", desc = "expand-window-below" },
    { "<leader>wK", ":resize -5", desc = "expand-window-up" },
    { "<leader>wL", "<C-W>5>", desc = "expand-window-right" },
    { "<leader>wO", "<C-W>o", desc = "close other windows" },
    { "<leader>wS", "<C-W>s", desc = "split and focus window below" },
    { "<leader>wV", "<C-W>v", desc = "split and focus window right" },
    { "<leader>wW", "<C-W>W", desc = "prev-window" },
    { "<leader>wc", "<C-W>c", desc = "delete-window" },
    { "<leader>wd", "<C-W>c", desc = "delete-window" },
    { "<leader>wh", "<C-W>h", desc = "window-left" },
    { "<leader>wj", "<C-W>j", desc = "window-below" },
    { "<leader>wk", "<C-W>k", desc = "window-up" },
    { "<leader>wl", "<C-W>l", desc = "window-right" },
    { "<leader>ws", "<C-W>s<C-W>W", desc = "split window below" },
    { "<leader>wv", "<C-W>v<C-W>W", desc = "split window right" },
    { "<leader>ww", "<C-W>w", desc = "next-window" },
  },
}
