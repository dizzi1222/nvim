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
    category = "AI Assistant",
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
    category = "AI Completion",
  },
  supermaven = {
    name = "Supermaven",
    icon = "󰓅",
    file = "supermaven.lua",
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
    category = "UI",
  },
  markdownRender = {
    name = "Markdown Render",
    icon = "",
    file = "render-markdown.nvim",
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
    file = "smear-cursor.lua",
    repo = "sphamba/smear-cursor.nvim",
    category = "UI",
  },
  precognition = {
    name = "Precognition",
    icon = "󰗹",
    file = "precognition.lua",
    category = "UI",
  },

  -- 🎮 Discord
  presence = {
    name = "Discord Presence",
    icon = "󰙯",
    file = "presence.lua",
    category = "Discord",
  },
  cord = {
    name = "Cord",
    icon = "󰙯",
    file = "cord.lua",
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

-- ⭐ NUEVA FUNCIÓN: Sincronizar disabled.lua en tiempo real
-- Busca en disabled.lua y actualiza el field "enabled = true/false"
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
  local modified = false
  local plugin_found = false
  local i = 1

  -- Función auxiliar para encontrar la línea del plugin
  local function find_plugin_line()
    for idx, line in ipairs(content) do
      -- Primero intentar con repo exacto (si existe)
      if config.repo and line:find(config.repo, 1, true) then
        return idx
      end
      -- Fallback: buscar por nombre o archivo (mantener compatibilidad)
      if not config.repo then
        local name_match = line:find(config.name, 1, true)
        local file_match = line:find(config.file, 1, true)
        if name_match or file_match then
          return idx
        end
      end
    end
    return nil
  end

  i = find_plugin_line()
  if not i then
    -- No tiene entrada en disabled.lua → se gestiona por sistema de
    -- archivos (mover el .lua entre plugins/ y plugins/disabled/). No emitimos
    -- aviso aquí: move_plugin() hará el fallback y ya notifica su propio
    -- "Activado/Desactivado". Evita la falsa alarma del toggle por archivo.
    return false
  end

  -- Busca la línea "enabled = true/false" en los siguientes 15 líneas
  local modified = false
  for j = i, math.min(i + 30, #content) do
    if content[j]:match("enabled%s*=%s*[a-z]+") then
      local old_line = content[j]
      local new_line = old_line:gsub("enabled%s*=%s*[a-z]+", "enabled = " .. (should_disable and "false" or "true"))

      if new_line ~= old_line then
        content[j] = new_line
        modified = true
        break
      end
    end
  end

  if modified then
    vim.fn.writefile(content, disabled_file)
  end

  return modified
end

-- Move plugin file between lua/plugins/ and lua/plugins/disabled/
local function move_plugin(plugin_key, to_disabled)
  local config = PLUGINS_CONFIG[plugin_key]
  if not config then
    vim.notify("󰜺 Plugin desconocido: " .. plugin_key, vim.log.levels.ERROR)
    return false
  end

  -- Primero intentar sincronizar con disabled.lua
  if update_disabled_config(plugin_key, to_disabled) then
    local status = to_disabled and "❌ Desactivado" or "✅ Activado"
    vim.notify(
      status
        .. ": "
        .. config.icon
        .. " "
        .. config.name
        .. "\n\n💾 disabled.lua actualizado\n🔄 Reinicia Neovim (o :e lua/plugins/disabled.lua)",
      vim.log.levels.INFO
    )
    return true
  end

  -- Fallback: usar sistema de archivos (para plugins sin entrada en disabled.lua)
  local from_dir = to_disabled and get_plugins_path() or get_disabled_path()
  local to_dir = to_disabled and get_disabled_path() or get_plugins_path()

  local from_file = from_dir .. "/" .. config.file
  local to_file = to_dir .. "/" .. config.file

  -- Verificar que el archivo origen existe
  if vim.fn.filereadable(from_file) ~= 1 then
    vim.notify(
      "⚠️  "
        .. config.icon
        .. " "
        .. config.name
        .. " — Ya está "
        .. (to_disabled and "desactivado" or "activado")
        .. " (gestionado por disabled.lua)",
      vim.log.levels.INFO
    )
    return false
  end

  -- Crear directorio destino si no existe
  vim.fn.mkdir(to_dir, "p")

  -- Mover archivo
  local success = vim.fn.rename(from_file, to_file) == 0

  if success then
    local status = to_disabled and "❌ Desactivado" or "✅ Activado"
    vim.notify(
      status .. ": " .. config.icon .. " " .. config.name .. "\n\n🔄 Reinicia Neovim para aplicar cambios",
      vim.log.levels.WARN
    )
    return true
  else
    vim.notify("❌ Error moviendo " .. config.name, vim.log.levels.ERROR)
    return false
  end
end

-- Comprobar si un plugin está desactivado (en disabled.lua o en la carpeta disabled/)
local function is_plugin_disabled(plugin_key)
  local config = PLUGINS_CONFIG[plugin_key]
  if not config then
    return false
  end

  -- Primero verificar en disabled.lua
  local disabled_file = get_disabled_lua_path()
  if vim.fn.filereadable(disabled_file) == 1 then
    local content = vim.fn.readfile(disabled_file)

    -- Función auxiliar para encontrar la línea del plugin
    local function find_plugin_line()
      for idx, line in ipairs(content) do
        -- Primero intentar con repo exacto (si existe)
        if config.repo and line:find(config.repo, 1, true) then
          return idx
        end
        -- Fallback: buscar por nombre o archivo (mantener compatibilidad)
        if not config.repo then
          local name_match = line:find(config.name, 1, true)
          local file_match = line:find(config.file, 1, true)
          if name_match or file_match then
            return idx
          end
        end
      end
      return nil
    end

    local i = find_plugin_line()
    if i then
      -- Buscar "enabled = true/false" en los siguientes 30 líneas
      for j = i, math.min(i + 30, #content) do
        if content[j]:match("enabled%s*=%s*false") then
          return true -- Plugin está desactivado
        elseif content[j]:match("enabled%s*=%s*true") then
          return false -- Plugin está activado
        end
      end
    end
  end

  -- Fallback: verificar si existe en carpeta disabled/
  local disabled_file_path = get_disabled_path() .. "/" .. config.file
  return vim.fn.filereadable(disabled_file_path) == 1
end

-- ⭐ FUNCIÓN PÚBLICA: Toggle plugin
function M.toggle_plugin(plugin_key)
  local is_disabled = is_plugin_disabled(plugin_key)
  move_plugin(plugin_key, not is_disabled)
end

-- ⭐ FUNCIÓN PÚBLICA: Deshabilitar plugin
function M.disable_plugin(plugin_key)
  if not is_plugin_disabled(plugin_key) then
    move_plugin(plugin_key, true)
  else
    vim.notify("ℹ️  " .. PLUGINS_CONFIG[plugin_key].name .. " ya está desactivado", vim.log.levels.INFO)
  end
end

-- ⭐ FUNCIÓN PÚBLICA: Habilitar plugin
function M.enable_plugin(plugin_key)
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

-- ⭐ FUNCIÓN PÚBLICA: Listar todos los plugins
function M.list_plugins()
  return PLUGINS_CONFIG
end

return M
