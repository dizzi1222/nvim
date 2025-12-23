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
      
      -- Helper: Obtener tema guardado de theme.txt
      local function get_saved_theme()
        local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
        local file = io.open(theme_file, "r")
        if file then
          local line = file:read("*line")
          file:close()
          if line then return line:gsub("^%s*(.-)%s*$", "%1") end
        end
        return nil
      end

      -- Helper: Escribir tema a theme.txt
      local function save_theme_to_file(theme_name)
        local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
        local file = io.open(theme_file, "w")
        if file then
          file:write(theme_name)
          file:close()
        end
      end

      -- Inicialización de variables
      local saved_theme = get_saved_theme()
      local previous_theme = "aura-dark" -- Fallback global
      
      -- Si el tema guardado no es pywal, ese es nuestro previous_theme
      if saved_theme and saved_theme ~= "pywal" and saved_theme ~= "" then
        previous_theme = saved_theme
      end

      -- Cargar Pywal si está en theme.txt
      if saved_theme == "pywal" then
        local wal_colors = vim.fn.expand("~/.cache/wal/colors-wal.vim")
        if vim.fn.filereadable(wal_colors) == 1 then
          pcall(function()
            require("pywal").setup()
            vim.cmd("colorscheme pywal")
            vim.g.colors_name = "pywal"
          end)
        end
      end

      -- Variable global para que otros plugins lo vean
      vim.g.pywal_loaded = true

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
          end
        end, 100)
      end

      -- Guardar tema actual SOLO si no es pywal
      local function save_current_theme_if_not_pywal()
        local current = vim.g.colors_name
        if current and current ~= "" and current ~= "pywal" then
          previous_theme = current
          return current
        end
        return nil
      end

      -- Toggle pywal CON opacidad (fondo oscuro)
      local function toggle_pywal()
        local current = vim.g.colors_name or ""

        if current == "pywal" then
          -- Volver al tema anterior
          local target_theme = previous_theme or "aura-dark"
          vim.cmd("colorscheme " .. target_theme)
          vim.g.colors_name = target_theme
          save_theme_to_file(target_theme)
          print("🔙 Volviendo a: " .. target_theme)
        else
          -- Guardar tema actual
          save_current_theme_if_not_pywal()
          -- Cambiar a pywal y guardar
          apply_pywal_with_opacity()
          save_theme_to_file("pywal")
          print("🎨 Cambiando a: Pywal")
        end
        vim.cmd("redraw!")
      end

      -- Toggle pywal fondo transparente (SIN opacidad)
      local function toggle_pywal_transparent()
        local current = vim.g.colors_name or ""

        if current == "pywal" then
          -- Si ya estamos en pywal, volver al tema anterior
          local target_theme = previous_theme or "aura-dark"
          vim.cmd("colorscheme " .. target_theme)
          vim.g.colors_name = target_theme
          save_theme_to_file(target_theme)
          print("🔙 Volviendo a: " .. target_theme)
        else
          -- Guardar tema actual
          save_current_theme_if_not_pywal()
          -- Cambiar a pywal Transparente y guardar
          apply_pywal_without_opacity()
          save_theme_to_file("pywal")
          print("🎨 Cambiando a: Pywal (Transparente)")
        end
        vim.cmd("redraw!")
      end

      -- Exportar funciones
      vim.g.toggle_pywal = toggle_pywal
      vim.g.toggle_pywal_transparent = toggle_pywal_transparent

      -- Mapear teclas
      vim.keymap.set("n", "<leader>p", toggle_pywal, { noremap = true, silent = false, desc = "🎨Toggle Pywal" })
      vim.keymap.set("n", "<leader>pw", toggle_pywal_transparent, { noremap = true, silent = false, desc = "🎨Toggle Pywal (Transparente)" })

      -- Actualizar previous_theme dinámicamente si cambia el tema fuera de pywal
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local current = vim.g.colors_name
          if current and current ~= "pywal" and current ~= "" then
            previous_theme = current
          end
        end,
      })
    end,
  },
}
