-- ~/.config/nvim/lua/config/Windows-pywal-wiwalAuto.lua
-- VERSIÓN DUAL: Windows PowerShell + WSL Bash

local M = {}

function M.setup()
  -- Detectar entorno
  local is_windows = vim.fn.has("win32") == 1
  local is_wsl = vim.fn.has("wsl") == 1 or vim.fn.isdirectory("/mnt/c") == 1

  -- Si no es Windows ni WSL, salir (es Arch nativo)
  if not is_windows and not is_wsl then
    return
  end

  -- ================================================
  -- FUNCIÓN PARA WINDOWS (PowerShell)
  -- ================================================
  local function update_pywal_windows()
    -- Ejecutar WalManager en PowerShell (oculto, compatible con shell=pwsh)
    vim.fn.jobstart({ "cmd", "pwsh", "-NoProfile", "-Command", "uwal -y" }, { detach = true })
    -- usando cmd /c para invocar pwsh en una terminal aparte
  end

  -- ================================================
  -- FUNCIÓN PARA WSL (Bash)
  -- ================================================
  local function update_pywal_wsl()
    -- Obtener wallpaper actual de Windows desde WSL
    local get_wallpaper_cmd = [[
      powershell.exe -NoProfile -Command "
        \$RegPath = 'HKCU:\Control Panel\Desktop';
        (Get-ItemProperty -Path \$RegPath -Name Wallpaper).Wallpaper
      "
    ]]

    -- Ejecutar comando y capturar salida
    local handle = io.popen(get_wallpaper_cmd)
    local wallpaper_path = handle:read("*a"):gsub("[\r\n]", "")
    handle:close()

    if wallpaper_path and wallpaper_path ~= "" then
      -- Convertir ruta Windows a WSL (C:\Users\... → /mnt/c/Users/...)
      local wsl_path = wallpaper_path
        :gsub("\\", "/") -- \ → /
        :gsub("^(%a):", function(drive) -- C: → /mnt/c
          return "/mnt/" .. drive:lower()
        end)

      -- Ejecutar wal con la ruta convertida
      local wal_cmd = string.format('wal -i "%s" --backend colorthief -n > /dev/null 2>&1 &', wsl_path)
      vim.fn.system(wal_cmd)

      vim.notify("🎨 Actualizando colores (WSL Pywal)", vim.log.levels.INFO)
    else
      vim.notify("❌ No se pudo detectar wallpaper de Windows", vim.log.levels.WARN)
    end
  end

  -- ================================================
  -- FUNCIÓN UNIFICADA
  -- ================================================
  local function update_pywal()
    if is_windows then
      update_pywal_windows()
    elseif is_wsl then
      update_pywal_wsl()
    end
  end

  -- ================================================
  -- AUTORUN AL INICIO
  -- ================================================
  vim.defer_fn(function()
    update_pywal()
  end, 2000) -- 2 segundos después de cargar Nvim

  -- ================================================
  -- KEYMAP MANUAL
  -- ================================================
  vim.keymap.set("n", "<leader>lu", update_pywal, {
    desc = "🎨 Actualizar Pywal (usar fondo actual de Windows)",
  })

  -- ================================================
  -- COMANDO PARA DEBUGGING
  -- ================================================
  vim.api.nvim_create_user_command("PywalDebug", function()
    if is_windows then
      print("🖥️  Entorno: Windows PowerShell")
      print("📂 Cache: C:\\Users\\Diego\\.cache\\wal\\")
      print("🔧 Comando: uwal -y (WalManager)")
    elseif is_wsl then
      print("🐧 Entorno: WSL Arch Linux")
      print("📂 Cache: ~/.cache/wal/")
      print("🔧 Comando: wal -i [wallpaper_de_windows]")
    end
  end, { desc = "Mostrar info de Pywal Auto" })
end

return M
