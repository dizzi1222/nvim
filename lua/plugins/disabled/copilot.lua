-- copilot.lua con NES + autocompletado inline
return {
  "zbirenbaum/copilot.lua",
  dependencies = {
    "copilotlsp-nvim/copilot-lsp", -- NES
  },
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      -- ✅ Autocompletado inline tradicional (modo Insert)
      suggestion = {
        enabled = true, -- Inline en Insert
        auto_trigger = true,
        keymap = {
          accept = "<Tab>", -- Tab en INSERT
          accept_word = "<C-Enter>",
          accept_line = "<C-j>",
          dismiss = "<C-]>",
        },
      },

      -- ✅ NES predictivo (modo Normal)
      nes = {
        enabled = true,
        keymap = {
          accept_and_goto = "<leader>p", -- Normal mode
          dismiss = "<Esc>",
        },
      },

      server_opts_overrides = {
        settings = {
          advanced = {
            inlineSuggestCount = 5,
          },
        },
      },
    })
  end,
}

