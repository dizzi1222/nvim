-- 🎨 TEMA CONFIGURABLE VÍA VARIABLE DE ENTORNO
-- Cambiar tema: export NVIM_THEME="everforest"
local default_theme = vim.env.NVIM_THEME or "aura-dark"
-- colorscheme.lua (VERSIÓN DEFINITIVA - Opacidad 50%/100% + Terminal Control)

-- 💡 TIPS DE USO:
-- • <Space> + C + T → Cambiar entre temas con preview (Telescope)
-- • <Ctrl> + O → Toggle opacidad 50% ↔ 100% transparente
-- • <Space> + U → Desactivar UI/animaciones (si usas snacks.nvim)
-- • Para personalizar lualine → ./plugins/ui.lua
-- • Temas disponibles: aura-dark, oasis-lagoon, everforest, catppuccin-frappe, gruvbox
-- • Para eliminar o reponer los puntos verticales (•trail•) , horizontales (⋅spaces⋅), se hace en ./indent_blankline.lua
return {
  -- 🔥 TREESITTER (siempre primero)
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- 🌃 TOKYONIGHT (Merged)
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        styles = { sidebars = "transparent", floats = "transparent" },
      })
      -- Link SmoothCursor to Tokyonight
      vim.api.nvim_set_hl(0, "SCCursorHead", { link = "Identifier" })
      vim.api.nvim_set_hl(0, "SCCursor", { link = "Identifier" })
    end,
  },

  -- 🪐 NEON (New)
  {
    "rafamadriz/neon",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.neon_style = "default"
      vim.g.neon_transparent = true
    end,
  },

  -- 🌫️ TRANSPARENT.NVIM (Merged)
  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({
        extra_groups = { "NormalFloat", "NvimTreeNormal" },
      })
    end,
  },

  --  SMOOTHCURSOR (Merged)
  {
    "gen740/SmoothCursor.nvim",
    config = function()
      require("smoothcursor").setup({
        cursor = "",
        texthl = "SCCursorHead",
        type = "exp",
        fancy = {
          enable = true,
          head = { cursor = "", texthl = "SCCursorHead" },
          body = {
            { cursor = "●", texthl = "SCCursor" },
            { cursor = "•", texthl = "SCCursor" },
            { cursor = "∙", texthl = "SCCursor" },
          },
        },
        speed = 20, intervals = 15, threshold = 1, disable_float_win = true,
      })
    end,
  },

  -- 🧛‍♀️ AURA THEME
  {
    "baliestri/aura-theme",
    lazy = false,
    priority = 1000,
    config = function(plugin)
      vim.opt.rtp:append(plugin.dir .. "/packages/neovim")
    end,
  },

  -- ✨ EVERFOREST
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 999,
    config = function()
      require("everforest").setup({
        background = "hard",
        transparent_background_level = 2,
        italics = true,
        disable_italic_comments = false,
      })
    end,
  },

  -- 🎨 CATPPUCCIN
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 998,
    config = function()
      require("catppuccin").setup({
        flavour = "frappe",
        transparent_background = true,
      })
    end,
  },

  -- 🟤 GRUVBOX
  {
    "morhetz/gruvbox",
    lazy = false,
    priority = 997,
  },

  -- 🌴 OASIS
  {
    "uhs-robert/oasis.nvim",
    lazy = false,
    priority = 996,
    config = function()
      require("oasis").setup()
    end,
  },

  -- 🌊 KANAGAWA (New)
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 995,
    config = function()
      require("kanagawa").setup({
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = true,
        dimInactive = false,
        terminalColors = true,
        theme = "wave",
        background = {
          dark = "wave",
          light = "lotus",
        },
      })
    end,
  },

  -- 🔭 TELESCOPE SELECTOR
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>ct",
        function()
          require("telescope.builtin").colorscheme({
            enable_preview = true,
            attach_mappings = function(prompt_bufnr, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- Usar el comando :Theme para guardar y aplicar
                vim.cmd("Theme " .. selection.value)
              end)
              return true
            end,
            include = {
              "aura-dark",
              "aura-soft-dark",
              "aura-dark-soft-text",
              "everforest",
              "catppuccin-frappe",
              "catppuccin-mocha",
              "catppuccin-macchiato",
              "catppuccin-latte",
              "gruvbox",
              "oasis",
              "oasis-lagoon",
              "oasis-night",
              "tokyonight",
              "tokyonight-night",
              "tokyonight-moon",
              "neon",
              "kanagawa",
              "kanagawa-wave",
              "kanagawa-dragon",
              "kanagawa-lotus",
              "pywal",
            },
          })
        end,
        desc = "Cambiar colorscheme con preview",
      },
    },
  },

  -- 🌫️ SISTEMA DE OPACIDAD 50%/100% (tu versión funcional restaurada)
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
    priority = 100, -- Carga al final
    config = function()
      -- 🧊 CONFIGURACIÓN DE TERMINAL (Windows Terminal Blur)
      local function toggle_terminal_blur(enable_blur)
        if vim.fn.has("win32") == 0 then return end -- Solo en Windows nativo

        local settings_path = "C:/Users/Diego/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

        -- Script PowerShell para conmutar opacidad y acrylic
        local ps_cmd
        if enable_blur then
          ps_cmd = string.format([[pwsh -NoProfile -Command "$c = Get-Content '%s' -Raw; $c = $c -replace '\"opacity\":\s*\d+', '\"opacity\": 1'; $c = $c -replace '\"useAcrylic\":\s*false', '\"useAcrylic\": true'; Set-Content '%s' $c"]], settings_path, settings_path)
        else
          ps_cmd = string.format([[pwsh -NoProfile -Command "$c = Get-Content '%s' -Raw; $c = $c -replace '\"opacity\":\s*\d+', '\"opacity\": 90'; $c = $c -replace '\"useAcrylic\":\s*true', '\"useAcrylic\": false'; Set-Content '%s' $c"]], settings_path, settings_path)
        end

        -- Ejecutar en segundo plano para no bloquear
        vim.fn.jobstart(ps_cmd)
      end

      -- Estados internos
      vim.g.background_opacity = 4 -- Opacidad de Neovim (4 = 100% trans, 2 = 50% color)
      vim.g.terminal_blur_enabled = 0 -- Blur de Windows Terminal (0 = Off, 1 = On)

      -- Obtener color de fondo según el tema activo (Dinámico)
      local function get_theme_background_color()
        -- Intentar obtener el color Normal actual
        local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
        if normal.bg then
          return string.format("#%06x", normal.bg)
        end
        return "#000000"
      end

      -- Aplicar opacidad (sin spam de notificaciones)
      local function apply_background_opacity(show_notification)
        local groups = {
          "Normal",
          "NormalNC",
          "NormalFloat",
          "SignColumn",
          "MsgArea",
          "MsgSeparator",
          "FloatBorder",
          "TelescopeNormal",
          "TelescopeBorder",
          "Pmenu",
          "PmenuSel",
          "NonText",
          "Whitespace",
          "EndOfBuffer",
        }

        local current_opacity = vim.g.background_opacity

        if current_opacity == 4 then
          -- 100% Transparente
          for _, g in ipairs(groups) do
            pcall(function()
              local current = vim.api.nvim_get_hl(0, { name = g })
              vim.api.nvim_set_hl(0, g, {
                fg = current.fg,
                bg = "none",
                blend = 0,
              })
            end)
          end
          if show_notification then
            vim.notify("🌫️  Opacidad: Transparente (100%)", vim.log.levels.INFO)
          end
        elseif current_opacity == 2 then
          -- 50% Opacidad con blend
          local bg_color = get_theme_background_color()

          for _, g in ipairs(groups) do
            pcall(function()
              local current = vim.api.nvim_get_hl(0, { name = g })
              vim.api.nvim_set_hl(0, g, {
                fg = current.fg,
                bg = bg_color,
                blend = 50,
              })
            end)
          end
          if show_notification then
            vim.notify("🎨 Opacidad: 50%", vim.log.levels.INFO)
          end
        end
      end

      -- Función 1: Solo Opacidad de Neovim (Highlights)
      local function toggle_background_opacity()
        if vim.g.background_opacity == 2 then
          vim.g.background_opacity = 4
        else
          vim.g.background_opacity = 2
        end
        apply_background_opacity(true)
      end

      -- Función 2: Solo Blur de Windows Terminal (External)
      local function toggle_windows_terminal_blur()
        if vim.g.terminal_blur_enabled == 1 then
          vim.g.terminal_blur_enabled = 0
          toggle_terminal_blur(false)
          vim.notify("🚫 Terminal Blur: DESACTIVADO", vim.log.levels.INFO)
        else
          vim.g.terminal_blur_enabled = 1
          toggle_terminal_blur(true)
          vim.notify("✨ Terminal Blur: ACTIVADO", vim.log.levels.INFO)
        end
      end

      -- Exportar funciones globalmente
      vim.g.apply_background_opacity = function()
        apply_background_opacity(false)
      end
      vim.g.toggle_background_opacity = toggle_background_opacity
      vim.g.get_theme_background_color = get_theme_background_color

      -- Atajos de teclado
      -- Opacidad (Neovim)
      vim.keymap.set("n", "<C-o>", toggle_background_opacity, { desc = "Toggle opacidad Neovim (50%/100%)" })
      vim.keymap.set("i", "<C-o>", toggle_background_opacity, { desc = "Toggle opacidad Neovim (50%/100%)" })
      vim.keymap.set("n", "<leader>pr", toggle_background_opacity, { desc = "Toggle opacidad Neovim" })

      -- Blur (Windows Terminal)
      vim.keymap.set("n", "<leader>cb", toggle_windows_terminal_blur, { desc = "Toggle Blur en Windows Terminal" })
      vim.keymap.set("n", "<leader>co", toggle_windows_terminal_blur, { desc = "Toggle Blur en Windows Terminal" })

      -- Auto-aplicar al cambiar colorscheme
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.defer_fn(function()
            apply_background_opacity(false) -- Sin notificación
          end, 100)
        end,
      })

      -- 🎨 ACTIVAR/CAMBIAR TEMA POR DEFECTO (después de cargar todo)
      vim.defer_fn(function()
        local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
        local saved_theme = default_theme

        local file = io.open(theme_file, "r")
        if file then
          saved_theme = file:read("*line"):gsub("^%s*(.-)%s*$", "%1")
          file:close()
        end

        local ok = pcall(function()
          vim.cmd([[colorscheme ]] .. saved_theme)
        end)

        if not ok then
          vim.notify("⚠️  Tema '" .. saved_theme .. "' no disponible", vim.log.levels.WARN)
          saved_theme = "oasis-lagoon"
          vim.cmd.colorscheme(saved_theme)
        end

        -- IMPORTANTE: Forzar vim.g.colors_name
        vim.g.colors_name = saved_theme
        -- Aplicar opacidad inicial

        apply_background_opacity(false)
      end, 50)
      -- 🎨 COMANDO :Theme <nombre> - Cambiar y guardar tema
      vim.api.nvim_create_user_command("Theme", function(opts)
        local theme = opts.args

        -- Aplicar tema
        local ok = pcall(function()
          vim.cmd([[colorscheme ]] .. theme)
        end)

        if ok then
          -- Guardar en archivo para persistencia
          local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
          local file = io.open(theme_file, "w")
          if file then
            file:write(theme)
            file:close()
          end

          -- IMPORTANTE: Forzar vim.g.colors_name (para Pywal)
          vim.g.colors_name = theme

          -- Reaplicar opacidad
          apply_background_opacity(false)
          vim.notify("✅ Tema guardado: " .. theme, vim.log.levels.INFO)
        else
          vim.notify("❌ Tema no encontrado: " .. theme, vim.log.levels.ERROR)
        end
      end, {
        nargs = 1,
        complete = function()
          return {
            "aura-dark",
            "aura-soft-dark",
            "everforest",
            "catppuccin-frappe",
            "catppuccin-mocha",
            "gruvbox",
            "oasis",
            "oasis-lagoon",
            "tokyonight",
            "tokyonight-night",
            "tokyonight-moon",
            "neon",
            "kanagawa",
            "kanagawa-wave",
            "kanagawa-dragon",
            "kanagawa-lotus",
            "pywal",
          }
        end,
        desc = "Cambiar y guardar colorscheme",
      })

      -- 🔧 Función global para leer tema guardado (para Pywal)
      vim.g.get_saved_theme = function()
        local theme_file = vim.fn.stdpath("config") .. "/theme.txt"
        local file = io.open(theme_file, "r")
        if file then
          local theme = file:read("*line"):gsub("^%s*(.-)%s*$", "%1")
          file:close()
          return theme
        end
        return default_theme
      end
    end,
  },
}

