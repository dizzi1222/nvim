-- /042 󰢱  disabled.lua
-- SOLO PUEDES USAR COPILOT || SUPERMAVEN || TABNINE || Para autocompletar TEXTO!!!
-- ESTE ARCHIVO ES MANEJADO APARTE CON: Space + D / A+D [ de forma externa]
-- lua/utils/plugin-switcher.lua
return {
  {
    -- Plugin: bufferline.nvim
    -- URL: https://github.com/akinsho/bufferline.nvim
    -- Description: A snazzy buffer line (with tabpage integration) for Neovim.
    "akinsho/bufferline.nvim",
    enabled = true, -- Disable this plugin
  },
  -- 󰨞  󰇀 Cursor,Antigravity & VSCODE = Avante AI Plugins for Neovim  .
  {
    -- Plugin para mejorar la experiencia de edición en Neovim
    -- URL: https://github.com/yetone/avante.nvim
    -- Description: Este plugin ofrece una serie de mejoras y herramientas para optimizar la edición de texto en Neovim.
    "yetone/avante.nvim", -- 8/10 | Codeium: 2/10
    enabled = true, -- Integrado a NVIM, pocos modelos gratis,pero Ollama deepseek-cloud Clave, interfaz god, sugerencias like cursor
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = true, -- AVANTE NECESITA EL MARKDOWN PARA EL RENDEREIZADO XLM/XLS html
  },
  {
    "OXY2DEV/markview.nvim",
    enabled = true,
  },
  -- REMPLAZADO POR MARKVIEW
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
  --  Copilot AI Plugins for Neovim  ..
  -- {
  --   "CopilotC-Nvim/CopilotChat.nvim", -- 1/10 | Codeium: 2/10
  --   enabled = false, --     no funciona "Thinking..."
  -- },
  -- Autocompletion AI Plugins for Neovim   Suggestions, Completions... 󰓅 .[pls add Tab]
  {
    "zbirenbaum/copilot.lua", -- 6/10
    enabled = true, -- Buen autocompletado, Lo unico gratis de COPILOT  .
  },
  {
    "tris203/precognition.nvim",
    enabled = true,
  },
  {
    "supermaven-nvim", -- 9/10 | Codeium: 2/10
    enabled = true, -- Muy buen autocompletado, aunque le falte contexto general, recuerda conversaciones pasadas. GRATIS
  },
  -- {
  --   "codota/tabnine-nvim", -- 1/10 | Codeium: 2/10
  --   enabled = false, -- el autocompletado es mierda (no me funciona), y requiere app externa :/
  -- },
  --  󱝆 Codeium / Windsurf Plugins for Neovim  .
  {
    "Exafunction/windsurf.nvim", -- 7.5/10 Codeium: 3/10 [autocritica!?]
    enabled = true, -- Buen autocompletado, Lo unico gratis de WINDSURF  . Lo del Webchat esta curioso, novedoso, es como tener un Opwenweb ui mas nerfeado.
  },
  -- 󰙯 Discord Presence plugin's for Neovim  .
  {
    "andweeb/presence.nvim",
    enabled = true, -- Este es funcional
  },
  -- {
  --   "vyfor/cord.nvim",
  --   enabled = false,
  -- },

  { "folke/snacks.nvim", enabled = true }, -- SI NEOVIM / LAZY / UI FALLA, DESACtIVA ESTO.
  -- 󰮮 Opencode AI Plugins for Neovim 
  -- SOLO PUEDES USAR UNO DE LOS 2, DEBES DE SELECCIONAR UNO CON: Space + D / A+D
  -- {
  --   "NickvanDyke/opencode.nvim", -- 1. El Opencode-CLI mas comodo
  --   name = "opencode-nick", -- 9.5/10
  --   enabled = true, -- Una cantidad bastante generosa de modelos gratis, ollama facil de configurar, Login y configurar APIS nunca fue tan facil en OPENCODE 󰮮 .
  -- },
  -- {
  --   "sudo-tee/opencode.nvim", -- 2. Integrado en el chat de NVIM rapido
  --   name = "opencode-sudo", -- 7/10
  --   enabled = false, -- Lo mismo pero integrado a NEOVIM [Like Avante], No me convence, pero ta god, es OPENCODE 󰮮 .
  -- },
  -- {
  --   "olimorris/codecompanion.nvim", -- 4/10 | Codeium: 2/10
  --   enabled = false, -- Respet por ser casi lo 1ro y la comodidad de la caja de Prompts que paso a ser lo habitual en los plugins. Integrado a NEOVIM  .
  -- },
  --  Claude-code AI assistant for Neovim  .
  -- {
  --   -- 1. [NEW] Plugin: mejor claude-code:
  --   "coder/claudecode.nvim", -- 5/10
  --   enabled = false, -- Es de PAGO, pero sin poder afirmarlo, Claude-code sea lo mejor [10/10].
  -- },
  -- {
  --   -- 2. OLD Claude-code
  --   -- Plugin: claude-code.nvim
  --   -- URL: https://github.com/greggh/claude-code.nvim
  --   -- Description: Neovim integration for Claude Code AI assistant
  --   "greggh/claude-code.nvim", -- 4/10
  --   enabled = false, -- Es de PAGO, pero sin poder afirmarlo, Claude-code sea lo mejor [10/10].
  -- },
  -- {
  -- 0. 󰊭 Prefiero usar mi config de Gemini-cli
  { "jonroosevelt/gemini-cli.nvim", -- 3/10
  enabled = false, -- Gratuito, pero el Modo Plan no existe, la implementacion del codigo no existe, y hasta yo hice una mejor config de Gemini-cli 󰊭 .
   },
  --  MCPHUB  - Requiere APIKEY DE COPILOT permantente o 30 dias
  { "ravitemer/mcphub.nvim", enabled = true },
  {
    "sphamba/smear-cursor.nvim",
    enabled = true,
  },
  -- { "obsidian-nvim/obsidian.nvim", enabled = false },
  -- { "nvim-lua/plenary.nvim", enabled = false }, -- ESTO ES VITAL! 💀
}
