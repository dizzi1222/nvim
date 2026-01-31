-- 🐐🗣️🔥️✍️ NO REQUIERE API: -- -- ✍️ Activar con:OpenCodeToggle  Luego  Ctrl + X + M (Cambiar Model)  Ctrl+A (Cambiar de Provider)        ~ (MEJOR QUE ANTIGRAVITY\CHAT Nativo)
--
return {
  "NickvanDyke/opencode.nvim",
  name = "opencode-nick", -- ← IMPORTANTE: nombre único
  dependencies = {
    --  Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("opencode").toggle()
      end,
      mode = { "n" },
      desc = " 󰮮 Toggle OpenCode [Cli]",
    },
    {
      "<leader>ao",
      function()
        require("opencode").toggle()
      end,
      mode = { "n" },
      desc = " 󰮮 Toggle OpenCode [Cli]",
    },

    {
      "<leader>ai",
      function()
        require("opencode").ask("", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode ask",
    },
    {
      "<leader>aI",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode ask with context",
    },
    {
      "<leader>ab",
      function()
        require("opencode").ask("@file ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode ask about buffer",
    },
    {
      "<leader>ap",
      function()
        require("opencode").prompt("@this", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode prompt",
    },
    -- Built-in prompts
    {
      "<leader>ape",
      function()
        require("opencode").prompt("explain", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode explain",
    },
    {
      "<leader>apf",
      function()
        require("opencode").prompt("fix", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode fix",
    },
    {
      "<leader>apd",
      function()
        require("opencode").prompt("diagnose", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode diagnose",
    },
    {
      "<leader>apr",
      function()
        require("opencode").prompt("review", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode review",
    },
    {
      "<leader>apt",
      function()
        require("opencode").prompt("test", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode test",
    },
    {
      "<leader>apo",
      function()
        require("opencode").prompt("optimize", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode optimize",
    },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
      providers = {
        anthropic = {
          -- auth_type = "max",  --   Opencode SOLO  funciona con API KEYS
          api_key_cmd = "echo $ANTHROPIC_API_KEY", -- 🔥 Cambiar ESTO
          model = "claude-sonnet-4-20250514",
        },
      },
      default_provider = "anthropic",
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = " 󰮮 Ask opencode… " })
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = " 󰮮 Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", function()
      require("opencode").toggle()
    end, { desc = " 󰮮 Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function()
      return require("opencode").operator("@this ")
    end, { desc = " 󰮮 Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { desc = " 󰮮 Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = " 󰮮 Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = " 󰮮 Scroll opencode down" })

    -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o…".
    vim.keymap.set("n", "+", "<C-a>", { desc = " 󰮮 Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = " 󰮮 Decrement under cursor", noremap = true })
  end,
}
