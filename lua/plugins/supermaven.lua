-- 🐐🗣️🔥️✍️ NO REQUIERE API: es completamente gratis -- ✍️ Activar con:SupermavenUseFree | AUTOCOMPLETADO 󰄭 .
--
return {
  "supermaven-inc/supermaven-nvim", -- ¡IMPORTANTE! Nuevo repositorio
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-Enter>", -- antes estaba como C-j
        -- El keymap 'dismiss_suggestion' ya no se menciona en la config por defecto,
        -- pero puedes mantenerlo si lo necesitas, o usar la opción por defecto si existe.
      },
      ignore_filetypes = { cpp = true },
      color = {
        suggestion_color = "#caa99b", -- Manteniendo tu color anterior -- #808080
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
