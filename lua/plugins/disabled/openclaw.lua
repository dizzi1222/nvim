-- https://openclaw.ai/
-- https://github.com/OpenKnots/openclaw.nvim
return {
  "OpenKnots/openclaw.nvim",
  config = function()
    require("openclaw").setup({
      command = "clawdbot", -- antes era "openclaw"
      auto_connect = false,
      status_refresh_ms = 5000,
      notify_on_status_change = true,
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>aOc", "<cmd>OpenClawConnect<cr>", { desc = "OpenClaw Connect" })
    vim.keymap.set("n", "<leader>aOd", "<cmd>OpenClawDisconnect<cr>", { desc = "OpenClaw Disconnect" })
    vim.keymap.set("n", "<leader>aOs", "<cmd>OpenClawStatus<cr>", { desc = "OpenClaw Status" })
    vim.keymap.set("n", "<leader>aOt", "<cmd>OpenClawTUI<cr>", { desc = "OpenClaw TUI" })

    -- which-key: solo mostrar icono cuando openclaw está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ "<leader>aO", group = "🦞 ~ Abrir Clawdbot Openclawd", icon = { icon = "🦞" } })
    end
  end,
}
