-- lua/utils/plugin-switcher.lua
-- 🔌 Plugin Toggle & Disable Manager
-- Sincroniza automáticamente con lua/plugins/disabled.lua
-- Soporta toggle interactivo, por categoría y programático

local M = {}

local PLUGINS_CONFIG = {
  -- 🤖 AI Assistants
  avante = {
    name = "Avante",
    icon = "",
    file = "avante-cursor.lua",
    repo = "yetone/avante.nvim",
    category = "AI Assistant",
  },
  -- 🎛️ Avante Auth/ACP Modes (sub-entry para selector de modo)
  avante_mode = {
    name = "Avante · Modo Auth/ACP",
    icon = "󰿆",
     file = "avante-cursor.lua",
    category = "AI Assistant",
    -- Este es un "virtual plugin" que usa el mismo archivo que avante
    -- pero permite cambiar el provider/acp_provider en caliente
    -- Seleccionarlo abre el picker de modo (NO mueve archivos); su estado = el de avante
    virtual = true,
    alias = "avante",
  },
  copilot_chat = {
    name = "CopilotChat",
    icon = "",
    file = "copilot-chat.lua",
    category = "AI Assistant",
  },
  codecompanion = {
    name = "CodeCompanion",
    icon = "",
    file = "code-companion.lua",
    category = "AI Assistant",
  },
  antigravity_cli = {
    name = "Antigravity CLI",
    icon = "󰨞",
    file = "antigravity.lua",
    repo = "NakLast/antigravity-cli.nvim",
    category = "AI Assistant",
  },
  codex_cli = {
    name = "OpenAI Codex CLI",
    icon = "󱚡",
    file = "codex.lua",
    repo = "johnseth97/codex.nvim",
    category = "AI Assistant",
  },
  gemini_cli = {
    name = "Gemini CLI",
    icon = "󰊭",
    file = "gemini-cli.lua",
    category = "AI Assistant",
  },
  crawbot_open = {
    name = "Crawbot Openclaw",
    icon = "󰧑",
    file = "openclaw.lua",
    category = "AI Assistant",
  },
  -- Copilot NES - Next Edit Suggestion [NORMAL mode]
  copilot_nes = {
    name = "Copilot NES [ 󰞑 ] N.3",
    icon = "󰯈",
    file = "copilot.lua",
    alias = "copilot", -- mismo plugin/archivo que copilot: comparten estado
    category = "🔮🛸 Cursor TAB 👾☄️",
  },

  -- ✨ 🔮🛸 Cursor TAB 👾☄️ - Next Edit Suggestion [ghost lines]
  cursortab = {
    name = "CursorTab [ 󰞑 ] N.2",
    icon = "󱙝",
    file = "cursortab.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },
  nextedit = {
    name = "NextEdit [💀]",
    icon = "󱙝",
    file = "nextedit.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },
  neocursor = {
    name = "NeoCursor [ 󰞑 ] N.1",
    icon = "󱙝",
    file = "neocursor.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },
  blink_edit = {
    name = "Blink Edit [💀]",
    icon = "󱙝",
    file = "blink-edit.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },
  sweep_local = {
    name = "Sweep [💀]",
    icon = "󱙝",
    file = "sweep-nvim.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },
  tabtab = {
    name = "TabTab [💀]",
    icon = "󱙝",
    file = "tabtab.lua",
    category = "🔮🛸 Cursor TAB 👾☄️",
  },

  -- 🔮 AI Autocompletion
  copilot = {
    name = "Copilot",
    icon = "",
    file = "copilot.lua",
    repo = "zbirenbaum/copilot.lua",
    category = "AI Completion",
  },
  supermaven = {
    name = "Supermaven",
    icon = "󰓅",
    file = "supermaven.lua",
    repo = "supermaven-inc/supermaven-nvim",
    category = "AI Completion",
  },
  tabnine = {
    name = "TabNine",
    icon = "",
    file = "tabnine.lua",
    category = "AI Completion",
  },
  codeium = {
    name = "Codeium",
    icon = "",
    file = "windsurf-codeium.lua",
    repo = "Exafunction/windsurf.nvim",
    category = "AI Completion",
  },
  fittencode = {
    name = "FittenCode",
    icon = "",
    file = "ai-fittencode.lua",
    category = "AI Completion",
  },
  neocodeium = {
    name = "NeoCodeium",
    icon = "",
    file = "neocodeium.lua",
    category = "AI Completion",
  },

  -- 🎮 OpenCode variants
  opencode = {
    name = "OpenCode (sudo-tee)",
    icon = "󰮮",
    file = "opencode.lua",
    category = "OpenCode",
  },
  opencode_nick = {
    name = "OpenCode (NickvanDyke)",
    icon = "󰮮",
    file = "opencode-chat.lua",
    category = "OpenCode",
  },

  -- 🌟 Claude variants
  claude = {
    name = "Claude Code",
    icon = "",
    file = "claude-code.lua",
    repo = "coder/claudecode.nvim",
    category = "Claude",
  },

  -- 🎨 UI/UX
  bufferline = {
    name = "Bufferline",
    icon = "󰓩",
    file = "bufferline.lua",
    repo = "akinsho/bufferline.nvim",
    category = "UI",
  },
  markdown = {
    name = "Markdown View",
    icon = "",
    file = "markview.lua",
    repo = "OXY2DEV/markview.nvim",
    category = "UI",
  },
  markdownRender = {
    name = "Markdown Render",
    icon = "",
    file = "render-markdown.lua",
    repo = "MeanderingProgrammer/render-markdown.nvim",
    category = "UI",
  },
  snacks = {
    name = "Snacks",
    icon = "",
    file = "snacks.lua",
    repo = "folke/snacks.nvim",
    category = "UI",
  },
  smear_cursor = {
    name = "Smear Cursor",
    icon = "󱄧",
    file = "smear.lua",
    repo = "sphamba/smear-cursor.nvim",
    category = "UI",
  },
  precognition = {
    name = "Precognition",
    icon = "󰗹",
    file = "precognition.lua",
    repo = "tris203/precognition.nvim",
    category = "UI",
  },

  -- 🎮 Discord
  presence = {
    name = "Discord Presence",
    icon = "󰙯",
    file = "presence.lua",
    repo = "andweeb/presence.nvim",
    category = "Discord",
  },
  cord = {
    name = "Cord",
    icon = "󰙯",
    file = "cord.lua",
    repo = "vyfor/cord.nvim",
    category = "Discord",
  },

  -- 📝 Productivity
  todo_comments = {
    name = "Todo Comments",
    icon = "",
    file = "todo-comments.lua",
    repo = "folke/todo-comments.nvim",
    category = "Productivity",
  },
  mcphub = {
    name = "MCPHUB",
    icon = "",
    file = "mcphub-nvim.lua",
    repo = "ravitemer/mcphub.nvim",
    category = "Productivity",
  },
  obsidian = {
    name = "Obsidian",
    icon = "",
    file = "obsidian.lua",
    category = "Productivity",
  },
}

local function get_disabled_path()
  return vim.fn.stdpath("config") .. "/lua/plugins/disabled"
end

local function get_plugins_path()
  return vim.fn.stdpath("config") .. "/lua/plugins"
end

local function get_disabled_lua_path()
  return vim.fn.stdpath("config") .. "/lua/plugins/disabled.lua"
end

-- Devuelve el índice de la primera línea `enabled = ...` en las 30 líneas desde `start`.
-- Si esa línea está COMENTADA (entrada inactiva en disabled.lua) devuelve nil,
-- para que el toggle caiga al sistema de archivos (plugins/ ↔ disabled/).
local function find_enabled_line(content, start)
  for j = start, math.min(start + 30, #content) do
    if content[j]:match("enabled%s*=%s*[a-z]+") then
      if content[j]:match("^%s*%-%-") then
        return nil
      end
      return j
    end
  end
  return nil
end

--- Resuelve alias: entradas que comparten plugin/archivo (copilot_nes → copilot).
---@param plugin_key string
---@return string
local function resolve_key(plugin_key)
  local config = PLUGINS_CONFIG[plugin_key]
  return (config and config.alias) or plugin_key
end

--- Índices de las entradas ACTIVAS (`enabled = ...` sin comentar) del plugin en disabled.lua.
--- Coincide solo contra la parte de código de cada línea (sin comentarios), para no
--- confundir p. ej. "Codeium" con el comentario `-- Codeium: 2/10` de otra entrada.
--- Si hay entradas duplicadas (render-markdown aparece 2 veces) devuelve todas.
---@param content string[] Líneas de disabled.lua
---@param config table Entrada de PLUGINS_CONFIG
---@return integer[] Índices de las líneas `enabled = ...`
local function find_enabled_lines(content, config)
  local found = {}
  for idx, line in ipairs(content) do
    local code = line:gsub("%-%-.*$", "")
    local hit
    if config.repo then
      hit = code:find('"' .. config.repo .. '"', 1, true)
    else
      hit = code:find(config.name, 1, true) or code:find(config.file, 1, true)
    end
    if hit then
      local j = find_enabled_line(content, idx)
      if j then
        table.insert(found, j)
      end
    end
  end
  return found
end

-- ⭐ Sincronizar disabled.lua en tiempo real: reescribe "enabled = true/false"
-- en TODAS las entradas activas del plugin. Devuelve false si no tiene ninguna
-- (→ move_plugin() gestiona por archivo: plugins/ ↔ plugins/disabled/).
local function update_disabled_config(plugin_key, should_disable)
  local config = PLUGINS_CONFIG[plugin_key]
  if not config then
    return false
  end

  local disabled_file = get_disabled_lua_path()
  if vim.fn.filereadable(disabled_file) == 0 then
    vim.notify("❌ disabled.lua no encontrado en " .. disabled_file, vim.log.levels.ERROR)
    return false
  end

  local content = vim.fn.readfile(disabled_file)
  local lines = find_enabled_lines(content, config)
  if #lines == 0 then
    return false
  end

  local value = "enabled = " .. (should_disable and "false" or "true")
  local changed = false
  for _, j in ipairs(lines) do
    local new_line = content[j]:gsub("enabled%s*=%s*[a-z]+", value)
    if new_line ~= content[j] then
      content[j] = new_line
      changed = true
    end
  end
  if changed then
    vim.fn.writefile(content, disabled_file)
  end
  return true
end

--- ¿El spec del plugin está en plugins/disabled/ (y no en plugins/)? → lazy no lo carga.
---@param config table Entrada de PLUGINS_CONFIG
---@return boolean
local function spec_stuck_in_disabled(config)
  return vim.fn.filereadable(get_disabled_path() .. "/" .. config.file) == 1
    and vim.fn.filereadable(get_plugins_path() .. "/" .. config.file) == 0
end

-- Move plugin file between lua/plugins/ and lua/plugins/disabled/
local function move_plugin(plugin_key, to_disabled)
  local config = PLUGINS_CONFIG[plugin_key]
  if not config then
    vim.notify("󰜺 Plugin desconocido: " .. plugin_key, vim.log.levels.ERROR)
    return false
  end

  -- Toggle SIMÉTRICO, las dos vías a la par (cada una solo si aplica):
  --   1) disabled.lua: `enabled = true/false` si el plugin tiene entrada activa.
  --   2) archivo: mover el .lua entre plugins/ ↔ plugins/disabled/ si existe en el origen.
  local managed = update_disabled_config(plugin_key, to_disabled)

  local from_dir = to_disabled and get_plugins_path() or get_disabled_path()
  local to_dir = to_disabled and get_disabled_path() or get_plugins_path()
  local from_file = from_dir .. "/" .. config.file
  local to_file = to_dir .. "/" .. config.file

  local moved, move_failed = false, false
  if vim.fn.filereadable(from_file) == 1 then
    vim.fn.mkdir(to_dir, "p")
    moved = vim.fn.rename(from_file, to_file) == 0
    move_failed = not moved
  end

  if move_failed then
    vim.notify("❌ Error moviendo " .. config.name, vim.log.levels.ERROR)
    return false
  end

  if not managed and not moved then
    vim.notify(
      "⚠️  " .. config.icon .. " " .. config.name .. " — Ya está " .. (to_disabled and "desactivado" or "activado"),
      vim.log.levels.INFO
    )
    return false
  end

  local detail = {}
  if managed then
    table.insert(detail, "💾 disabled.lua → enabled = " .. tostring(not to_disabled))
  end
  if moved then
    table.insert(detail, "📁 " .. config.file .. " → " .. (to_disabled and "plugins/disabled/" or "plugins/"))
  end
  vim.notify(
    (to_disabled and "❌ Desactivado" or "✅ Activado")
      .. ": "
      .. config.icon
      .. " "
      .. config.name
      .. "\n\n"
      .. table.concat(detail, "\n")
      .. "\n🔄 Reinicia Neovim para aplicar cambios",
    vim.log.levels.WARN
  )
  return true
end

-- Comprobar si un plugin está desactivado (en disabled.lua o en la carpeta disabled/)
local function is_plugin_disabled(plugin_key)
  plugin_key = resolve_key(plugin_key)
  local config = PLUGINS_CONFIG[plugin_key]
  if not config then
    return false
  end

  -- Primero verificar en disabled.lua
  local disabled_file = get_disabled_lua_path()
  if vim.fn.filereadable(disabled_file) == 1 then
    local content = vim.fn.readfile(disabled_file)
    local lines = find_enabled_lines(content, config)
    if #lines > 0 then
      for _, j in ipairs(lines) do
        if content[j]:match("enabled%s*=%s*false") then
          return true
        end
      end
      -- `enabled = true` pero el spec atrapado en disabled/ = cargado sin config → off
      return spec_stuck_in_disabled(config)
    end
  end

  -- Fallback: verificar si existe en carpeta disabled/
  local disabled_file_path = get_disabled_path() .. "/" .. config.file
  return vim.fn.filereadable(disabled_file_path) == 1
end

-- ── 🎛  Presets de neocursor (modo = host/usage_host) ──────────────
-- Cada modo reescribe `host` y `usage_host` en lua/plugins/neocursor.lua.
-- LÓGICA CONDICIONAL (ciclo include-toggle):
--   · neocursor ya activo en ESTE modo → desactivar (mueve a disabled/)
--   · neocursor off o en OTRO modo      → activar/cambiar a este modo
local NEOCURSOR_FILE = "neocursor.lua"
local NEOCURSOR_PRESETS = {
  ["cursor"] = { host = "cursor", usage_host = "cursor" },
  ["antigravity"] = { host = "antigravity", usage_host = "antigravity" },
  ["antigravity-tui"] = { host = "antigravity", usage_host = "antigravity-tui" },
}

-- ¿Dónde vive neocursor.lua hoy? (plugins/ activo · disabled/ off)
local function neocursor_active_file()
  local active = get_plugins_path() .. "/" .. NEOCURSOR_FILE
  if vim.fn.filereadable(active) == 1 then
    return active, true
  end
  local dis = get_disabled_path() .. "/" .. NEOCURSOR_FILE
  if vim.fn.filereadable(dis) == 1 then
    return dis, false
  end
  return active, true -- asume activo si no existe en ningún lado
end

-- Estado actual: { enabled, host, usage_host }
local function neocursor_current()
  local file, enabled = neocursor_active_file()
  local host, usage_host = "cursor", "cursor"
  if vim.fn.filereadable(file) == 1 then
    for _, line in ipairs(vim.fn.readfile(file)) do
      if not line:match("^%s*%-%-") then -- ignorar comentarios
        local h = line:match('host%s*=%s*"([^"]+)"%s*,')
        if h then
          host = h
        end
        local uh = line:match('usage_host%s*=%s*"([^"]+)"%s*,')
        if uh then
          usage_host = uh
        end
      end
    end
  end
  return { enabled = enabled, host = host, usage_host = usage_host }, file
end

-- Reescribe host/usage_host en el archivo activo de neocursor.
local function neocursor_apply(mode)
  local preset = NEOCURSOR_PRESETS[mode]
  if not preset then
    return false
  end
  local cur, _ = neocursor_current()
  -- si está off, primero reactivar (mover de disabled/ a plugins/)
  if not cur.enabled then
    move_plugin("neocursor", false)
  end
  local f, _ = neocursor_active_file()
  if vim.fn.filereadable(f) ~= 1 then
    vim.notify("⚠️ neocursor.lua no encontrado", vim.log.levels.ERROR)
    return false
  end
  local content = vim.fn.readfile(f)
  local host_str = ('host = "%s",'):format(preset.host)
  local usage_str = ('usage_host = "%s",'):format(preset.usage_host)
  local changed = false
  for i, line in ipairs(content) do
    if line:match('^%s*host%s*=%s*"[^"]*"%s*,') then
      if not line:find(host_str, 1, true) then
        content[i] = line:gsub('host%s*=%s*"[^"]*"', ('host = "%s"'):format(preset.host))
        changed = true
      end
    elseif line:match('^%s*usage_host%s*=%s*"[^"]*"%s*,') then
      if not line:find(usage_str, 1, true) then
        content[i] = line:gsub('usage_host%s*=%s*"[^"]*"', ('usage_host = "%s"'):format(preset.usage_host))
        changed = true
      end
    end
  end
  if changed then
    vim.fn.writefile(content, f)
  end
  return true
end

-- ⭐ FUNCIÓN PÚBLICA: preset de neocursor (ciclo include-toggle)
function M.preset_neocursor(mode)
  local preset = NEOCURSOR_PRESETS[mode]
  if not preset then
    vim.notify("⚠️ Modo neocursor desconocido: " .. tostring(mode), vim.log.levels.ERROR)
    return
  end
  local cur, _ = neocursor_current()
  local label = mode == "antigravity-tui" and "antigravity-tui (agy TUI)" or mode
  if cur.enabled and cur.host == preset.host and cur.usage_host == preset.usage_host then
    move_plugin("neocursor", true)
    vim.notify("󱙝 neocursor ❌ desactivado (modo " .. label .. ")", vim.log.levels.INFO)
    return
  end
  neocursor_apply(mode)
  vim.notify("󱙝 neocursor → modo " .. label .. "\n🔄 Reinicia Neovim para aplicar", vim.log.levels.INFO)
end

-- ⭐ FUNCIÓN PÚBLICA: abrir el selector de modo neocursor directo
function M.neocursor_mode_picker()
  local cur, _ = neocursor_current()
  local choices = {}
  local map = {}
  for mode, preset in pairs(NEOCURSOR_PRESETS) do
    local active = cur.enabled and cur.host == preset.host and cur.usage_host == preset.usage_host
    local mark = active and "󰗠  |" or (not cur.enabled and "🚫  |" or "  |")
    local label = mode == "antigravity-tui" and "Antigravity TUI (agy /usage)"
      or (mode == "antigravity" and "Antigravity (RPC usage)" or "Cursor")
    local choice = ("  %s 󱙝 %s"):format(mark, label)
    table.insert(choices, choice)
    map[choice] = mode
  end
  table.insert(choices, "󰜺 Cancelar")
  vim.ui.select(choices, {
    prompt = "󱙝 neocursor · backend del tab / usage :",
  }, function(choice)
    if not choice or choice:match("󰜺") then
      return
    end
    M.preset_neocursor(map[choice])
  end)
end

-- ⭐ FUNCIÓN PÚBLICA: Toggle plugin
function M.toggle_plugin(plugin_key)
  local config = PLUGINS_CONFIG[plugin_key]
  if config and config.virtual then
    -- Entrada virtual (avante_mode): abre el selector de modo, no mueve archivos
    M.avante_mode_picker()
    return
  end
  plugin_key = resolve_key(plugin_key)
  local is_disabled = is_plugin_disabled(plugin_key)
  move_plugin(plugin_key, not is_disabled)
end

-- ⭐ FUNCIÓN PÚBLICA: Deshabilitar plugin
function M.disable_plugin(plugin_key)
  plugin_key = resolve_key(plugin_key)
  if not is_plugin_disabled(plugin_key) then
    move_plugin(plugin_key, true)
  else
    vim.notify("ℹ️  " .. PLUGINS_CONFIG[plugin_key].name .. " ya está desactivado", vim.log.levels.INFO)
  end
end

-- ⭐ FUNCIÓN PÚBLICA: Habilitar plugin
function M.enable_plugin(plugin_key)
  plugin_key = resolve_key(plugin_key)
  if is_plugin_disabled(plugin_key) then
    move_plugin(plugin_key, false)
  else
    vim.notify("ℹ️  " .. PLUGINS_CONFIG[plugin_key].name .. " ya está activado", vim.log.levels.INFO)
  end
end

-- ⭐ FUNCIÓN PÚBLICA: UI interactiva con categorías
function M.interactive_toggle()
  local choices = {}
  local choices_map = {}
  local categories = {}

  -- Agrupar plugins por categoría
  for key, config in pairs(PLUGINS_CONFIG) do
    if not categories[config.category] then
      categories[config.category] = {}
    end
    table.insert(categories[config.category], {
      key = key,
      config = config,
      disabled = is_plugin_disabled(key),
    })
  end

  -- Ordenar categorías
  local category_order = {
    "🔮🛸 Cursor TAB 👾☄️",
    "AI Assistant",
    "AI Completion",
    "OpenCode",
    "Claude",
    "UI",
    "Discord",
    "Productivity",
  }

  -- Construir lista de opciones
  for _, cat_name in ipairs(category_order) do
    local plugins = categories[cat_name]
    if plugins then
      -- Header de categoría
      table.insert(choices, "─── " .. cat_name .. " ───")

      -- Plugins de la categoría (ordenados alfabéticamente)
      table.sort(plugins, function(a, b)
        return a.config.name < b.config.name
      end)

      for _, item in ipairs(plugins) do
        local status = item.disabled and "🚫 |" or "󰗠  |"
        local choice_text = "  " .. status .. " " .. item.config.icon .. " " .. item.config.name
        table.insert(choices, choice_text)
        choices_map[choice_text] = item.key
        -- Entrada extra: neocursor tiene presets de modo (host/usage_host).
        if item.key == "neocursor" then
          local cur, _ = neocursor_current()
          local mode = cur.host
          if cur.host == "antigravity" and cur.usage_host == "antigravity-tui" then
            mode = "antigravity-tui"
          end
          local mode_status = cur.enabled and ("󰗠 " .. mode) or "🚫 (off)"
          local mode_text = ("    ⚙️   modo: %s"):format(mode_status)
          table.insert(choices, mode_text)
          choices_map[mode_text] = "__neocursor_mode__"
        end
        -- Entrada extra: avante_mode tiene presets de Auth/ACP.
        if item.key == "avante_mode" then
          local cur, _ = M.avante_current()
          local mode_status = cur.enabled and ("󰗠 " .. cur.provider) or "🚫 (off)"
          local mode_text = ("    ⚙️   modo: %s"):format(mode_status)
          table.insert(choices, mode_text)
          choices_map[mode_text] = "__avante_mode__"
        end
      end
    end
  end

  table.insert(choices, "─────────────────")
  table.insert(choices, "❌ Cancelar")

  vim.ui.select(choices, {
    prompt = "🔌 Toggle Plugin/Disable 󰯈 󰯇 :",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice or choice:match("󰜺") or choice:match("^───") or choice:match("❌") then
      return
    end

    local plugin_key = choices_map[choice]
    if plugin_key == "__neocursor_mode__" then
      M.neocursor_mode_picker()
      return
    end
    if plugin_key == "__avante_mode__" then
      M.avante_mode_picker()
      return
    end
    if plugin_key then
      M.toggle_plugin(plugin_key)
    end
  end)
end

-- ⭐ FUNCIÓN PÚBLICA: UI para toggle por categoría
function M.toggle_by_category(category)
  local plugins = {}

  for key, config in pairs(PLUGINS_CONFIG) do
    if config.category == category then
      table.insert(plugins, {
        key = key,
        config = config,
        disabled = is_plugin_disabled(key),
      })
    end
  end

  if #plugins == 0 then
    vim.notify("⚠️  No hay plugins en la categoría: " .. category, vim.log.levels.WARN)
    return
  end

  local choices = {}
  local choices_map = {}

  table.sort(plugins, function(a, b)
    return a.config.name < b.config.name
  end)

  for _, item in ipairs(plugins) do
    local status = item.disabled and "🚫  |" or "✅  |"
    local choice_text = status .. " " .. item.config.icon .. " " .. item.config.name
    table.insert(choices, choice_text)
    choices_map[choice_text] = item.key
  end

  table.insert(choices, "󰜺 Cancelar")

  vim.ui.select(choices, {
    prompt = "🔌 " .. category .. " :",
  }, function(choice)
    if not choice or choice:match("󰜺") then
      return
    end

    local plugin_key = choices_map[choice]
    if plugin_key then
      M.toggle_plugin(plugin_key)
    end
  end)
end

-- ⭐ Shortcuts para categorías comunes
function M.toggle_ai_completion()
  M.toggle_by_category("AI Completion")
end

function M.toggle_ai_assistant()
  M.toggle_by_category("AI Assistant")
end

function M.toggle_discord()
  M.toggle_by_category("Discord")
end

function M.toggle_cursor_tab()
  M.toggle_by_category("🔮🛸 Cursor TAB 👾☄️")
end

-- ⭐ FUNCIÓN PÚBLICA: Obtener estado de un plugin
function M.is_disabled(plugin_key)
  return is_plugin_disabled(plugin_key)
end

-- ⭐ FUNCIÓN PÚBLICA: Obtener config de un plugin
function M.get_plugin_config(plugin_key)
  return PLUGINS_CONFIG[plugin_key]
end

-- =============================================================================
-- 🎛️ AVANTE PRESETS — Modos de Auth/ACP (similar a neocursor)
-- =============================================================================
local AVANTE_FILE = "avante-cursor.lua"
local AVANTE_PRESETS = {
  -- OAuth modes (native Avante OAuth)
  ["max"] = {
    auth_type = "max",
    provider = "claude",
    description = "Claude Pro/Max (OAuth nativo, auth_type=max)",
  },
  ["copilot"] = {
    auth_type = "api", -- copilot usa token de copilot.lua
    provider = "copilot",
    description = "GitHub Copilot (token OAuth de copilot.lua)",
  },

  -- ACP modes (Agent Client Protocol - CLIs externos)
  ["agy-acp"] = {
    provider = "agy-acp",
    description = "Antigravity CLI (agy acp) — gratis, sin key",
  },
  ["codex"] = {
    provider = "codex",
    description = "Codex CLI (codex-acp) — ChatGPT Plus/Pro",
  },
  ["openrouter"] = {
    provider = "openrouter",
    description = "OpenRouter API (comentado en config, requiere descomentar)",
  },
  ["opencode"] = {
    provider = "opencode",
    description = "OpenCode (opencode acp) — suscripción OpenCode",
  },
  ["claude-code"] = {
    provider = "claude-code",
    description = "Claude Code (claude-agent-acp) — usa `claude` CLI = Pro/Max",
  },
}

-- ¿Dónde vive avante-cursor.lua hoy? (plugins/ activo · disabled/ off)
local function avante_active_file()
  local active = get_plugins_path() .. "/" .. AVANTE_FILE
  if vim.fn.filereadable(active) == 1 then
    return active, true
  end
  local dis = get_disabled_path() .. "/" .. AVANTE_FILE
  if vim.fn.filereadable(dis) == 1 then
    return dis, false
  end
  return active, true -- asume activo si no existe en ningún lado
end

--- Índice del PRIMER `provider =` no comentado (top-level de opts). Los siguientes
--- son file_selector.provider / windows.input.provider (= "snacks") y NO se tocan.
---@param content string[]
---@return integer|nil
local function avante_provider_line(content)
  for i, line in ipairs(content) do
    if not line:match("^%s*%-%-") and line:match("^%s*provider%s*=") then
      return i
    end
  end
  return nil
end

--- Estado actual leído del ARCHIVO (no de la config runtime: esa no refleja un
--- preset recién escrito hasta reiniciar, y hacer require() cargaría Avante).
---@return table { enabled, provider, auth_type }
---@return string Ruta del spec
local function avante_current()
  local file = avante_active_file()
  local provider, auth_type = "opencode", "api"

  if vim.fn.filereadable(file) == 1 then
    local content = vim.fn.readfile(file)
    local i = avante_provider_line(content)
    if i then
      -- provider = (function() ... end)() → auto-detección en runtime
      provider = content[i]:match('provider%s*=%s*"([^"]+)"') or "auto"
    end
    for _, line in ipairs(content) do
      local a = not line:match("^%s*%-%-") and line:match('^%s*auth_type%s*=%s*"([^"]+)"')
      if a then
        auth_type = a
        break
      end
    end
  end

  -- enabled real = spec en plugins/ Y no `enabled = false` en disabled.lua
  return { enabled = not is_plugin_disabled("avante"), provider = provider, auth_type = auth_type }, file
end

-- Reescribe provider/auth_type en el archivo activo de avante.
local function avante_apply(mode)
  local preset = AVANTE_PRESETS[mode]
  if not preset then
    return false
  end
  local cur, _ = avante_current()
  if not cur.enabled then
    move_plugin("avante", false)
  end
  local f = avante_active_file()
  if vim.fn.filereadable(f) ~= 1 then
    vim.notify("⚠️ avante-cursor.lua no encontrado", vim.log.levels.ERROR)
    return false
  end
  local content = vim.fn.readfile(f)
  local changed = false
  local new_provider = ('provider = "%s"'):format(preset.provider)

  local p = avante_provider_line(content)
  if p then
    local line = content[p]
    if line:match('^%s*provider%s*=%s*"[^"]*"') then
      -- Caso 1: provider = "string"
      if not line:find(new_provider, 1, true) then
        content[p] = line:gsub('provider%s*=%s*"[^"]*"', new_provider)
        changed = true
      end
    elseif line:match("^%s*provider%s*=%s*%(") then
      -- Caso 2: provider = (function() ... end)() multilínea → reemplazar el
      -- bloque COMPLETO hasta su `end)()` con la misma indentación.
      local indent = line:match("^(%s*)")
      local last = line:match("end%)%(%)") and p or nil
      for k = p + 1, last and 0 or #content do
        if content[k]:match("^" .. indent .. "end%)%(%)") then
          last = k
          break
        end
      end
      if not last then
        vim.notify("❌ No se encontró el cierre `end)()` del provider en " .. AVANTE_FILE, vim.log.levels.ERROR)
        return false
      end
      for _ = p + 1, last do
        table.remove(content, p + 1)
      end
      content[p] = indent .. new_provider .. ","
      changed = true
    end
  end

  if preset.auth_type then
    local new_auth = ('auth_type = "%s"'):format(preset.auth_type)
    for i, line in ipairs(content) do
      if not line:match("^%s*%-%-") and line:match('^%s*auth_type%s*=%s*"[^"]*"') and not line:find(new_auth, 1, true) then
        content[i] = line:gsub('auth_type%s*=%s*"[^"]*"', new_auth)
        changed = true
      end
    end
  end

  if changed then
    vim.fn.writefile(content, f)
  end
  return true
end

-- ⭐ FUNCIÓN PÚBLICA: preset de Avante (ciclo include-toggle)
function M.preset_avante(mode)
  local preset = AVANTE_PRESETS[mode]
  if not preset then
    vim.notify("⚠️ Modo Avante desconocido: " .. tostring(mode), vim.log.levels.ERROR)
    return
  end
  local cur, _ = avante_current()
  local label = preset.description
  if cur.enabled and cur.provider == preset.provider and (not preset.auth_type or cur.auth_type == preset.auth_type) then
    move_plugin("avante", true)
    vim.notify(" Avante ❌ desactivado (modo " .. label .. ")", vim.log.levels.INFO)
    return
  end
  avante_apply(mode)
  vim.notify(" Avante → modo " .. label .. "\n🔄 Reinicia Neovim para aplicar", vim.log.levels.INFO)
end

-- ⭐ FUNCIÓN PÚBLICA: abrir el selector de modo Avante directo
function M.avante_mode_picker()
  local cur, _ = avante_current()
  local choices = {}
  local map = {}
  for mode, preset in pairs(AVANTE_PRESETS) do
    local active = cur.enabled and cur.provider == preset.provider and (not preset.auth_type or cur.auth_type == preset.auth_type)
    local mark = active and "󰗠  |" or (not cur.enabled and "🚫  |" or "  |")
    local choice = ("  %s 󰿆 %s"):format(mark, preset.description)
    table.insert(choices, choice)
    map[choice] = mode
  end
  table.insert(choices, "󰜺 Cancelar")
  vim.ui.select(choices, {
    prompt = "󰿆 Avante · Modo Auth/ACP :",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice or choice:match("󰜺") then
      return
    end
    M.preset_avante(map[choice])
  end)
end

-- ⭐ FUNCIÓN PÚBLICA: estado actual de Avante (provider/auth_type)
M.avante_current = avante_current

return M
