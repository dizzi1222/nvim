return {
  "johnseth97/codex.nvim",
  cmd = { "Codex", "CodexToggle" },
  opts = {
    -- Los atajos viven en config/keymaps/codex-keys.lua para mantener el
    -- mismo esquema que Agy y evitar el <C-q> interno (ya está ocupado).
    keymaps = {
      toggle = nil,
      quit = nil,
    },
    border = "rounded",
    panel = true,
    width = 0.35,
    height = 0.8,
    use_buffer = false,
    autoinstall = false, -- el CLI codex ya está instalado
  },
}
