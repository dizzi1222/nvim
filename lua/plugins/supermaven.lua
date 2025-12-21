-- Archivo: .config/nvim/lua/plugins/supermaven.lua

-- 🐐🗣️🔥️✍️ NO REQUIERE API: es completamente gratis
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/plugins/copilot.lua [opcional usa copilot-chat.lua]
--   - .config/nvim/lua/plugins/supermaven.lua {etc..}
--
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua--
-- ACTIVAS SUPERMAVEn FREE CON: :SupermavenUseFree
return {
  "supermaven-inc/supermaven-nvim", -- ¡IMPORTANTE! Nuevo repositorio
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
        -- El keymap 'dismiss_suggestion' ya no se menciona en la config por defecto,
        -- pero puedes mantenerlo si lo necesitas, o usar la opción por defecto si existe.
      },
      ignore_filetypes = { cpp = true },
      color = {
        suggestion_color = "#595959", -- Manteniendo tu color anterior
        blend = 20, -- blend ya no aparece en el ejemplo de configuración, revisa si aún es soportado.
        cterm = 244,
      },
      log_level = "info",
      disable_inline_completion = false,
      disable_keymaps = false,
      condition = function()
        return false -- El valor por defecto ahora es usar `require("supermaven-nvim").setup({})`
        -- y la lógica condicional se define en el `condition`
      end,
    })
  end,
}
