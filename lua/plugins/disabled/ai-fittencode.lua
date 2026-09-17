-- 🐐🗣️🔥️✍️ NO REQUIERE API  USA: Fitten login  (Space+a+f+l)| Usuario: dizzi1222
return {
  "luozhiya/fittencode.nvim",
  event = "InsertEnter",
  config = function()
    require("fittencode").setup({
      completion_mode = "inline",

      -- Más contexto = mejor detección de idioma
      prompt = {
        -- max_characters = 100000,
        prompt = "Responde en español, Pro.",
      },

      inline_completion = {
        enable = true,
        auto_triggering_completion = true,
        disable_completion_within_the_line = false,
      },

      delay_completion = {
        delaytime = 100, -- Más rápido
      },

      use_default_keymaps = false,

      keymaps = {
        inline = {
          ["<Tab>"] = "accept_all_suggestions",
          ["<C-CR>"] = "accept_word", -- Ctrl+l (más fácil en móvil)
          ["<C-j>"] = "accept_line", -- Ctrl+j
          ["<C-c>"] = "dismiss_suggestions",
        },
      },
    })

    -- Updatetime más bajo = respuestas más rápidas
    vim.opt.updatetime = 200

    -- which-key: solo mostrar icono cuando fittencode está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>af", icon = { icon = "" } },
        { "<leader>af", mode = "x", icon = { icon = "" } },
      })
    end
  end,
}
