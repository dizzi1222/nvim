-- ~/.config/nvim/lua/config/highlights.lua
-- Colores personalizados para sugerencias de IA

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- 🎨 Copilot (color naranja suave)
    vim.api.nvim_set_hl(0, "CopilotSuggestion", {
      fg = "#caa99b", -- Color que querías
      italic = true,
      ctermfg = 244,
    })

    -- 🎨 Codeium (mismo color)
    vim.api.nvim_set_hl(0, "CodeiumSuggestion", {
      fg = "#caa99b",
      italic = true,
      ctermfg = 244,
    })

    -- 🎨 Avante Markdown (fix para tablas)
    vim.api.nvim_set_hl(0, "RenderMarkdownTableHead", { fg = "#89b4fa", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownTableRow", { fg = "#cdd6f4" })
  end,
})
