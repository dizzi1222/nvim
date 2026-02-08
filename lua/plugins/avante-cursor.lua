-- 💸💳💰REQUIERE API. USA : AvanteSwitchProvider ollama | consigue tu key en https://www.avantelabs.ai (MEJOR QUE CURSOR)
--  Puedes hacer el trucazo de usar OLLAMA local cloud con API gratuita.🐐
return {
  {
    "yetone/avante.nvim",
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    build = function()
      -- Verifica si los templates existen
      local avante_dir = vim.fn.expand("~/.local/share/nvim/lazy/avante.nvim")
      local templates_so = avante_dir .. "/dist/avante_templates.so"

      -- Si faltan los templates, compila automáticamente
      if vim.fn.filereadable(templates_so) == 0 then
        if vim.fn.has("win32") == 1 then
          return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        else
          return "make"
        end
      end
    end,
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = function(_, opts)
      -- Track avante's internal state during resize
      local in_resize = false
      local original_cursor_win = nil
      local avante_filetypes = { "Avante", "AvanteInput", "AvanteAsk", "AvanteSelectedFiles" }

      -- Check if current window is avante
      local function is_in_avante_window()
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")

        for _, avante_ft in ipairs(avante_filetypes) do
          if ft == avante_ft then
            return true, win, ft
          end
        end
        return false
      end

      -- Temporarily move cursor away from avante during resize
      local function temporarily_leave_avante()
        local is_avante, avante_win, avante_ft = is_in_avante_window()
        if is_avante and not in_resize then
          in_resize = true
          original_cursor_win = avante_win

          -- Find a non-avante window to switch to
          local target_win = nil
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")

            local is_avante_ft = false
            for _, aft in ipairs(avante_filetypes) do
              if ft == aft then
                is_avante_ft = true
                break
              end
            end

            if not is_avante_ft and vim.api.nvim_win_is_valid(win) then
              target_win = win
              break
            end
          end

          -- Switch to non-avante window if found
          if target_win then
            vim.api.nvim_set_current_win(target_win)
            return true
          end
        end
        return false
      end

      -- Restore cursor to original avante window
      local function restore_cursor_to_avante()
        if in_resize and original_cursor_win and vim.api.nvim_win_is_valid(original_cursor_win) then
          -- Small delay to ensure resize is complete
          vim.defer_fn(function()
            pcall(vim.api.nvim_set_current_win, original_cursor_win)
            in_resize = false
            original_cursor_win = nil
          end, 50)
        end
      end

      -- Prevent duplicate windows cleanup
      local function cleanup_duplicate_avante_windows()
        local seen_filetypes = {}
        local windows_to_close = {}

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")

          -- Special handling for Ask and Select Files panels
          if ft == "AvanteAsk" or ft == "AvanteSelectedFiles" then
            if seen_filetypes[ft] then
              -- Found duplicate, mark for closing
              table.insert(windows_to_close, win)
            else
              seen_filetypes[ft] = win
            end
          end
        end

        -- Close duplicate windows
        for _, win in ipairs(windows_to_close) do
          if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end

      -- Create autocmd group for resize fix AND template detection
      vim.api.nvim_create_augroup("AvanteResizeFix", { clear = true })

      -- 🔨 Auto-compile templates si faltan
      vim.api.nvim_create_augroup("AvanteTemplateCheck", { clear = true })
      vim.api.nvim_create_autocmd("VimEnter", {
        group = "AvanteTemplateCheck",
        callback = function()
          local avante_dir = vim.fn.expand("~/.local/share/nvim/lazy/avante.nvim")
          local templates_so = avante_dir .. "/dist/avante_templates.so"

          -- Si faltan los templates, compila automáticamente
          if vim.fn.filereadable(templates_so) == 0 then
            vim.notify("📦 Avante templates faltantes. Compilando automáticamente...", vim.log.levels.WARN)
            vim.fn.system("cd " .. avante_dir .. " && bash build.sh")
            vim.notify("✅ Avante compilado correctamente. Reinicia Neovim.", vim.log.levels.INFO)
          end
        end,
      })

      -- Main resize handler for Resize
      vim.api.nvim_create_autocmd({ "VimResized" }, {
        group = "AvanteResizeFix",
        callback = function()
          -- Move cursor away from avante before resize processing
          local moved = temporarily_leave_avante()

          if moved then
            -- Let resize happen, then restore cursor
            vim.defer_fn(function()
              restore_cursor_to_avante()
              -- Force a clean redraw
              vim.cmd("redraw!")
            end, 100)
          end

          -- Cleanup duplicates after resize completes
          vim.defer_fn(cleanup_duplicate_avante_windows, 150)
        end,
      })

      -- Prevent avante from responding to scroll/resize events during resize
      vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized" }, {
        group = "AvanteResizeFix",
        pattern = "*",
        callback = function(args)
          local buf = args.buf
          if buf and vim.api.nvim_buf_is_valid(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")

            for _, avante_ft in ipairs(avante_filetypes) do
              if ft == avante_ft then
                -- Prevent event propagation for avante buffers during resize
                if in_resize then
                  return true -- This should stop the event
                end
                break
              end
            end
          end
        end,
      })

      -- Additional cleanup on focus events
      vim.api.nvim_create_autocmd("FocusGained", {
        group = "AvanteResizeFix",
        callback = function()
          -- Reset resize state on focus gain
          in_resize = false
          original_cursor_win = nil
          -- Clean up any duplicate windows
          vim.defer_fn(cleanup_duplicate_avante_windows, 100)
        end,
      })

      return {
        -- 🎯 CONFIGURACIÓN BÁSICA
        --   ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
        ---@type Provider
        provider = "claude", -- /o ollama -- Provider por defecto
        ---@alias Mode "agentic" | "legacy"
        ---@type Mode
        mode = "legacy", -- o/ agentic -- 󰄭 GEMINI, Claude, 󰄬 etc SOPORTAN agentic, OLLAMA NO 󰂭 -- The default mode for interaction. "agentic" uses tools to automatically generate code, "legacy" uses the old planning method to generate code.
        -- 🔕 SILENCIAR NOTIFICACIONES, etiquetas XLS?
        hints = {
          enabled = true, -- Desactiva hints que pueden mostrar XML
        },

        -- 📝 Archivo de instrucciones del proyecto
        instructions_file = "avante.md",

        -- 🤖 CONFIGURACIÓN DE PROVIDERS (SIN DEPRECATED WARNINGS)
        providers = {
          --   OLLAMA - Local y gratuito 󰎣
          ollama = {
            priority = 1,
            endpoint = "127.0.0.1:11434", -- Sin /v1
            model = "deepseek-v3.2:cloud", -- Tu modeloAvanteSwitchProvider deepseek
            timeout = 30000,
            mode = "legacy", -- ✅ CRÍTICO, "agentic" causa crashes
            disable_tools = true, -- 🔥 Agregar esto
            -- api_key_name = "OLLAMA-API-KEY", -- NO necesitas api_key_name para Ollama local
          },
          -- GEMIMI-CLI 󰊭    OLLAMA 🐐 = LOS UNICOS MODELOS GRATIS DE AVANTE 🐐 󰸞 .
          ["gemini-cli-dizzi"] = {
            __inherited_from = "openai",
            api_key_name = "GEMINI_API_KEY",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/openai/",
            model = "gemini-2.0-flash-exp", -- ✅ Modelo correcto para API OpenAI-compatible
            timeout = 30000,
            mode = "legacy",
            disable_tools = true, -- 🔥 Agregar esto
          },
          --  GEMINI - API gratuita 💸🐐
          gemini = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.0-flash-exp",
            api_key_name = "GEMINI_API_KEY", -- ✅ NOMBRE DE VARIABLE, NO PATH
            mode = "agentic", -- USA Tools para GEMINI
            disable_tools = true, -- 🔥 Agregar esto
            timeout = 30000,
            -- La API key se lee de GEMINI_API_KEY o AVANTE_GEMINI_API_KEY
          },
          --  DeepSeek - GRATIS y POTENTE 🚀💸🐐
          deepseek = {
            priority = 2,
            __inherited_from = "openai", -- ✅ IMPORTANTE: Hereda de OpenAI
            endpoint = "https://api.deepseek.com",
            model = "deepseek-chat", -- No-thinking mode (más rápido)
            -- model = "deepseek-reasoner", -- Thinking mode (como Claude)
            timeout = 30000,
            mode = "agentic", -- USA Tools para DeepSeek
            disable_tools = true, -- 🔥 Agregar esto
            api_key_name = "DEEPSEEK_API_KEY", -- ✅ NOMBRE DE VARIABLE, NO PATH
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4096, -- Lo baje de 8192
            },
          },

          --  CLAUDE - Pago 💀☠️ (SIN deprecated warnings)
          claude = {
            priority = 1,
            endpoint = "https://api.anthropic.com",
            model = "claude-sonnet-4-20250514", -- O;  claude-3-5-haiku-20241022 / "claude-3-5-sonnet-20241022" / claude-3-opus-20240229 -- Modelo actualizado
            auth_type = "max", -- 🔥 Usa tu suscripción >>> [NO REQUIERE API KEY, CLAUDE CODE] 🐐.
            timeout = 30000,
            -- api_key_name = "ANTHROPIC_API_KEY", --  🔥 Desactivalo si usas suscripción  󰀦
            mode = "agentic", -- USA Tools para Claude
            disable_tools = true, -- 🔥 Agregar esto
            -- ✅ Usar extra_request_body para evitar warnings
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 4096, -- Lo baje de 20480
            },
          },

          --   COPILOT - Pago 💀☠️
          copilot = {
            model = "claude-sonnet-4",
            mode = "agentic", -- USA Tools para Copilot
            disable_tools = true, -- 🔥 Agregar esto
            -- Totalmente de PAGO
          },
          openrouter = {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "qwen/qwen3-coder:free",
            mode = "legacy", -- USA Tools para OpenRouter
            disable_tools = true, -- 🔥 Agregar esto
            -- model = "deepseek/deepseek-chat-v3-0324:free",
            -- model = "deepseek/deepseek-r1-0528:free",
            api_key_name = "OPEN_ROUTER_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 32768,
            },
          },
        },
        cursor_applying_provider = "claude", -- "copilot", "claude", ""
        auto_suggestions_provider = "claude", -- "copilot", "claude", ""
        --  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀 
        ---Note: This is an experimental feature and may not work as expected.
        dual_boost = {
          enabled = false,
          first_provider = "ollama",
          second_provider = "claude", -- "deepseek", "gemini-cli"
          -- prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
          prompt = "Habla Español,Based on the two reference outputs below, generate a response. Do not provide any explanation, just give the response. Este GPT es un clon del usuario, un arquitecto líder frontend especializado en Angular y React, con experiencia en arquitectura limpia, arquitectura hexagonal y separación de lógica en aplicaciones escalables. Tiene un enfoque técnico pero práctico, con explicaciones claras y aplicables, siempre con ejemplos útiles para desarrolladores con conocimientos intermedios y avanzados.\n\nHabla con un tono profesional pero cercano, relajado y con un toque de humor inteligente. Evita formalidades excesivas y usa un lenguaje directo, técnico cuando es necesario, pero accesible. Su estilo es argentino, sin caer en clichés, y utiliza expresiones como 'buenas acá estamos' o 'dale que va' según el contexto.\n\nSus principales áreas de conocimiento incluyen:\n- Desarrollo frontend con Angular, React y gestión de estado avanzada (Redux, Signals, State Managers propios como Gentleman State Manager y GPX-Store).\n- Arquitectura de software con enfoque en Clean Architecture, Hexagonal Architecure y Scream Architecture.\n- Implementación de buenas prácticas en TypeScript, testing unitario y end-to-end.\n- Loco por la modularización, atomic design y el patrón contenedor presentacional \n- Herramientas de productividad como LazyVim, Tmux, Zellij, OBS y Stream Deck.\n- Mentoría y enseñanza de conceptos avanzados de forma clara y efectiva.\n- Liderazgo de comunidades y creación de contenido en YouTube, Twitch y Discord.\n\nA la hora de explicar un concepto técnico:\n1. Explica el problema que el usuario enfrenta.\n2. Propone una solución clara y directa, con ejemplos si aplica.\n3. Menciona herramientas o recursos que pueden ayudar.\n\nSi el tema es complejo, usa analogías prácticas, especialmente relacionadas con construcción y arquitectura. Si menciona una herramienta o concepto, explica su utilidad y cómo aplicarlo sin redundancias.\n\nAdemás, tiene experiencia en charlas técnicas y generación de contenido. Puede hablar sobre la importancia de la introspección. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
          timeout = 60000, -- Timeout in milliseconds
        },
        -- FIN -  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀  - FIN

        -- 🎨 COMPORTAMIENTO
        behaviour = {
          enable_cursor_planning_mode = true,
          auto_suggestions = false, -- Desactiva auto-sugerencias CHOCA con OLLAMA  .
          disable_tools = true, -- 🔥 Esto desactiva tools para TODOS los providers
          minimize_diff = true, -- ✅ Agregá esto para el minimizado de diff [RENDERIZADO]
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          support_paste_from_clipboard = true,
        },
        -- File selector configuration
        --- @alias FileSelectorProvider "native" | "fzf" | "mini.pick" | "snacks" | "telescope" | string
        file_selector = {
          provider = "snacks", -- Avoid native provider issues
          provider_opts = {},
        },
        --  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀 
        mappings = {
          --- @class AvanteConflictMappings
          diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "]x",
            prev = "[x",
          },
          suggestion = {
            accept = "<M-l>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
          jump = {
            next = "]]",
            prev = "[[",
          },
          submit = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          cancel = {
            normal = { "<C-c>", "<Esc>", "q" },
            insert = { "<C-c>" },
          },
          sidebar = {
            apply_all = "A",
            apply_cursor = "a",
            retry_user_request = "r",
            edit_user_request = "e",
            switch_windows = "<Tab>",
            reverse_switch_windows = "<S-Tab>",
            remove_file = "d",
            add_file = "@",
            close = { "<Esc>", "q" },
            close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
          },
        },
        selection = {
          enabled = true,
          hint_display = "delayed",
        },
        -- FIN -  CONFIGURACION NUEVA EXPERIMENTAL!! 🚀  - FIN
        -- 🪟 CONFIGURACIÓN DE VENTANAS
        windows = {
          ---@type "right" | "left" | "top" | "bottom" | "smart"
          position = "left", -- the position of the sidebar
          wrap = true, -- similar to vim.o.wrap
          width = 30, -- default % based on available width
          sidebar_header = {
            enabled = true, -- true, false to enable/disable the header
            align = "center", -- left, center, right for title
            rounded = false,
          },
          input = {
            prefix = "> ",
            height = 8, -- Height of the input window in vertical layout
          },
          edit = {
            start_insert = true, -- Start insert mode when opening the edit window
          },
          ask = {
            floating = false, -- Open the 'AvanteAsk' prompt in a floating window
            start_insert = true, -- Start insert mode when opening the ask window
            ---@type "ours" | "theirs"
            focus_on_apply = "ours", -- which diff to focus after applying
          },
          -- ✅ AGREGAR render_markdown config:
          render_markdown = {
            enabled = true,
            file_types = { "Markdown", "Norg", "Rmd", "Org", "Vimwiki", "Avante", "AvanteInput", "AvanteAsk" },
          },
        },
        -- 🎭 SYSTEM PROMPT PERSONALIZADO (Opcional)
        system_prompt = "Este GPT es un clon del usuario, un arquitecto líder frontend especializado en Angular y React, con experiencia en arquitectura limpia, arquitectura hexagonal y separación de lógica en aplicaciones escalables. Tiene un enfoque técnico pero práctico, con explicaciones claras y aplicables, siempre con ejemplos útiles para desarrolladores con conocimientos intermedios y avanzados.\n\nHabla con un tono profesional pero cercano, relajado y con un toque de humor inteligente. Evita formalidades excesivas y usa un lenguaje directo, técnico cuando es necesario, pero accesible. Su estilo es argentino, sin caer en clichés, y utiliza expresiones como 'buenas acá estamos' o 'dale que va' según el contexto.\n\nSus principales áreas de conocimiento incluyen:\n- Desarrollo frontend con Angular, React y gestión de estado avanzada (Redux, Signals, State Managers propios como Gentleman State Manager y GPX-Store).\n- Arquitectura de software con enfoque en Clean Architecture, Hexagonal Architecure y Scream Architecture.\n- Implementación de buenas prácticas en TypeScript, testing unitario y end-to-end.\n- Loco por la modularización, atomic design y el patrón contenedor presentacional \n- Herramientas de productividad como LazyVim, Tmux, Zellij, OBS y Stream Deck.\n- Mentoría y enseñanza de conceptos avanzados de forma clara y efectiva.\n- Liderazgo de comunidades y creación de contenido en YouTube, Twitch y Discord.\n\nA la hora de explicar un concepto técnico:\n1. Explica el problema que el usuario enfrenta.\n2. Propone una solución clara y directa, con ejemplos si aplica.\n3. Menciona herramientas o recursos que pueden ayudar.\n\nSi el tema es complejo, usa analogías prácticas, especialmente relacionadas con construcción y arquitectura. Si menciona una herramienta o concepto, explica su utilidad y cómo aplicarlo sin redundancias.\n\nAdemás, tiene experiencia en charlas técnicas y generación de contenido. Puede hablar sobre la importancia de la introspección, có...",
      }
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- Opcional pero recomendado
      "nvim-tree/nvim-web-devicons",

      -- Desactivo markdown para usar MARKVIEW sin eliminar el plugin
      {
        "MeanderingProgrammer/render-markdown.nvim",
        lazy = false, -- ← NO lazy loading
        priority = 1000, -- ← Carga antes que Avante
        dependencies = { "folke/snacks.nvim" }, -- ← Dependencia explícita
        opts = {
          file_types = { "markdown", "Avante", "AvanteInput" },
          render_modes = { "n", "c", "i" }, -- ✅ Renderizar en todos los modos
          anti_conceal = {
            enabled = false, -- ✅ Evita que oculte caracteres
          },
          -- ✅ NO pongas anti_conceal aquí
        },
      },
      -- [Indexado ] Soporte para pegar imágenes
    },
  },
}
