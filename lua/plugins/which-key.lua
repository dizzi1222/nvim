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
      { "<leader>a", group = " AI/Claude Code", icon = { icon = "󰧑", color = "orange" } },
      { "<leader>aa", group = " ~ Abrir AI (aichat) con menú", icon = { icon = "󰧑", color = "orange" } },
      { "<leader>ac", group = " ~ Abrir AI (aichat) con menú", icon = { icon = "󰧑", color = "orange" } },
      { "<leader>b", group = "󰓩 Buffer", icon = { icon = "󰓩", color = "green" } },
      { "<leader>h", group = "󰓹 Tag Menu", icon = { icon = "󰛢", color = "blue" } },
      { "<leader>m", group = "󰍔 Markdown", icon = { icon = "󰍔", color = "red" } },
      { "<leader>?", group = "show all keymaps", icon = { icon = "󰌌", color = "cyan" } },
      { "<leader>k", group = "󰌌 screenkey", icon = { icon = "󰳽", color = "cyan" } },
      { "<leader>K", group = "󰌌 Help Keywordprg", icon = { icon = "󰘦", color = "cyan" } },
      { "<leader>o", group = "󰇈 Obsidian", icon = { icon = "󰇈", color = "purple" } },
      { "<leader>p", group = "󱥒  Toggle Pywal", icon = { icon = "", color = "red" } },
      { "<leader>M", group = "  MCP HUB", icon = { icon = "", color = "purple" } },
      { "<leader>v", group = "󰉦 󰇀 Color pick", icon = { icon = "", color = "red" } },
      -- [FIN] Sintaxis correcta con color
      { "<leader>q", group = "󰗼 Quit/Session" },
      { "<leader>s", group = "󰍉 Search" },
      { "<leader>u", group = " UI" },
      { "<leader>w", group = "󱂬 Windows" },
      { "<leader>x", group = "󰁨 Diagnostics/Quickfix" },
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
