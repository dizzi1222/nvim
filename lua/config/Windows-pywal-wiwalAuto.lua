-- ~/.config/nvim/lua/config/Windows-pywal-wiwalAuto.lua
local M = {}

function M.setup()
  local is_windows = vim.fn.has("win32") == 1
  if not is_windows then
    return
  end

  -- Función para actualizar pywal (DEFINIDA FUERA de defer_fn)
  local function update_pywal()
    -- Abrir PowerShell en una ventana nueva (oculta) en segundo plano (Background = /B)
    vim.cmd([[!start /B pwsh -NonInteractive -WindowStyle Hidden -Command "uwal -y"]])
    -- vim.notify("🔄 Actualizando colores pywal...", vim.log.levels.INFO)
  end

  -- Ejecutar automáticamente al inicio
  vim.defer_fn(function()
    update_pywal()
  end, 2000) -- 2 segundos para que Neovim termine de cargar

  -- Mapear tecla para ejecutar manualmente
  vim.keymap.set("n", "<leader>lu", update_pywal, {
    desc = "Actualizar Pywal ~ Usar fondo actual colors",
  })

  -- print("✅ Pywal Auto: configurado")
  -- print("📌 Usa <leader>pu para actualizar manualmente")
end

return M
