-- =============================================================
-- KEYMAPS OPENAI CODEX (johnseth97/codex.nvim)
-- =============================================================
-- Prefijo principal: <leader>cx  |  espejo corto: <leader>X
-- Libres al momento de instalar. Se evita <leader>ac/<leader>ax (OpenCode),
-- <leader>cc (CccConvert) y <leader>xx (Trouble).
--
--   t toggle       f focus       b buffer actual    B todos los buffers
--   n /new         l /resume     F /fork            d /diff
--   m /model       k /compact    r /review          x interrumpir
--   q /quit        ? /help       P menú de prompts
--   Visual <leader>cx o <leader>X: menú con referencia @ruta:start-end
-- =============================================================

local keymap = vim.keymap
local prefixes = { "<leader>cx", "<leader>X" }

local function state()
  local ok, codex_state = pcall(require, "codex.state")
  return ok and codex_state or nil
end

local function live_channel()
  local codex_state = state()
  if not codex_state or not codex_state.buf or not vim.api.nvim_buf_is_valid(codex_state.buf) then
    return nil
  end
  local channel = vim.bo[codex_state.buf].channel
  return channel and channel > 0 and channel or nil
end

local function send(text, focus)
  local channel = live_channel()
  if channel then
    vim.api.nvim_chan_send(channel, text)
    if focus ~= false then
      require("codex").open()
      vim.cmd("startinsert")
    end
    return
  end

  require("codex").open()
  vim.defer_fn(function()
    channel = live_channel()
    if channel then
      vim.api.nvim_chan_send(channel, text)
      if focus ~= false then
        vim.cmd("startinsert")
      end
    else
      vim.notify("Codex no pudo iniciar su terminal", vim.log.levels.ERROR)
    end
  end, 500)
end

local function command(cmd)
  send(cmd .. "\n")
end

local function file_ref(first, last)
  local path = vim.fn.expand("%:p")
  if path == "" then
    return nil
  end
  return first and ("@" .. path .. ":" .. first .. "-" .. last) or ("@" .. path)
end

local function send_buffer()
  local ref = file_ref(1, vim.api.nvim_buf_line_count(0))
  if ref then
    send(ref .. "\n")
  end
end

local function send_all_buffers()
  local refs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= "" then
        refs[#refs + 1] = "@" .. path .. ":1-" .. vim.api.nvim_buf_line_count(buf)
      end
    end
  end
  if #refs > 0 then
    send(table.concat(refs, "\n") .. "\n")
  end
end

local function prompt_menu(first, last)
  local choices = {
    "Revisar código",
    "Explicar código",
    "Debuggear error",
    "Refactorizar",
    "Optimizar",
    "Prompt personalizado",
  }
  vim.ui.select(choices, { prompt = " Codex ~ Selecciona acción:" }, function(_, index)
    if not index then
      return
    end
    local prompts = {
      "Revisa este código y sugiere mejoras:",
      "Explica este código paso a paso:",
      "Debuggea este error:",
      "Refactoriza este código:",
      "Optimiza este código:",
    }
    local function submit(prompt)
      if not prompt or prompt == "" then
        return
      end
      local ref = first and file_ref(first, last) or nil
      send(prompt .. (ref and ("\n" .. ref) or "") .. "\n")
    end
    if index == 6 then
      vim.ui.input({ prompt = "Tu prompt: " }, submit)
    else
      submit(prompts[index])
    end
  end)
end

local function map(mode, suffix, rhs, desc)
  for _, prefix in ipairs(prefixes) do
    keymap.set(mode, prefix .. suffix, rhs, { desc = " Codex: " .. desc })
  end
end

local function register_keymaps()
    map("n", "t", function()
      require("codex").toggle()
    end, "toggle")
    map("n", "f", function()
      require("codex").open()
      vim.cmd("startinsert")
    end, "focus")
    map("n", "b", send_buffer, "enviar buffer actual")
    map("n", "B", send_all_buffers, "enviar todos los buffers")
    map("n", "P", prompt_menu, "menú de prompts")
    map("v", "", function()
      prompt_menu(vim.fn.line("'<"), vim.fn.line("'>"))
    end, "enviar selección al menú")

    local commands = {
      n = { "/new", "nueva sesión" },
      l = { "/resume", "reanudar sesión" },
      F = { "/fork", "fork de sesión" },
      d = { "/diff", "mostrar diff" },
      m = { "/model", "seleccionar modelo" },
      k = { "/compact", "compactar contexto" },
      r = { "/review", "revisar cambios" },
      q = { "/quit", "salir" },
      ["?"] = { "/help", "ayuda" },
    }
    for suffix, item in pairs(commands) do
      local cmd = item[1]
      map("n", suffix, function()
        command(cmd)
      end, item[2])
    end
    map("n", "x", function()
      local channel = live_channel()
      if channel then
        vim.api.nvim_chan_send(channel, "\027")
      end
    end, "interrumpir")

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>cx", group = "Codex", icon = { icon = "󱚡" } },
        { "<leader>X", group = "Codex", icon = { icon = "󱚡" } },
      })
    end
end

register_keymaps()
