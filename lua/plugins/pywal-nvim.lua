-- pywal-nvim.lua (INTEGRADO CON TU SISTEMA)
return {
  {
    "AlphaTechnolog/pywal.nvim",
    name = "pywal",
    lazy = false,
    priority = 1000,
    config = function()
      -- ------------------------------------------------
      -- Configuración inicial de Pywal.nvim en Linux/MacOS
      -- ------------------------------------------------
      -- Guardamos tu colorscheme original
      local original_colorscheme = vim.g.colors_name or "default"
      local wal_active = true -- Pywal inicia activado = true /o false
      -- antes: "default"
      -- # ESTO DE TERMINA SI ARRANCA FALSE O TU TEMA
      -- # CON SPACE + PW o SPACE + P = Alternas entre Pywal / colorscheme

      -- Activamos Pywal al inicio solo si existe el archivo de colores
      if wal_active then
        local wal_colors = vim.fn.expand("~/.cache/wal/colors-wal.vim")
        if vim.fn.filereadable(wal_colors) == 1 then
          pcall(function()
            require("pywal").setup()
          end)
        else
          -- No mostrar error, simplemente no cargar pywal y usar el por defecto
          wal_active = false
          vim.cmd("colorscheme " .. original_colorscheme)
        end
      else
        vim.cmd("colorscheme " .. original_colorscheme)
      end

      -- Configurar pywal
      -- require("pywal").setup()

      -- Variable global para que otros plugins lo vean
      vim.g.pywal_loaded = true

      -- Variable para almacenar el tema anterior (SOLO para cuando estamos en pywal)
      local previous_theme = nil

      -- ---------------------------------------
      -- Función toggle de Pywal con y sin opacidad
      -- ---------------------------------------

      -- Función para aplicar pywal con opacidad
      local function apply_pywal_with_opacity()
        vim.cmd("colorscheme pywal")
        vim.g.colors_name = "pywal"

        vim.defer_fn(function()
          -- Aplicar opacidad base
          if vim.g.apply_background_opacity then
            vim.g.apply_background_opacity()
          end
        end, 100)
      end

      -- Función para aplicar pywal SIN opacidad (transparente)
      local function apply_pywal_without_opacity()
        vim.cmd("colorscheme pywal")
        vim.g.colors_name = "pywal"

        vim.defer_fn(function()
          -- Desactivar opacidad para fondo transparente
          if vim.g.toggle_background_opacity then
            -- Si ya está activa, desactivarla primero para resetear
            if vim.g.background_opacity_enabled then
              vim.g.toggle_background_opacity(false)
            end
            -- Dejar desactivada (fondo transparente)
          end
        end, 100)
      end

      -- Guardar tema actual SOLO si no es pywal (VERSIÓN MEJORADA)
      local function save_current_theme_if_not_pywal()
        local saved_theme = nil
        if vim.g.get_saved_theme then
          saved_theme = vim.g.get_saved_theme()
        end

        -- Fallback: usar vim.g.colors_name
        local current = saved_theme or vim.g.colors_name

        if current and current ~= "" and current ~= "pywal" then
          previous_theme = current
          print("📝 Tema guardado: " .. current)
          return current
        end
        return nil
      end

      -- Reiniciar tema actual
      -- local function restart_current_theme()
      --   local current = vim.g.colors_name
      --   if current and current ~= "" then
      --     print("🔄 Restarting theme: " .. current)
      --     vim.cmd("colorscheme " .. current)
      --     vim.cmd("redraw!")
      --   end
      -- end

      -- Toggle pywal CON opacidad (fondo oscuro)
      local function toggle_pywal()
        local current = vim.g.colors_name or ""

        if current == "pywal" then
          -- Volver al tema anterior
          local target_theme = previous_theme
          vim.cmd("colorscheme " .. target_theme)
          vim.g.colors_name = target_theme

          -- Guardar en theme.txt
          local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
          local file = io.open(theme_file, "w")
          if file then
            file:write(target_theme)
            file:close()
          end

          print("🔙 Volviendo a: " .. target_theme)
        else
          -- Guardar tema actual
          save_current_theme_if_not_pywal()

          -- Cambiar a pywal CON opacidad
          apply_pywal_with_opacity()
          print("🎨 Cambiando a: Pywal")
        end

        vim.cmd("redraw!")
      end
      -- Toggle pywal fondo transparente (SIN opacidad)
      local function toggle_pywal_transparent()
        local current = vim.g.colors_name or ""

        if current == "pywal" then
          -- Si ya estamos en pywal, volver al tema anterior
          local target_theme = previous_theme
          vim.cmd("colorscheme " .. target_theme)
          vim.g.colors_name = target_theme

          -- Guardar en theme.txt
          local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
          local file = io.open(theme_file, "w")
          if file then
            file:write(target_theme)
            file:close()
          end

          print("🔙 Volviendo a: " .. target_theme)
        else
          -- Guardar tema actual
          save_current_theme_if_not_pywal()

          -- Cambiar a pywal Transparente
          apply_pywal_without_opacity()
          print("🎨 Cambiando a: Pywal (Transparente)")
        end

        vim.cmd("redraw!")
      end
      -- Exportar funciones
      vim.g.toggle_pywal = toggle_pywal
      vim.g.toggle_pywal_transparent = toggle_pywal_transparent
      -- vim.g.restart_current_theme = restart_current_theme

      -- Mapear teclas [p]
      vim.keymap.set("n", "<leader>p", toggle_pywal, {
        noremap = true,
        silent = false,
        desc = "🎨Toggle Pywal (Alternar",
      })

      vim.keymap.set("n", "<leader>pw", toggle_pywal_transparent, {
        noremap = true,
        silent = false,
        desc = "🎨Toggle Pywal (Alternar",
      })

      -- vim.keymap.set("n", "<leader>pr", restart_current_theme, {
      --   noremap = true,
      --   silent = false,
      --   desc = "🔄Restart Current Theme",
      -- })

      -- Inicializar previous_theme DESPUÉS de que cargue el tema por defecto
      vim.defer_fn(function()
        local current = vim.g.colors_name
        if current and current ~= "" and current ~= "pywal" then
          previous_theme = current
          -- print("📝 Previous theme saved: " .. current)
        end
      end, 1000) -- Esperar 1 segundo para que cargue el tema por defecto

      -- NO aplicar pywal al inicio - dejar que colorscheme.lua maneje el tema inicial
      -- print("✅ Pywal configurado (no se activa al inicio)")
    end,
  },
}

