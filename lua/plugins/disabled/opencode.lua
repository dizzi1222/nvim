-- 🐐🗣️🔥️✍️ NO REQUIERE API: Opencode alternativa a copilot chat
return {
  "sudo-tee/opencode.nvim",
  name = "opencode-sudo", -- ← IMPORTANTE: nombre único
  config = function()
    require("opencode").setup({
      server = {
        url = "http://localhost:4096", -- Esta es la URL que necesitas
        autostart = false, -- No intentar iniciar el servidor automáticamente
      },
      default_mode = "build",
      default_model = "ollama/deepseek-v3.1:671b", -- ← AGREGAR ESTA LÍNEA
      -- default_model = "claude-sonnet-4-20250514", --  Para  Claude 🔥
      opencode_executable = "opencode",

      keymap = {
        editor = {
          -- Keymaps principales
          ["<leader>og"] = { "toggle", desc = "󰮮 Toggle OpenCode [Avante Like sudo-tee]" },
          ["<leader>ao"] = { "toggle", desc = "󰮮 Toggle OpenCode [Avante Like sudo-tee]" },
          ["<leader>oi"] = { "open_input", desc = "󰮮 Open input window" },
          ["<leader>oI"] = { "open_input_new_session", desc = "󰮮 Open input (new session)" },
          ["<leader>oo"] = { "open_output", desc = "󰮮 Open output window" },
          ["<leader>ot"] = { "toggle_focus", desc = "󰮮 Toggle focus OpenCode/Editor" },
          ["<leader>oq"] = { "close", desc = "󰮮 Close UI windows" },
          ["<leader>os"] = { "select_session", desc = "󰮮 Select session" },
          ["<leader>oR"] = { "rename_session", desc = "󰮮 Rename session" },
          ["<leader>op"] = { "configure_provider", desc = "󰮮 Configure provider/model" },
          ["<leader>oz"] = { "toggle_zoom", desc = "󰮮 Toggle zoom" },
          ["<leader>ov"] = { "paste_image", desc = "󰮮 Paste image" },
          ["<leader>aP"] = { "paste_image", desc = "󰮮 Paste image [Avante Like sudo-tee]" },
          ["<leader>iv"] = { "paste_image", desc = "󰮮 Paste image [Avante Like sudo-tee]" },

          -- Keymaps para diffs
          ["<leader>od"] = { "diff_open", desc = "󰮮 Open diff view" },
          ["<leader>o]"] = { "diff_next", desc = "󰮮 Next file diff" },
          ["<leader>o["] = { "diff_prev", desc = "󰮮 Previous file diff" },
          ["<leader>oc"] = { "diff_close", desc = "󰮮 Close diff view" },
          ["<leader>ora"] = { "diff_revert_all_last_prompt", desc = "󰮮 Revert all (last prompt)" },
          ["<leader>ort"] = { "diff_revert_this_last_prompt", desc = "󰮮 Revert file (last prompt)" },
          ["<leader>orA"] = { "diff_revert_all", desc = "󰮮 Revert all (session)" },
          ["<leader>orT"] = { "diff_revert_this", desc = "󰮮 Revert file (session)" },
          ["<leader>orr"] = { "diff_restore_snapshot_file", desc = "󰮮 Restore file to snapshot" },
          ["<leader>orR"] = { "diff_restore_snapshot_all", desc = "󰮮 Restore all to snapshot" },

          -- Otros keymaps útiles
          ["<leader>ox"] = { "swap_position", desc = "󰮮 Swap pane position" },
          ["<leader>oT"] = { "timeline", desc = "󰮮 Timeline picker" },
          ["<leader>o/"] = { "quick_chat", mode = { "n", "x" }, desc = "󰮮 Quick chat" },
          ["<leader>aq"] = { "quick_chat", mode = { "n", "x" }, desc = "󰮮 Quick chat [Avante Like sudo-tee]" },
          -- OpenCode [Avante Like sudo-tee] PROMPTS PERSONALIZADOS:
          ["<leader>aa1"] = {
            function()
              vim.cmd(
                'Opencode run "Revisar el código seleccionado y sugerir mejoras" model=ollama/deepseek-v3.1:671b'
              )
            end,
            mode = { "n", "x" },
            desc = "󰮮 Revisar código ◎",
          },
          ["<leader>aa2"] = {
            function()
              vim.cmd('Opencode run "Explicar detalladamente qué hace este código" model=ollama/deepseek-v3.1:671b')
            end,
            mode = { "n", "x" },
            desc = "󰮮 󱜨 Explicar código",
          },
          ["<leader>aa3"] = {
            function()
              vim.cmd('Opencode run "Debuggear este error y proponer soluciones" model=ollama/deepseek-v3.1:671b')
            end,
            mode = { "n", "x" },
            desc = "󰮮  Debuggear error ◎",
          },
          ["<leader>aa4"] = {
            function()
              vim.cmd(
                'Opencode run "Refactorizar este código para mejorar legibilidad y mantenibilidad" model=ollama/deepseek-v3.1:671b'
              )
            end,
            mode = { "n", "x" },
            desc = "󰮮 󰈏 Refactorizar ◎",
          },
          ["<leader>aa5"] = {
            function()
              vim.cmd('Opencode run "Optimizar el rendimiento de este código" model=ollama/deepseek-v3.1:671b')
            end,
            mode = { "n", "x" },
            desc = "󰮮 󰓅 Optimizar ◎",
          },
          ["<leader>aa6"] = {
            function()
              vim.cmd('Opencode run "' .. vim.fn.input("󰮮 Custom prompt: ") .. '" model=ollama/deepseek-v3.1:671b')
            end,
            mode = { "n", "x" },
            desc = "󰮮 Opencode Prompt [Avante Like sudo-tee]",
          },

          ["<leader>opa"] = { "permission_accept", desc = "󰮮 Accept permission (once)" },
          ["<leader>opA"] = { "permission_accept_all", desc = "󰮮 Accept all permissions" },
          ["<leader>opd"] = { "permission_deny", desc = "󰮮 Deny permission" },
          ["<leader>ott"] = { "toggle_tool_output", desc = "󰮮 Toggle tool output" },
          ["<leader>otr"] = { "toggle_reasoning_output", desc = "󰮮 Toggle reasoning output" },
          ["<leader>oS"] = { "select_child_session", desc = "󰮮 Select child session" },
        },

        input_window = {
          ["<cr>"] = { "submit_input_prompt", mode = { "n", "i" }, desc = "󰮮 Submit prompt" },
          ["<esc>"] = { "close", desc = "󰮮 Close OpenCode" },
          ["<C-c>"] = { "cancel", desc = "󰮮 Cancel request" },
          ["~"] = { "mention_file", mode = "i", desc = "󰮮 Mention file" },
          ["@"] = { "mention", mode = "i", desc = "󰮮 Insert mention" },
          ["/"] = { "slash_commands", mode = "i", desc = "󰮮 Slash commands" },
          ["#"] = { "context_items", mode = "i", desc = "󰮮 Context items" },
          ["<M-v>"] = { "paste_image", mode = "i", desc = "󰮮 Paste image" },
          ["<C-i>"] = { "focus_input", mode = { "n", "i" }, desc = "󰮮 Focus input" },
          ["<tab>"] = { "toggle_pane", mode = { "n", "i" }, desc = "󰮮 Toggle pane" },
          ["<up>"] = { "prev_prompt_history", mode = { "n", "i" }, desc = "󰮮 Previous prompt" },
          ["<down>"] = { "next_prompt_history", mode = { "n", "i" }, desc = "󰮮 Next prompt" },
          ["<M-m>"] = { "switch_mode", desc = "󰮮 Switch mode (build/plan)" },
        },

        output_window = {
          ["<esc>"] = { "close", desc = "󰮮 Close OpenCode" },
          ["<C-c>"] = { "cancel", desc = "󰮮 Cancel request" },
          ["]]"] = { "next_message", desc = "󰮮 Next message" },
          ["[["] = { "prev_message", desc = "󰮮 Previous message" },
          ["<tab>"] = { "toggle_pane", mode = { "n", "i" }, desc = "󰮮 Toggle pane" },
          ["i"] = { "focus_input", mode = "n", desc = "󰮮 Focus input" },
          ["<leader>oS"] = { "select_child_session", desc = "󰮮 Select child session" },
          ["<leader>oD"] = { "debug_message", desc = "󰮮 Debug message" },
          ["<leader>oO"] = { "debug_output", desc = "󰮮 Debug output" },
          ["<leader>ods"] = { "debug_session", desc = "󰮮 Debug session" },
        },

        ui = {
          position = "left",
          display_model = true,
          window_highlight = "Normal:OpencodeBackground,FloatBorder:OpencodeBorder",
          output = {
            tools = {
              show_output = true,
            },
          },
        },

        permission = {
          accept = "a",
          accept_all = "A",
          deny = "d",
        },

        session_picker = {
          rename_session = { "<C-r>" },
          delete_session = { "<C-d>" },
          new_session = { "<C-n>" },
        },

        timeline_picker = {
          undo = { "<C-u>", mode = { "i", "n" } },
          fork = { "<C-f>", mode = { "i", "n" } },
        },
      },
    })
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "opencode_output" },
      },
      ft = { "markdown", "opencode_output" },
    },
    "folke/snacks.nvim",
  },
}
