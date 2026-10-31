-- OpenCode v2: servicio compartido, API nativa y TUI integrado en Neovim.
local terminal = require("utils.opencode-terminal")
local tui_send = terminal.send
local focus_opencode = terminal.focus
local toggle_opencode = terminal.toggle

-- ── Engram: memoria persistente ────────────────────────────────────────────
-- Autodetección de proyecto por cwd; el resumen de sesión SIEMPRE a dotfiles-dizzi.
-- Espejos: <leader>em* (largo) y <leader>m* (corto, sin chocar con markdown).
local function eng_save(title, msg)
  if title == "" or msg == "" then
    return
  end
  vim.fn.system('engram save "' .. title .. '" "' .. msg .. '" --type lesson')
  vim.notify("Saved to Engram (proyecto detectado)")
end

local function eng_save_lesson()
  local title = vim.fn.input("Lesson title: ")
  if title == "" then
    return
  end
  local msg = vim.fn.input("Lesson content: ")
  eng_save("Lección: " .. title, msg)
end

local function eng_save_pattern()
  local title = vim.fn.input("Pattern title: ")
  if title == "" then
    return
  end
  local msg = vim.fn.input("Pattern description: ")
  if msg == "" then
    return
  end
  vim.fn.system('engram save "Patrón: ' .. title .. '" "' .. msg .. '" --type pattern')
  vim.notify("Pattern saved to Engram")
end

local function eng_session_summary()
  local msg = vim.fn.input("Session summary: ")
  if msg == "" then
    return
  end
  vim.fn.system('engram save "Resumen de sesión" "' .. msg .. '" --type session-summary --project dotfiles-dizzi')
  vim.notify("Session summary saved (dotfiles-dizzi)")
end

local function eng_context()
  vim.notify(vim.fn.system("engram context"))
end

local function eng_search()
  local query = vim.fn.input("Search: ")
  if query == "" then
    return
  end
  vim.notify(vim.fn.system('engram search "' .. query .. '"'))
end

-- ── Transcript v2: exportación oficial, sin consultar las tablas legacy ──
local OC_TRANSCRIPT_PY = vim.fn.stdpath("config") .. "/opencode_transcript.py"

---Export a v2 session and display a searchable Markdown buffer, or copy it.
---@param session_id? string
---@param copy? boolean
local function oc_transcript_float(session_id, copy)
  local args = { "python3", OC_TRANSCRIPT_PY }
  if session_id then
    vim.list_extend(args, { "--session", session_id })
  else
    vim.list_extend(args, { "--directory", vim.fn.getcwd() })
  end
  vim.system(
    args,
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify(vim.trim(result.stderr or "No se pudo exportar la sesión"), vim.log.levels.WARN)
        return
      end
      if copy then
        vim.fn.setreg("+", result.stdout)
        vim.notify("Transcript de OpenCode copiado al portapapeles")
        return
      end
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout, "\n", { plain = true }))
      vim.bo[buf].filetype = "markdown"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].modifiable = false
      local width = math.max(1, math.min(120, vim.o.columns - 6))
      local height = math.max(1, math.min(40, vim.o.lines - 6))
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        title = "󱙔 OpenCode transcript",
        title_pos = "center",
      })
      vim.wo[win].number = true
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Cerrar transcript" })
      vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, desc = "Cerrar transcript" })
    end)
  )
end

---Choose a v2 session using IDs, even when multiple sessions have the same title.
local function oc_select_transcript()
  vim.system(
    { "python3", OC_TRANSCRIPT_PY, "--list" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify(vim.trim(result.stderr or "No se pudieron listar las sesiones"), vim.log.levels.WARN)
        return
      end
      local ok, sessions = pcall(vim.json.decode, result.stdout)
      if not ok or type(sessions) ~= "table" or #sessions == 0 then
        vim.notify("Sin sesiones de OpenCode v2", vim.log.levels.INFO)
        return
      end
      vim.ui.select(sessions, {
        prompt = "󱙔 Selecciona una sesión OpenCode:",
        format_item = function(session)
          local created = math.floor((session.time.created or 0) / 1000)
          return ("%s · %s"):format(session.title or session.id, vim.fn.strftime("%Y-%m-%d %H:%M", created))
        end,
      }, function(session)
        if session then
          oc_transcript_float(session.id)
        end
      end)
    end)
  )
end

return {
  "nickjvandyke/opencode.nvim",
  branch = "main",
  version = false, -- Las releases 1.x usan la API antigua.
  commit = "4851ae503585dc5142ad66a98e8952a74e1f7b3a",
  name = "opencode-nick",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    -- ── Toggle ───────────────────────────────────────────────
    {
      "<leader>ao",
      toggle_opencode,
      mode = { "n" },
      desc = " 󰮮 Toggle OpenCode",
    },

    -- ── Ask / Prompts ─────────────────────────────────────────
    {
      "<leader>aK",
      function()
        require("opencode").ask("@this: ")
      end,
      mode = { "n", "x" },
      desc = "󰮮 OpenCode - Send / Ask a Opencode [Input]",
    },
    {
      "<leader>as",
      function()
        terminal.append("@this: ")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode - Send / Enviar a Opencode TUI",
    },

    -- ── Buffers como contexto (no submit, solo referencia) ─────
    {
      "<leader>ab",
      function()
        terminal.append("@buffer: ")
      end,
      mode = { "n" },
      desc = " 󰮮 Agregar @buffer a contexto (sin enviar)",
    },
    {
      "<leader>aB",
      function()
        terminal.append("@buffers: ")
      end,
      mode = { "n" },
      desc = " 󰮮 Agregar @buffers (todos) a contexto",
    },

    -- ── Prompts built-in ──────────────────────────────────────
    {
      "<leader>ap",
      function()
        require("opencode").prompt("@this")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode prompt",
    },
    {
      "<leader>ape",
      function()
        require("opencode").prompt("Explain @this and its context")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode explain",
    },
    {
      "<leader>apf",
      function()
        require("opencode").prompt("Fix @diagnostics")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode fix",
    },
    {
      "<leader>apd",
      function()
        require("opencode").prompt("Explain @diagnostics and suggest a solution")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode diagnose",
    },
    {
      "<leader>apr",
      function()
        require("opencode").prompt("Review @this for correctness and readability")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode review",
    },
    {
      "<leader>apt",
      function()
        require("opencode").prompt("Add tests for @this")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode test",
    },
    {
      "<leader>apo",
      function()
        require("opencode").prompt("Optimize @this for performance and readability")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode optimize",
    },

    -- ── Session management ────────────────────────────────────
    {
      "<leader>aN",
      function()
        tui_send("\x18n")
      end,
      desc = " 󰮮 New Session",
    },
    {
      "<leader>al",
      function()
        tui_send("\x18l")
      end,
      desc = " 󰮮 Select Session (Ctrl+X L)",
    },
    {
      "<leader>au",
      function()
        tui_send("\x18u")
      end,
      desc = " 󰮮 Undo último mensaje",
    },
    {
      "<leader>ar",
      function()
        tui_send("\x18r")
      end,
      desc = " 󰮮 Redo acción",
    },
    {
      "<leader>ax",
      function()
        tui_send("\27")
      end,
      desc = " 󰮮 Interrupt / Detener opencode",
    },
    {
      "<leader>ak",
      function()
        tui_send("\x18c")
      end,
      desc = " 󰮮 Compact / Reducir contexto",
    },
    {
      "<leader>aC",
      function()
        oc_transcript_float(nil, true)
      end,
      mode = { "n", "x" },
      desc = " 󰮮 Copiar transcript (OpenCode v2)",
    },
    {
      "<leader>aF",
      function()
        tui_send("\16fork")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 Fork session (selector de acciones)",
    },

    -- ── Focus TUI terminal ───────────────────────────────────
    {
      "<leader>af",
      focus_opencode,
      desc = " 󰮮 Focus TUI terminal Opencode",
    },

    -- ── Model / Provider selector ────────────────────────────
    {
      "<leader>am",
      function()
        tui_send("\x18m")
      end,
      desc = " 󰮮 Select Model (Ctrl+X M)",
    },
    {
      "<leader>ac",
      function()
        terminal.focus(true)
      end,
      mode = { "n" },
      desc = "󰮮 Continue OpenCode (v2)",
    },
    {
      "<leader>so",
      oc_transcript_float,
      mode = { "n" },
      desc = "󱙔 Open transcript (buscable) en float",
    },
    {
      "<leader>sO",
      oc_select_transcript,
      mode = { "n" },
      desc = "󱙔 Seleccionar sesión y abrir transcript",
    },

    -- ── Engram: Memoria persistente ────────────────────────────
    -- <leader>em*  → grupal largo  |  <leader>m*  → espejo corto (sin chocar con markdown)
    {
      "<leader>ems",
      function()
        eng_save(vim.fn.input("Title: "), vim.fn.input("Message: "))
      end,
      desc = "󰍛 Engram: Save memory",
    },
    {
      "<leader>ms",
      function()
        eng_save(vim.fn.input("Title: "), vim.fn.input("Message: "))
      end,
      desc = "󰍛 Engram: Save memory",
    },
    {
      "<leader>eml",
      eng_save_lesson,
      desc = "󰍛 Engram: Save lesson",
    },
    {
      "<leader>ml",
      eng_save_lesson,
      desc = "󰍛 Engram: Save lesson",
    },
    {
      "<leader>emp",
      eng_save_pattern,
      desc = "󰍛 Engram: Save pattern",
    },
    {
      "<leader>mp",
      eng_save_pattern,
      desc = "󰍛 Engram: Save pattern",
    },
    {
      "<leader>emsess",
      eng_session_summary,
      desc = "󰍛 Engram: Save session summary",
    },
    {
      "<leader>mS",
      eng_session_summary,
      desc = "󰍛 Engram: Save session summary",
    },
    {
      "<leader>emc",
      eng_context,
      desc = "󰍛 Engram: Show context",
    },
    {
      "<leader>mc",
      eng_context,
      desc = "󰍛 Engram: Show context",
    },
    {
      "<leader>emf",
      eng_search,
      desc = "󰍛 Engram: Search memory",
    },
    {
      "<leader>mf",
      eng_search,
      desc = "󰍛 Engram: Search memory",
    },
  },

  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        -- v2 descubre URL y contraseña en el registro del servicio compartido.
        connect = true,
        start = focus_opencode,
      },
      contexts = terminal.contexts(),
    }

    vim.o.autoread = true

    -- ── Inputs flotantes: limpios, sin autocompletado ──
    local function clean_input()
      vim.b.cmp_enabled = false
      vim.b.blink_cmp_enabled = false
      vim.keymap.set("i", "<Esc>", "<Esc>", { buffer = true, desc = "Exit insert mode" })
      vim.keymap.set("i", "<C-BS>", "<C-W>", { buffer = true, desc = "Delete prev word" })
    end
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = vim.api.nvim_create_augroup("OpencodeCleanInput", { clear = true }),
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if ft == "opencode_ask" or ft == "AvanteAsk" or ft == "AvanteInput" then
          clean_input()
        end
      end,
    })

    -- ── Keymaps globales ──────────────────────────────────────
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("opencode").ask("@this: ")
    end, { desc = " 󰮮 Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = " 󰮮 Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", toggle_opencode, { desc = " 󰮮 Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function()
      return terminal.operator()
    end, { desc = " 󰮮 Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function()
      return terminal.operator() .. "_"
    end, { desc = " 󰮮 Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function()
      tui_send("\27\21")
    end, { desc = " 󰮮 Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function()
      tui_send("\27\4")
    end, { desc = " 󰮮 Scroll opencode down" })

    -- which-key: solo mostrar iconos cuando opencode está activo
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>aC", icon = { icon = "󰮮" } },
        { "<leader>ak", icon = { icon = "󰮮" } },
        { "<leader>al", icon = { icon = "󰮮" } },
        { "<leader>am", icon = { icon = "󰮮" } },
        { "<leader>ao", icon = { icon = "󰮮" } },
        { "<leader>ar", icon = { icon = "󰮮" } },
        { "<leader>aF", icon = { icon = "󰮮" } },
        { "<leader>as", icon = { icon = "󰮮" } },
        { "<leader>au", icon = { icon = "󰮮" } },
        { "<leader>ax", icon = { icon = "󰮮" } },
        { "<leader>ap", icon = { icon = "󰮮" } },
        { "<leader>af", icon = { icon = "" } },
        { "<leader>ab", icon = { icon = "" } },
        { "<leader>aB", icon = { icon = "" } },
        { "<leader>so", icon = { icon = "󱙔" } },
        { "<leader>sO", icon = { icon = "󱙔" } },
        -- Engram: Memory Persistent [Opencode, AI] + Atajos en: @plugins/which-key.lua:L23
      })
    end
  end,
}
