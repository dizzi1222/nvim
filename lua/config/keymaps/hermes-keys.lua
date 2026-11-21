local terminal = require("utils.hermes-terminal")

local function visual_selection(buf)
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  local first_line, first_col = anchor[2], anchor[3]
  local last_line, last_col = cursor[2], cursor[3]

  if first_line > last_line or (first_line == last_line and first_col > last_col) then
    first_line, last_line = last_line, first_line
    first_col, last_col = last_col, first_col
  end

  local first_row = first_line - 1
  local last_row = last_line - 1
  if mode == "V" then
    return table.concat(vim.api.nvim_buf_get_lines(buf, first_row, last_row + 1, false), "\n")
  end

  if mode == "\22" then
    local lines = vim.api.nvim_buf_get_lines(buf, first_row, last_row + 1, false)
    local left_col = math.min(anchor[3], cursor[3])
    local right_col = math.max(anchor[3], cursor[3])
    for index, line in ipairs(lines) do
      lines[index] = line:sub(left_col, right_col)
    end
    return table.concat(lines, "\n")
  end

  return table.concat(
    vim.api.nvim_buf_get_text(buf, first_row, first_col - 1, last_row, last_col, {}),
    "\n"
  )
end

local function build_context()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local file_name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[buffer sin guardar]"
  local project_root = terminal.project_root()
  local project = vim.fn.fnamemodify(project_root, ":t")
  local filetype = vim.bo[buf].filetype
  local line = vim.fn.line(".")
  local system = vim.fn.has("wsl") == 1 and "WSL" or vim.loop.os_uname().sysname
  local code = visual_selection(buf)

  if code == nil then
    local count = math.min(100, vim.api.nvim_buf_line_count(buf))
    code = table.concat(vim.api.nvim_buf_get_lines(buf, 0, count, false), "\n")
  end

  local display_path = path ~= "" and path or "[buffer sin guardar]"
  local language = filetype ~= "" and filetype or "text"
  return string.format(
    "📁 Proyecto: %s\n📄 Archivo: %s\n📂 Ruta: %s\n🔤 Tipo: %s\n📍 Línea: %d\n💻 Sistema: %s\n\n```%s\n%s\n```\n",
    project,
    file_name,
    display_path,
    language,
    line,
    system,
    language,
    code
  )
end

local function send_context()
  terminal.send_context(build_context())
end

local function buffer_reference(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return nil
  end

  return "@file:" .. path .. ":1-" .. vim.api.nvim_buf_line_count(buf)
end

local function send_buffer()
  local reference = buffer_reference(vim.api.nvim_get_current_buf())
  if reference then
    terminal.send_context(reference)
  else
    vim.notify("Hermes: el buffer actual no tiene un archivo guardado", vim.log.levels.WARN)
  end
end

local function send_all_buffers()
  local references = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local reference = buffer_reference(buf)
    if reference then
      references[#references + 1] = reference
    end
  end

  if #references > 0 then
    terminal.send_context(table.concat(references, "\n"))
  else
    vim.notify("Hermes: no hay buffers de archivo para enviar", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>ht", function()
  local has_vps = terminal.profile_has_vps_config and terminal.profile_has_vps_config("vps")
  if has_vps then
    vim.ui.select({ "default", "vps" }, { prompt = "Hermes: Seleccionar perfil: " }, function(choice)
      if choice then
        if choice == "default" then
          terminal.smart_toggle()
        else
          terminal.smart_toggle_profile(choice)
        end
      end
    end)
  else
    terminal.smart_toggle()
  end
end, { desc = "Hermes: Abrir TUI (selector si hay VPS)" })

vim.keymap.set("n", "<leader>hc", terminal.focus_and_resume, { desc = "Hermes: Reanudar + abrir selector de sesiones (Ctrl+X)" })
vim.keymap.set("n", "<leader>ho", terminal.focus, { desc = "Hermes: Enfocar TUI" })
vim.keymap.set({ "n", "x" }, "<leader>hs", send_context, { desc = "Hermes: Enviar contexto al prompt" })
vim.keymap.set("n", "<leader>hb", send_buffer, { desc = "Hermes: Enviar buffer actual" })
vim.keymap.set("n", "<leader>hB", send_all_buffers, { desc = "Hermes: Enviar todos los buffers" })

local slash_mappings = {
  { "<leader>hn", "/new", "Hermes: Nueva sesión", 300 },
  { "<leader>hl", "/sessions", "Hermes: Seleccionar sesión" },
  { "<leader>hF", "/fork --here", "Hermes: Bifurcar sesión aquí" },
  { "<leader>hm", "/model", "Hermes: Cambiar modelo" },
  { "<leader>hu", "/rewind", "Hermes: Deshacer turno" },
  { "<leader>hr", "/retry", "Hermes: Reintentar último mensaje" },
  { "<leader>hx", "/stop", "Hermes: Detener procesos en segundo plano" },
  { "<leader>hk", "/compress", "Hermes: Comprimir contexto" },
  { "<leader>he", "/save md", "Hermes: Exportar conversación en Markdown" },
  { "<leader>hi", "/context", "Hermes: Ver uso del contexto" },
  { "<leader>hS", "/status", "Hermes: Ver estado de sesión" },
  { "<leader>hv", "/voice", "Hermes: Alternar voz" },
  { "<leader>hvo", "/voice on", "Hermes: Activar voz" },
  { "<leader>hvf", "/voice off", "Hermes: Desactivar voz" },
  { "<leader>hvs", "/voice status", "Hermes: Ver estado de voz" },
  { "<leader>hvt", "/voice tts", "Hermes: Alternar voz TTS" },
  { "<leader>hL", "/limpieza", "Hermes: Limpieza del sistema" },
}

for _, mapping in ipairs(slash_mappings) do
  local lhs, command, description, submit_delay_ms = mapping[1], mapping[2], mapping[3], mapping[4]
  vim.keymap.set("n", lhs, function()
    terminal.send_command(command, submit_delay_ms)
  end, { desc = description })
end

vim.keymap.set("n", "<leader>hw", function()
  vim.ui.input({ prompt = "Hermes /btw: " }, function(question)
    if question == nil then
      return
    end

    question = vim.trim(question):gsub("[\r\n]+", " ")
    if question ~= "" then
      terminal.send_command("/btw " .. question)
    end
  end)
end, { desc = "Hermes: Pregunta lateral (/btw)" })

vim.keymap.set("n", "<leader>hq", function()
  vim.ui.input({ prompt = "Hermes /queue <prompt>: " }, function(prompt)
    if prompt == nil then
      return
    end

    prompt = vim.trim(prompt):gsub("[\r\n]+", " ")
    if prompt ~= "" then
      terminal.send_command("/queue " .. prompt)
    end
  end)
end, { desc = "Hermes: Encolar prompt para el siguiente turno" })

vim.keymap.set("n", "<leader>hR", function()
  vim.ui.input({ prompt = "Nuevo título de sesión: " }, function(title)
    if title == nil then
      return
    end
    title = vim.trim(title)
    if title ~= "" then
      terminal.send_command("/title " .. title)
    end
  end)
end, { desc = "Hermes: Renombrar sesión actual (/title)" })