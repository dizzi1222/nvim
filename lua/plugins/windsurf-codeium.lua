-- 🐐🗣️🔥️✍️ NO REQUIERE API  USA:Copilot auth  | Se activa al entrar en insert, AUTOCOMPLETADO 󰄭 .|USA:Codeium Auth
return {
  "Exafunction/codeium.nvim", -- Nombre correcto del plugin
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
  },
  event = "InsertEnter",
  config = function()
    -- 🔧 FIX: Detectar si Avante está activo y desactivar Codeium
    local function is_avante_buffer()
      local ft = vim.bo.filetype
      return ft == "Avante" or ft == "AvanteInput" or ft == "AvanteAsk" or ft == "AvanteSelectedFiles" or ft == "avante"
    end
    -- 1. Configuración principal de Codeium
    require("codeium").setup({
      -- 🔇 SILENCIAR ERRORES DE CONEXIÓN
      on_attach = function(client, bufnr)
        -- Silenciar todos los logs de error
        client.config.flags = client.config.flags or {}
        client.config.flags.allow_incremental_sync = true
      end,

      -- Configurar handlers para ignorar errores
      handlers = {
        ["textDocument/publishDiagnostics"] = function() end, -- Silenciar diagnósticos
      },
      enable_chat = true,
      enable_cmp_source = true,
      detect_proxy = true,

      virtual_text = {
        enabled = true, -- Cambiado a true para ver sugerencias
        manual = false,
        idle_delay = 75,
        filetypes = {
          python = true,
          lua = true,
          javascript = true,
          typescript = true,
          java = true,
          go = true,
          rust = true,
          cpp = true,
          c = true,
          php = true,
          ruby = true,

          -- ❌ DESACTIVAR en buffers de Avante
          Avante = false,
          AvanteInput = false,
          AvanteAsk = false,
          AvanteSelectedFiles = false,
          avante = false,
        },
        default_filetype_enabled = true,
        key_bindings = {
          accept = "<Tab>",
          accept_word = "<C-Enter>", -- M-w
          -- suggestion_color = { gui = "#caa99b", cterm = 244 }, -- #808080
          accept_line = "<C-j>",
          clear = "<C-]>", -- C-e
          next = "<M-]>",
          prev = "<M-[>",
        },
      },

      workspace_root = {
        use_lsp = true,
        paths = {
          ".git",
          "package.json",
          "pyproject.toml",
          "Cargo.toml",
          "go.mod",
          "composer.json",
          "Gemfile",
          "requirements.txt",
        },
      },
    })

    --
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- 3. Atajos globales personalizados
    local keymap = vim.keymap.set

    -- Atajos en modo Normal
    keymap("n", "<leader>cL", "<Cmd>Codeium Auth<CR>", { desc = "   🔐 Login/Autenticar Codeium " })
    keymap("n", "<leader>aL", "<Cmd>Codeium Auth<CR>", { desc = "   🔐 Login/Autenticar Codeium " })
    keymap("n", "<leader>cT", "<Cmd>Codeium Toggle<CR>", { desc = "   🔄 Toggle/Activar Codeium " })
    keymap("n", "<leader>cT", "<Cmd>Codeium Toggle<CR>", { desc = "   🔄 Activar/Toggle Codeium " })
    keymap("n", "<leader>aT", "<Cmd>Codeium Toggle<CR>", { desc = "   🔄 Toggle/Activar Codeium " })
    keymap("n", "<leader>aT", "<Cmd>Codeium Toggle<CR>", { desc = "   🔄 Activar/Toggle Codeium " })
    keymap("n", "<leader>cs", "<Cmd>Codeium Status<CR>", { desc = "   📊 Estado Codeium " })
    keymap("n", "<leader>cw", "<Cmd>Codeium Chat<CR>", { desc = "  💬 Web/Api Chat Codeium " })
    keymap("n", "<leader>aw", "<Cmd>Codeium Chat<CR>", { desc = "    💬 Web/Api Chat Codeium " })

    -- 4. Configuración de LuaSnip
    require("luasnip.loaders.from_vscode").lazy_load()

    -- 5. Mensaje de bienvenida
    vim.schedule(function()
      if vim.fn.has("nvim-0.8") == 1 then
        -- print("✅ Codeium configurado correctamente")
        -- print("🎯 Atajos principales:")
        -- print("   <Tab> - Navegar/aceptar sugerencias")
        -- print("   <C-Space> - Forzar autocompletado")
        -- print("   <leader>ct - Toggle Codeium")
        -- print("   <leader>cc - Abrir chat")
      end
    end)
  end,
}
