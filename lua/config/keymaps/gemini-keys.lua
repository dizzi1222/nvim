-- =============================================================
-- KEYMAPS ANTIGRAVITY AI 󰨞 (agy)  NO REQUIERE API
-- =============================================================
-- Integración con lua/plugins/antigravity.lua (NakLast/antigravity-cli.nvim)
-- Patrón tomado de opencode-chat.lua:
--   - agy_send(): detecta el buffer terminal PERSISTENTE del plugin y envía
--     texto por su canal. Si no existe, lo abre vía require("antigravity").
--     CERO ventanas nuevas: el plugin mantiene state.buf entre toggles.
--
--   Prefijos de acciones (Triple alternativa):
--     (Space+a+g), | (Space+G) | (Space+g+g)
--     v<leader>ag / v<leader>G / v<leader>gg      prompts (fix/debug/..)  <leader>ag/ <leader>G/ <leader>gg/ Editar Keybindings
--     <leader>agt / v<leader>Gt / v<leader>ggt    toggle (no slash)       <leader>agp / <leader>Gp /plan
--     <leader>agL / <leader>GL / <leader>gL       /goal                   <leader>agl / <leader>Gl /resume (switch)
--     <leader>agn / v<leader>Gn / v<leader>ggn    /clear (new)            <leader>agc / <leader>Gc /clear (clean)
--     <leader>agf / v<leader>Gf / v<leader>ggf    /fork (branch)          <leader>agm / <leader>Gm /model
--     <leader>agq / v<leader>Gq / v<leader>ggq    /exit (quit)            <leader>agd / <leader>Gd /diff
--     <leader>agk / v<leader>Gk / v<leader>ggk    /context                <leader>agw / <leader>Gw /btw
--     <leader>agw / v<leader>Gw / v<leader>ggw    /btw                    <leader>age / <leader>Ge /grill-me
--     <leader>ags / v<leader>Gs / v<leader>ggs    /skills                 <leader>ago / <leader>Go /ggo  focus agy
--     <leader>agr / v<leader>Gr / v<leader>ggr    /rename                 <leader>agC / <leader>GC /changelog
--     <leader>agx / v<leader>Gx / v<leader>ggx    interrumpir             <leader>agP / <leader>GP /ggP menú
--     <leader>ago / v<leader>Go / v<leader>ggo    focus agy               <leader>agF / <leader>GF /ggF fork
--     <leader>agO / v<leader>GO / v<leader>ggO    open agy                <leader>agu / <leader>Gu /ggu  Undo ctrl+u
--     <leader>agZ / v<leader>GZ / v<leader>ggZ    Redo                    <leader>ag? / <leader>G? / <leader>gg?  shortcuts
--
--   Envío de código con líneas exactas (estilo opencode @file, SIN contenido):
--     <leader>agb / <leader>Gb / <leader>ggb → buffer ACTUAL      (ref @ruta:1-N)
--     <leader>agB / <leader>GB / <leader>ggB → TODOS los buffers  (refs @ruta:1-N por archivo)
--     visual <leader>ag / <leader>G / <leader>gg → SELECCIÓN     (ref @ruta:start-end)
--
--   Slash commands reales de agy (verificados en el menú / del CLI):
--   /plan /goal /grill-me /btw /resume (switch) /rewind (undo)
--   /clear (new) /fork (branch) /diff /context /model /permissions
--   /agents /tasks /artifact /add-dir /codesearch /mcp /hooks
--   /keybindings /config (settings) /rename /copy /schedule /usage
--   /credits /feedback /learn /skills /open /title /statusline
--   /exit (quit) /logout /changelog /help
-- =============================================================

local is_wsl = vim.fn.has("wsl") == 1
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and not is_wsl

vim.g.mapleader = " "

local keymap = vim.keymap

vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- ── Envío al buffer persistente de agy ───────────────────────
-- Busca un buffer terminal cuyo nombre matchee "agy" (el que abre
-- lua/plugins/antigravity.lua con `term agy`). Si el canal está vivo,
-- envía el texto y opcionalmente enfoca la ventana. Devuelve true/false.
local function agy_send(text, focus)
  if focus == nil then
    focus = true
  end
  local bufs = vim.api.nvim_list_bufs()
  for i = 1, #bufs do
    local buf = bufs[i]
    if vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("agy") then
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

-- Último recurso: si no hay plugin disponible, abre un terminal plano
-- en un vsplit y le escribe el texto pasados 1.2s (arranque de agy).
local function agy_fallback_open(text)
  vim.cmd("vsplit | vertical resize 50")
  vim.cmd("term agy")
  vim.defer_fn(function()
    local bufs = vim.api.nvim_list_bufs()
    for i = 1, #bufs do
      local buf = bufs[i]
      if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("agy") then
        local chan = vim.bo[buf].channel
        if chan and chan > 0 then
          vim.api.nvim_chan_send(chan, text)
        end
        break
      end
    end
  end, 1200)
  vim.cmd("startinsert")
end

-- Envía texto al agy. Reusa el buffer del plugin; si no existe lo abre
-- con require("antigravity").toggle() y reintenta tras el arranque.
local function agy_send_text(text)
  if agy_send(text) then
    return
  end
  local ok, ag = pcall(require, "antigravity")
  if ok and ag.toggle then
    ag.toggle()
    vim.defer_fn(function()
      if not agy_send(text) then
        agy_fallback_open(text)
      end
    end, 500)
  else
    agy_fallback_open(text)
  end
end

-- ── Envía un comando slash (ej. /resume) al agy ──────────────
local function agy_command(command)
  agy_send_text(command .. "\n")
end

-- ── Interrumpir / escapar (cli.escape nativo del CLI agy) ─────
--   agy trae cli.escape propio: ["esc", "ctrl+w", "alt+w", "ctrl+x"].
--   ESC (\027) interrumpe la generación sin cerrar el TUI, así que ya
--   no hace falta el hack viejo (Enter\r + ESC) que concatenaba con el
--   draft si el prompt no estaba vacío. Ctrl+C hoy es cli.clear_screen
--   (limpia pantalla, ya NO cierra el TUI).
local function agy_flush_interrupt()
  local bufs = vim.api.nvim_list_bufs()
  for i = 1, #bufs do
    local buf = bufs[i]
    if vim.bo[buf].buftype == "terminal" then
      local chan = vim.bo[buf].channel
      if chan and chan > 0 and vim.api.nvim_buf_get_name(buf):match("agy") then
        vim.api.nvim_chan_send(chan, "\027")
        return
      end
    end
  end
end

-- ── Referencia opencode-style @ruta:start-end (líneas exactas) ──
-- Devuelve "@<ruta absoluta>:<start>-<end>" si el buffer tiene nombre;
-- sin rango si start es nil. nil si el buffer es sin nombre.
local function file_ref(start_line, end_line)
  local path = vim.fn.expand("%:p")
  if path == "" then
    return nil
  end
  if start_line then
    return "@" .. path .. ":" .. start_line .. "-" .. end_line
  end
  return "@" .. path
end

-- ── Envía SOLO la referencia del buffer ACTUAL (sin contenido) ──
--   agy lee el archivo por sí mismo con @ruta:1-N → rápido.
local function send_buffer_to_agy()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local ref = file_ref(1, #lines)
  if ref then
    agy_send_text(ref .. "\n")
  end
end

-- ── Envía las referencias de TODOS los buffers con nombre ──
--   (estilo opencode @buffers). Solo refs @ruta:1-N, sin contenido.
local function send_all_buffers_to_agy()
  local refs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= "" and not path:match("^term://") then
        local count = vim.api.nvim_buf_line_count(buf)
        table.insert(refs, "@" .. path .. ":1-" .. count)
      end
    end
  end
  if #refs > 0 then
    agy_send_text(table.concat(refs, "\n") .. "\n")
  end
end

-- ── Acción: abre agy con el prompt + SOLO la referencia @ruta:start-end ──
local function open_gemini(prompt, start_line, end_line)
  local full = prompt
  local ref = start_line and file_ref(start_line, end_line) or nil
  if ref then
    full = full .. "\n" .. ref
  end
  agy_send_text(full .. "\n")
end

-- ── Menú de prompts (revisar/explicar/debuggear/refactorizar/...) ──
local function show_gemini_menu(start_line, end_line)
  local options = {
    "  󰨞 Revisar código",
    "  󰨞 Explicar código",
    "  󰨞 Debuggear error",
    "  󰨞 Refactorizar",
    "  󰨞 Optimizar",
    "  󰨞 Personalizado [Abrir agy]",
  }

  vim.ui.select(options, {
    prompt = " 󰨞 ~ Selecciona acción:",
  }, function(choice, idx)
    if not choice then
      return
    end

    local prompts = {
      "Revisa este código y sugiere mejoras:",
      "Explica este código paso a paso:",
      "Debuggea este error:",
      "Refactoriza este código:",
      "Optimiza este código:",
      "", -- Personalizado
    }

    if idx == 6 then -- Opción personalizada
      vim.ui.input({
        prompt = "Tu prompt: ",
      }, function(input)
        if input and input ~= "" then
          open_gemini(input, start_line, end_line)
        end
      end)
    else
      open_gemini(prompts[idx], start_line, end_line)
    end
  end)
end

-- ── Enfocar la ventana de agy (Focus directo sin cerrar/alternar) ──
local function agy_focus()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("agy") then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
        return
      end
    end
  end
  local ok, ag = pcall(require, "antigravity")
  if ok and ag.toggle then
    ag.toggle()
  else
    agy_fallback_open("")
  end
end

-- ── Acción por prefijo (triple alternativa: <leader>ag, <leader>G y <leader>gg) ────────
local prefixes = { "<leader>ag", "<leader>G", "<leader>gg" }

local function map_cmd(mode, suffix, fn_or_cmd, desc)
  local suffixes = type(suffix) == "table" and suffix or { suffix }
  for _, pfx in ipairs(prefixes) do
    for _, sfx in ipairs(suffixes) do
      keymap.set(mode, pfx .. sfx, fn_or_cmd, { desc = desc })
    end
  end
end

-- Menú de prompts (Normal mode: <leader>ag, <leader>G, <leader>gg, <leader>agP, <leader>GP, <leader>ggP)
map_cmd("n", "P", function()
  show_gemini_menu()
end, "󰨞 Agy: menú de prompts")

-- Menú de prompts para selección visual (Visual mode: <leader>ag, <leader>G y <leader>gg)
map_cmd("v", "", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  show_gemini_menu(start_line, end_line)
end, "󰨞 Agy: enviar selección a menú (solo @ruta:start-end)")

-- ── Toggle seguro de la ventana de agy (Evita Vim:E444) ───────
local function agy_toggle()
  local ok, ag = pcall(require, "antigravity")
  if ok and ag.toggle then
    local wins = vim.api.nvim_list_wins()
    if #wins <= 1 then
      local buf = vim.api.nvim_win_get_buf(wins[1])
      if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("agy") then
        vim.cmd("new")
      end
    end
    local toggle_ok = pcall(ag.toggle)
    if not toggle_ok then
      pcall(vim.cmd, "new")
      pcall(ag.toggle)
    end
  else
    agy_fallback_open("\n")
  end
end

-- Toggle del plugin
map_cmd("n", "t", agy_toggle, "󰨞 Agy: toggle")

-- 👉 <Space>G + <Esc> → toggle agy: al haber quitado el mapping pelado de
--    antigravity.lua, <Space>G abre el tablero which-key; Esc lo cierra Y
--    togglea agy. Esta entrada aparece como hija en el tablero (visibilidad).
map_cmd("n", "<Esc>", agy_toggle, "󰨞 Agy: toggle (Esc desde tablero)")

-- Envío de buffers
map_cmd("n", "b", function()
  send_buffer_to_agy()
end, "󰨞 Agy: enviar buffer actual (solo @ruta:1-N)")

map_cmd("n", "B", function()
  send_all_buffers_to_agy()
end, "󰨞 Agy: enviar TODOS los buffers (refs @ruta:1-N)")

-- Slash commands directos
map_cmd("n", "d", function()
  agy_command("/diff")
end, "󰨞 Agy: /diff")

map_cmd("n", "n", function()
  agy_command("/clear")
end, "󰨞 Agy New Session: /clear")

map_cmd("n", "p", function()
  agy_command("/plan")
end, "󰨞 Agy Modo: /plan")

-- map_cmd("n", "L", function()
--   agy_command("/goal")
-- end, "󰨞 Agy: /goal")

-- map_cmd("n", "e", function()
--   agy_command("/grill-me")
-- end, "󰨞 Agy: /grill-me")

map_cmd("n", { "f", "F" }, function()
  agy_command("/fork")
end, "󰨞 Agy Session: /fork")

map_cmd("n", "m", function()
  agy_command("/model")
end, "󰨞 Agy Select: /model")

map_cmd("n", "q", function()
  agy_command("/exit")
end, "󰨞 Agy Quit: /exit")

map_cmd("n", "x", agy_flush_interrupt, "󰨞 Agy Interrupt (ESC / Ctrl+W to close)")

map_cmd("n", "k", function()
  agy_command("/context")
end, "󰨞 Agy Compact / Reducir: /context")

map_cmd("n", "l", function()
  agy_command("/resume")
end, "󰨞 Agy Select Session: /resume")

-- map_cmd("n", "c", function()
--   agy_command("/share")
-- end, "󰨞 Agy Session: /share (link)")

map_cmd("n", "w", function()
  agy_command("/btw")
end, "󰨞 Agy: /btw")

-- map_cmd("n", "s", function()
--   agy_command("/skills")
-- end, "󰨞 Agy: /skills")

-- Focus a la ventana de agy (reemplaza /open)
map_cmd("n", { "o", "g", "G" }, agy_focus, "󰨞 Agy: focus")

-- Atajos nativos del CLI agy (ver /keybindings) vía bytes crudos al terminal:
map_cmd("n", "/", function()
  agy_command("/keybindings")
end, "󰨞 Agy Editar: /keybindings")

--   Undo = ctrl+u, Redo = ctrl+r, ? = panel de shortcuts
map_cmd("n", "u", function()
  agy_send_text("\15")
end, "󰨞 Agy Undo: ctrl+u")

map_cmd("n", "Z", function()
  agy_send_text("\18")
end, "󰨞 Agy Redo: ctrl+r / ctrl+shift+z")

map_cmd("n", "?", function()
  agy_send_text("?")
end, "󰨞 Agy Shortcuts: ?")

-- map_cmd("n", "O", function()
--   agy_command("/open")
-- end, "󰨞 Agy Open: /open")

map_cmd("n", "r", function()
  agy_command("/rename")
end, "󰨞 Agy: /rename")

map_cmd("n", "C", function()
  agy_command("/changelog")
end, "󰨞 Agy: /changelog")
