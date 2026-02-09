-- https://openclaw.ai/
-- https://github.com/njg7194/openclaw.nvim
return {
  -- "OpenKnots/openclaw.nvim",
  "njg7194/openclaw.nvim",
  config = function()
    require("openclaw").setup({
      command = "openclaw",
      auto_connect = false,
      status_refresh_ms = 5000,
      notify_on_status_change = true,
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>aO", "<cmd>OpenClawConnect<cr>", { desc = "OpenClaw Connect" })
    vim.keymap.set("n", "<leader>aOd", "<cmd>OpenClawDisconnect<cr>", { desc = "OpenClaw Disconnect" })
    vim.keymap.set("n", "<leader>aOs", "<cmd>OpenClawStatus<cr>", { desc = "OpenClaw Status" })
    vim.keymap.set("n", "<leader>aOt", "<cmd>OpenClawTUI<cr>", { desc = "OpenClaw TUI" })
  end,
}
