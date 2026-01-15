-- 🐐🗣️🔥️✍️  NO REQUIERE API. [lo usa gil] Pero no me gusta tanto como copilot, o supermaven como IAS gratuitas para sugerencias]
-- ✍️ Activar con:
-- TabnineLoginWithAuthToken
-- Luego abre el browser, logeas con github, y pegas tu token [eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJodHRwczovL2lkZW50aXR5dG9vbGtpdC5nb29nbGVhcGlzLmNvbS9nb29nbGUuaWRlbnRpdHkuaWRlbnRpdHl0b29sa2l0LnYxLklkZW50aXR5VG9vbGtpdCIsImlhdCI6MTc2NzI3NDU2OCwiZXhwIjoxNzY3Mjc4MTY4LCJpc3MiOiJmaXJlYmFzZS1hZG1pbnNkay02cjM0eUB0YWJuaW5lLWF1dGgtMzQwMDE1LmlhbS5nc2VydmljZWFjY291bnQuY29tIiwic3ViIjoiZmlyZWJhc2UtYWRtaW5zZGstNnIzNHlAdGFibmluZS1hdXRoLTM0MDAxNS5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsInVpZCI6Ik1PQzJTQVN3bTRjQjBDOE9pb2llT1NhRnFEcDIifQ.R_TdpQalfmzLlbjbmHn8P_IyQZom4DaQtzEjI4FNiG4Uf-6P1gjjMCiN2UDRQmscQs3Qv7PJye0nzBsLmWCObff3itNI50offqmN8uwleUGA1qSkf6Qt24nIvVny178dLj1bLEo1PJrMt77He712OfkGFwNpiUV-ktvygAynug3fyYehcKZCxCRzBjm3AzZlFF6jwvKq4zWxsuxsvGiQRBdA6ap8HpeszI7iWeJVtc-x8u2sJlzdWTkJcCWItTXcE-0PF0E8F1CU0mRbDAlyrkuYQFq1eNUAzzYpKZ2t2fBb4zuWlaSe4iBBOrrgj7NwqfIe9XQzFcLv64Oislfe8w]-
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
--
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/plugins/copilot.lua [opcional usa copilot-chat.lua]
--   - .config/nvim/lua/plugins/supermaven.lua {etc..}
--
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua--
--
return {
  -- // Esta extension es la que da problemas al usar Ctrl+O, pero da sugerencias AI
  "codota/tabnine-nvim",
  build = "./dl_binaries.sh",
  config = function()
    require("tabnine").setup({
      disable_auto_comment = true,
      accept_keymap = "<Tab>",
      dismiss_keymap = "<C-]>",
      accept_word = "<C-Enter>", -- antes estaba como C-j
      debounce_ms = 800,
      suggestion_color = { gui = "#808080", cterm = 244 },
      exclude_filetypes = { "TelescopePrompt", "NvimTree" },
      log_file_path = nil, -- absolute path to Tabnine log file
      ignore_certificate_errors = false,
      -- workspace_folders = {
      --   paths = { "/your/project" },
      --   get_paths = function()
      --       return { "/your/project" }
      --   end,
      -- },
    })
  end,
}
