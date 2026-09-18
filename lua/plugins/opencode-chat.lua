-- 🐐🗣️🔥️✍️ NO REQUIERE API: Opencode (NickvanDyke)
--  <leader>ao → Toggle  |  <C-a> → Ask @this  |  <C-x> → Select
--  <leader>ag → Menú de prompts  |  go/goo → operadores
--  @buffer, @this, @diagnostics nativos
--
-- TUI fallback para comandos que el server no expone (/fork, /share, Ctrl+X)
local function tui_send(text, focus)
  if focus == nil then
    focus = true
  end
  local bufs = vim.api.nvim_list_bufs()
  for i = 1, #bufs do
    local buf = bufs[i]
    if vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("opencode") then
        local chan = vim.bo[buf].channel
        if chan and chan > 0 then
          vim.api.nvim_chan_send(chan, text)
          if focus then
            local win = vim.fn.bufwinid(buf)
            if win ~= -1 then
              vim.api.nvim_set_current_win(win)
              vim.cmd("startinsert")
            end
          end
          return true
        end
      end
    end
  end
  return false
end

-- opencode se abre en una terminal snacks.terminal. Fijamos una sola cwd al
-- arrancar para que el id sea estable; así, al cambiar de proyecto/directorio
-- SIEMPRE se enfoca/oculta la misma sesión. El puerto se fija (4096) para que
-- coincida con `url` del server y el plugin conecte SIEMPRE a la misma
-- instancia (sin auto-discovery). La terminal se busca por su cmd real
-- (opencode) y NO con `snacks.terminal.get(..., {create=true})`: ese get crea
-- una terminal NUEVA aunque el server ya viva, spawneando otro `opencode
-- --port` que no puede bindear 4096 y queda zombie.
local OC_CMD = "opencode --port 4096"
local OC_ATTACH = "opencode attach http://localhost:4096"
local OC_OPTS = {
  cwd = vim.loop.cwd(), -- estable: no cambiar con el cwd actual de Neovim
  win = {
    position = "right",
    enter = false,
  },
}

-- ¿Hay un server opencode escuchando en 4096?
local function server_running()
  local ok = vim.fn.system("curl -sf -m 2 -o /dev/null http://localhost:4096/")
  return vim.v.shell_error == 0 and ok == ""
end

-- Busca la terminal TUI opencode viva registrada en snacks.terminal.
local function find_opencode_term()
  local snacks = require("snacks.terminal")
  for _, term in ipairs(snacks.list()) do
    local cmd = term.cmd
    if type(cmd) == "string" and cmd:match("opencode") then
      return term
    end
  end
  return nil
end

-- Limpia buffers terminal opencode muertos (canal cerrado) que quedan de
-- procesos que ya no existen (zombies tipo term://166836:opencode).
local function cleanup_dead_opencode()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("opencode") then
      local chan = vim.bo[buf].channel
      if not chan or chan <= 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

-- Abre la terminal correcta según el estado del server:
--   - server vivo:  `opencode attach` (conecta al 4096, NO spawna otro bind)
--   - server muerto: `opencode --port 4096` (arranca server + TUI)
local function open_opencode()
  local snacks = require("snacks.terminal")
  if server_running() then
    snacks.open(OC_ATTACH, OC_OPTS)
  else
    snacks.open(OC_CMD, OC_OPTS)
  end
end

-- Toggle real: muestra si está oculta, oculta si está visible, crea si no existe.
local function toggle_opencode()
  cleanup_dead_opencode()
  local term = find_opencode_term()
  if term then
    term:toggle()
  else
    open_opencode()
  end
end

-- Focus: muestra y enfoca la terminal ya creada (o la crea si no hay ninguna).
local function focus_opencode()
  cleanup_dead_opencode()
  local term = find_opencode_term()
  if term then
    term:show():focus()
  else
    open_opencode()
  end
end

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

-- ── Transcript en float (<leader>so / <leader>sO) ──────────────────────────
-- Vuelca el transcript markdown de una sesión opencode leyendo literal la DB
-- (~/.local/share/opencode/*.db) con el helper opencode_transcript.py, que
-- replica el formato EXACTO del /copy del TUI (headers `## User` /
-- `## Assistant (Agent · Model · tiempo)`, `_Thinking:_` y tools).
--   <leader>so → sesión más activa (time_updated)
--   <leader>sO → selector de sesiones (vía --list) y abre la elegida
-- No depende del clipboard ni del foco de la TUI (el flujo /copy era frágil).
local OC_TRANSCRIPT_PY = vim.fn.stdpath("config") .. "/opencode_transcript.py"

local function oc_open_transcript_float(session_id)
  local tmp = "/tmp/copy.md"
  local buf = vim.fn.bufadd(tmp)
  vim.bo[buf].filetype = "markdown"
  local cols, rows = vim.o.columns, vim.o.lines
  local width = math.min(120, cols - 6)
  local height = math.min(40, rows - 6)
  local title = session_id and ("󱙔 opencode transcript — " .. session_id:sub(1, 8))
    or "󱙔 opencode transcript — /tmp/copy.md"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.max(0, math.floor((rows - height) / 2) - 1),
    col = math.max(0, math.floor((cols - width) / 2)),
    title = title,
    title_pos = "center",
  })
  vim.wo[win].number = true
  if vim.fn.filereadable(tmp) == 1 then
    vim.cmd("edit " .. tmp)
  end
  vim.schedule(function()
    vim.cmd("normal! gg")
  end)
  -- q / Esc cierran el float; la búsqueda nativa (/ ? n N) funciona de serie.
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Cerrar transcript" })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, desc = "Cerrar transcript" })
end

local function oc_transcript_float(session_id)
  if vim.fn.filereadable(OC_TRANSCRIPT_PY) ~= 1 then
    vim.notify("󱙔 Falta " .. OC_TRANSCRIPT_PY, vim.log.levels.WARN)
    return
  end

  local args = { "python3", OC_TRANSCRIPT_PY }
  if session_id then
    vim.list_extend(args, { "--session", session_id })
  end
  local out = {}
  vim.fn.jobstart(args, {
    stdout_buffered = true,
    on_stdout = function(_, d)
      if d then
        vim.list_extend(out, d)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          vim.notify("󱙔 opencode_transcript.py falló (código " .. code .. ")", vim.log.levels.WARN)
          return
        end
        if #out == 0 or vim.fn.filereadable("/tmp/copy.md") ~= 1 then
          vim.notify("󱙔 Sin transcript: no hay sesión opencode", vim.log.levels.WARN)
          return
        end
        oc_open_transcript_float(session_id)
      end)
    end,
  })
end

-- Selector de sesiones (rápido y simple): lista las sesiones con su último
-- título y fecha, y abre el transcript de la elegida en el float.
local function oc_select_transcript()
  if vim.fn.filereadable(OC_TRANSCRIPT_PY) ~= 1 then
    vim.notify("󱙔 Falta " .. OC_TRANSCRIPT_PY, vim.log.levels.WARN)
    return
  end

  local items = {}
  vim.fn.jobstart({ "python3", OC_TRANSCRIPT_PY, "--list" }, {
    stdout_buffered = true,
    on_stdout = function(_, d)
      if d then
        vim.list_extend(items, d)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 or #items == 0 then
          vim.notify("󱙔 Sin sesiones opencode en la DB", vim.log.levels.WARN)
          return
        end
        local choices = {}
        local map = {}
        for _, line in ipairs(items) do
          local id, title, created, _, texts = line:match("([^|]+)|([^|]*)|([^|]*)|[^|]*|([^|]*)")
          local label = title ~= "" and title or "(sin título)"
          if #label > 60 then
            label = label:sub(1, 57) .. "…"
          end
          local choice = ("󱙔 %s  ·  %s  ·  %s msgs"):format(label, created, texts or "0")
          choices[#choices + 1] = choice
          map[choice] = id
        end
        vim.ui.select(choices, {
          prompt = "󱙔 Seleccioná sesión opencode:",
        }, function(choice)
          if choice and map[choice] then
            oc_transcript_float(map[choice])
          end
        end)
      end)
    end,
  })
end

return {
  -- 1. Apuntar a tu fork con los parches nativos
  "dizzi1222/opencode.nvim",
  -- commit = "0d0aede7", -- Opcional: Lazy.nvim descargará siempre lo último de main.
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
        local as_group = vim.api.nvim_create_augroup("opencode_as_focus", { clear = true })
        vim.api.nvim_create_autocmd("User", {
          pattern = "OpencodeEvent:*",
          group = as_group,
          once = true,
          callback = function()
            vim.defer_fn(function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("opencode") then
                  local win = vim.fn.bufwinid(buf)
                  if win ~= -1 then
                    vim.api.nvim_set_current_win(win)
                    vim.cmd("startinsert")
                  end
                  break
                end
              end
            end, 100)
          end,
        })
        require("opencode").ask("@this: ", { submit = false })
      end,
      mode = { "n", "x" },
      desc = "󰮮 OpenCode - Send / Ask a Opencode [Input]",
    },
    {
      "<leader>as",
      function()
        require("opencode").prompt("@this: ")
        vim.defer_fn(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("opencode") then
              local win = vim.fn.bufwinid(buf)
              if win ~= -1 then
                vim.api.nvim_set_current_win(win)
                vim.cmd("startinsert")
              end
              break
            end
          end
        end, 200)
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode - Send / Enviar a Opencode TUI",
    },

    -- ── Buffers como contexto (no submit, solo referencia) ─────
    {
      "<leader>ab",
      function()
        require("opencode").ask("@buffer: ", { submit = false })
      end,
      mode = { "n" },
      desc = " 󰮮 Agregar @buffer a contexto (sin enviar)",
    },
    {
      "<leader>aB",
      function()
        require("opencode").ask("@buffers: ", { submit = false })
      end,
      mode = { "n" },
      desc = " 󰮮 Agregar @buffers (todos) a contexto",
    },

    -- ── Prompts built-in ──────────────────────────────────────
    {
      "<leader>ap",
      function()
        require("opencode").prompt("@this", { submit = true })
      end,
      mode = { "n", "x" },
      desc = " 󰮮 OpenCode prompt",
    },
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

    -- ── Session management ────────────────────────────────────
    {
      "<leader>aN",
      function()
        require("opencode").command("session.new")
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
        require("opencode").command("session.undo")
      end,
      desc = " 󰮮 Undo último mensaje",
    },
    {
      "<leader>ar",
      function()
        require("opencode").command("session.redo")
      end,
      desc = " 󰮮 Redo acción",
    },
    {
      "<leader>ax",
      function()
        require("opencode").command("session.interrupt")
      end,
      desc = " 󰮮 Interrupt / Detener opencode",
    },
    {
      "<leader>ak",
      function()
        require("opencode").command("session.compact")
      end,
      desc = " 󰮮 Compact / Reducir contexto",
    },
    {
      "<leader>aC",
      function()
        tui_send("/share\n")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 Share session (link)",
    },
    {
      "<leader>aF",
      function()
        tui_send("/fork\n")
      end,
      mode = { "n", "x" },
      desc = " 󰮮 Fork session (desde este punto)",
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
        require("snacks.terminal").open("opencode --continue --port 4096", OC_OPTS)
      end,
      mode = { "n" },
      desc = "󰮮 Continue (abre opencode --continue en 4096)",
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
        -- Conecta DIRECTO al server opencode --port existente (4096).
        -- Sin `url`, el plugin usa auto-discovery (pgrep+lsof+CWD overlap) que
        -- en termux falla (lsof ausente / CWD distinto) y en desktop crea OTRAS
        -- instancias al cambiar de CWD -> "No OpenCode servers found with
        -- overlapping CWD" y sessões nuevas. Con `url`+`connect` SIEMPRE usa la
        -- misma instancia que abre OC_CMD (puerto 4096 fijo).
        url = "http://localhost:4096",
        connect = true,
        start = function()
          focus_opencode()
        end,
      },
      providers = {
        anthropic = {
          api_key_cmd = "echo $ANTHROPIC_API_KEY",
          model = "claude-sonnet-4-20250514",
        },
        gemini = {
          auth_type = "oauth",
          model = "gemini-2.5-pro",
          models = {
            ["gemini-2.5-pro"] = {
              options = {
                thinkingConfig = {
                  thinkingBudget = 8192,
                  includeThoughts = true,
                },
              },
            },
          },
        },
      },
      default_provider = "anthropic",
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
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if ft == "opencode_ask" or ft == "AvanteAsk" or ft == "AvanteInput" then
          clean_input()
        end
      end,
    })

    -- ── Keymaps globales ──────────────────────────────────────
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = " 󰮮 Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("opencode").select()
    end, { desc = " 󰮮 Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", toggle_opencode, { desc = " 󰮮 Toggle opencode" })

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
