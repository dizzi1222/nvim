-- 💸💳💰REQUIERE API. USA:claude auth o Logeate con Claude-code: /login auth
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--- Devuelve el bufnr del terminal de Claude activo (o nil si no hay sesión).
---@return integer|nil
local function claude_bufnr()
  local ok, term = pcall(require, "claudecode.terminal")
  local bufnr = ok and term.get_active_terminal_bufnr() or nil
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
  return nil
end

--- Escribe `text` en el terminal de Claude activo, lo muestra y enfoca.
--- `\r` = Enter (envía); `\n` en el TUI de Claude solo inserta salto de línea.
---@param text string Texto/slash command a escribir
---@param submit? boolean Enviar con Enter (default true). false = dejarlo escrito
---@return boolean sent true si había sesión y se envió
local function send_to_claude(text, submit)
  local bufnr = claude_bufnr()
  local chan = bufnr and vim.bo[bufnr].channel
  if not (chan and chan > 0) then
    return false
  end
  require("claudecode.terminal").open() -- reutiliza la sesión: la muestra y enfoca
  vim.api.nvim_chan_send(chan, text .. (submit == false and "" or "\r"))
  vim.cmd("startinsert")
  return true
end

--- `:ClaudeCode <args>` solo usa los args al CREAR el terminal; con una sesión
--- abierta solo alterna la ventana. Si hay sesión → `fallback()`; si no → arranca con args.
---@param args string Flags del CLI (ej. "--resume")
---@param fallback fun() Acción a ejecutar dentro de la sesión existente
local function start_or(args, fallback)
  if claude_bufnr() then
    fallback()
  else
    vim.cmd("ClaudeCode " .. args)
  end
end

--- <leader>al: sin sesión → `claude --resume`; con sesión → `/resume` dentro de ella.
local function resume_claude()
  start_or("--resume", function()
    send_to_claude("/resume")
  end)
end

--- <leader>aC: sin sesión → `claude --continue`; con sesión ya estás continuando → mostrarla.
local function continue_claude()
  start_or("--continue", function()
    require("claudecode.terminal").open()
  end)
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      split_side = "left",
      split_width_percentage = 0.30,
      provider = "snacks",
    },
  },
  keys = {
    { "<leader>a", nil, desc = " AI / IA Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = " Toggle / Alternar Claude" },
    -- aO/aA (no af/aa): esas las usa Avante (focus/ask). aO en visual = Ollama, no choca.
    { "<leader>aO", "<cmd>ClaudeCodeFocus<cr>", desc = " Focus / Enfocar Claude" },
    { "<leader>al", resume_claude, desc = " Resume / Reanudar Claude History Session" },
    { "<leader>aC", continue_claude, desc = " Continue / Continuar Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = " Select model / Seleccionar modelo" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = " Add buffer / Agregar buffer actual" }, -- antes con ab
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = " Send / Enviar a Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = " Add file / Agregar archivo",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
    },
    -- Diff management
    { "<leader>aA", "<cmd>ClaudeCodeDiffAccept<cr>", desc = " Accept / Aceptar cambios" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = " Deny / Rechazar cambios" },
    -- Slash commands automáticos al terminal de Claude
    {
      "<leader>aW",
      function()
        send_to_claude("/rewind")
      end,
      desc = " /rewind - Deshacer último mensaje",
    },
    {
      "<leader>aN",
      function()
        send_to_claude("/rename ", false) -- sin Enter: escribes el nombre tú
      end,
      desc = " /rename - Renombrar conversación",
    },
    {
      "<leader>aF",
      function()
        send_to_claude("/fork")
      end,
      desc = " /fork - Clonar / Bifurcar conversación",
    },
  },
}
