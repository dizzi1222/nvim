-- ☄️ Markview.nvim - Markdown previewer que funciona con Avante
-- Basado en la configuración oficial de la wiki
return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- ⚠️ IMPORTANTE: No lazy load según la documentación oficial
  priority = 1000,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons", -- o "echasnovski/mini.icons"
  },
  opts = {
    -- ✅ Configuración según la wiki oficial
    -- https://github.com/OXY2DEV/markview.nvim/wiki/Configuration

    -- Experimental settings
    experimental = {
      date_formats = {},
      date_time_formats = {},
      file_open_command = nil,
      list_empty_line_tolerance = nil,
      prefer_nvim = nil,
      read_chunk_size = nil,
      linewise_ignore_org_indent = false,
    },

    -- HTML support
    html = {
      enable = true,
    },

    -- LaTeX support
    latex = {
      enable = true,
    },

    -- Markdown configuration
    markdown = {
      enable = true,
      -- Encabezados
      headings = {
        enable = true,
        shift_width = 1,
        heading_1 = {
          style = "icon",
          icon = "󰼏 ",
          sign = "① ",
        },
        heading_2 = {
          style = "icon",
          icon = "󰎨 ",
          sign = "② ",
        },
        heading_3 = {
          style = "icon",
          icon = "󰼑 ",
          sign = "③ ",
        },
        heading_4 = {
          style = "icon",
          icon = "󰎲 ",
          sign = "④ ",
        },
        heading_5 = {
          style = "icon",
          icon = "󰼓 ",
          sign = "⑤ ",
        },
        heading_6 = {
          style = "icon",
          icon = "󰎴 ",
          sign = "⑥ ",
        },
      },
      -- Code blocks
      code_blocks = {
        enable = true,
        style = "language",
        position = "overlay",
        min_width = 60,
        pad_amount = 1,
        pad_char = " ",
        language_direction = "right",
      },
      -- Listas
      list_items = {
        enable = true,
        indent_size = 2,
        shift_width = 2,
        marker_minus = {
          text = "●",
        },
        marker_plus = {
          text = "○",
        },
        marker_star = {
          text = "◆",
        },
      },
      -- Tablas
      tables = {
        enable = true,
        use_virt_lines = true,
      },
    },

    -- Markdown inline configuration
    markdown_inline = {
      enable = true,
      -- Inline code
      inline_codes = {
        enable = true,
        corner_left = " ",
        corner_right = " ",
        padding_left = " ",
        padding_right = " ",
      },
      -- Checkboxes (útil para Avante)
      checkboxes = {
        enable = true,
        checked = {
          text = "✔",
        },
        unchecked = {
          text = " ",
        },
        pending = {
          text = "◐",
        },
      },
      -- Links
      hyperlinks = {
        enable = true,
        icon = "󰌹 ",
      },
      -- Images
      images = {
        enable = true,
        icon = "󰥶 ",
      },
    },

    -- Preview configuration
    preview = {
      enable = true,
      -- ✅ CRÍTICO: Agregar Avante a los filetypes
      filetypes = { "markdown", "norg", "rmd", "org", "vimwiki", "Avante", "AvanteInput" },
      ignore_buftypes = {},
      ignore_previews = {},

      debounce = 100,
      icon_provider = "devicons", -- "mini" o "devicons"
      max_buf_lines = 99999,

      -- Modos de renderizado
      modes = { "n", "i", "c", "v" },
      hybrid_modes = { "i" },
      linewise_hybrid_mode = nil,
    },
  },
  config = function(_, opts)
    require("markview").setup(opts)

    -- ✅ Asegurar activación en buffers de Avante
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "Markdown", "Norg", "Rmd", "Org", "Vimwiki", "Avante", "AvanteInput", "AvanteAsk" },
      callback = function()
        -- Desactivar render-markdown si está cargado
        local ok, render_md = pcall(require, "render-markdown")
        if ok then
          -- Método correcto para desactivar
          pcall(function()
            render_md.disable()
          end)
        end

        -- Forzar activación de markview
        vim.cmd("Markview enableAll")
      end,
    })

    -- ✅ Keymap para toggle (según la wiki)
    -- Markview toggle (alternativo)
    vim.keymap.set("n", "<leader>mv", function()
      vim.cmd("Markview toggle")
      vim.notify("Markview toggled", vim.log.levels.INFO)
    end, { desc = "Toggle Markview" })
  end,
}
