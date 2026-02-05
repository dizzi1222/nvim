-- 🐐🗣️🔥️✍️ NO REQUIERE API  USA:Copilot auth  | AUTOCOMPLETADO 󰄭 .
return {
  "zbirenbaum/copilot.lua",
  optional = true,
  opts = function()
    require("copilot").setup({
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<Tab>", -- acepta sugerencia
          -- suggestion_color = { gui = "#caa99b", cterm = 244 }, -- #808080
          dismiss = "<C-]>", -- cierra sugerencia
          accept_word = "<C-Enter>", -- antes estaba como C-j
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        -- poner true para filetypes donde quieras AI
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
      },
    })
  end,
}
