local M = {}

local terminals = {}
local terminal_width = 0.4

---Find the current Git workspace, or fall back to Neovim's working directory.
---@return string
function M.project_root()
  local cwd = vim.fn.getcwd()
  local root = vim.fn.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })

  if vim.v.shell_error == 0 then
    return vim.trim(root)
  end

  return cwd
end

local function terminal_is_live(entry)
  return entry ~= nil
    and vim.api.nvim_buf_is_valid(entry.buf)
    and type(entry.job) == "number"
    and entry.job > 0
    and vim.fn.jobwait({ entry.job }, 0)[1] == -1
end

local function hermes_binary()
  local binary = vim.fn.exepath("hermes")
  if binary ~= "" then
    return binary
  end

  local local_binary = vim.fn.expand("~/.local/bin/hermes")
  if vim.fn.executable(local_binary) == 1 then
    return local_binary
  end

  vim.notify("No encontré el ejecutable hermes en PATH ni en ~/.local/bin/hermes", vim.log.levels.ERROR)
  return nil
end

local function new_terminal_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  return buf
end

local function current_tab_window_for(buf)
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_tabpage(win) == current_tab then
      return win
    end
  end
end

---Find any visible window displaying a buffer, across all tabs.
---@param buf integer
---@return integer?
local function visible_window_for(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      return win
    end
  end
end

---Check if a Hermes profile has VPS/hostinger configuration.
---@param profile_name string
---@return boolean
function M.profile_has_vps_config(profile_name)
  local config_path = vim.fn.expand("~/.hermes/profiles/" .. profile_name .. "/config.yaml")
  if vim.fn.filereadable(config_path) == 0 then
    return false
  end
  local content = vim.fn.readfile(config_path)
  for _, line in ipairs(content) do
    if line:match("hostinger") or line:match("vps") then
      return true
    end
  end
  return false
end

local function profile_has_vps_config(profile_name)
  return M.profile_has_vps_config(profile_name)
end

---Toggle a profile's TUI window, reopening its live buffer instead of spawning a duplicate.
---@param profile_name string
---@return table?
function M.smart_toggle_profile(profile_name)
  local binary = hermes_binary()
  if not binary then
    return nil
  end

  local root = M.project_root()
  local previous = terminals[root]
  local previous_buf = previous and previous.buf or nil
  local win = previous_buf and visible_window_for(previous_buf) or nil
  local previous_profile = previous and previous.profile or "default"
  local previous_source_buf
  local has_live_session = terminal_is_live(previous)

  -- A visible Hermes terminal always toggles off, regardless of selected profile.
  if has_live_session and win then
    local win_tab = vim.api.nvim_win_get_tabpage(win)
    if #vim.api.nvim_tabpage_list_wins(win_tab) > 1 then
      vim.api.nvim_win_hide(win)
    elseif previous.previous_buf and vim.api.nvim_buf_is_valid(previous.previous_buf) then
      vim.api.nvim_win_set_buf(win, previous.previous_buf)
    else
      vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    end
    return previous
  end

  -- Reopen the same profile's existing terminal instead of spawning another.
  if has_live_session and previous_profile == profile_name then
    local source_win = vim.api.nvim_get_current_win()
    previous_source_buf = previous.previous_buf
    if not previous_source_buf or not vim.api.nvim_buf_is_valid(previous_source_buf) then
      previous_source_buf = vim.api.nvim_win_get_buf(source_win)
      previous.previous_buf = previous_source_buf
    end
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
    vim.api.nvim_win_set_buf(win, previous_buf)
    vim.cmd.startinsert()
    return previous
  end

  if win then
    previous_source_buf = previous.previous_buf
    if not previous_source_buf or not vim.api.nvim_buf_is_valid(previous_source_buf) then
      previous_source_buf = vim.api.nvim_win_get_buf(win)
    end
  else
    local source_win = vim.api.nvim_get_current_win()
    previous_source_buf = vim.api.nvim_win_get_buf(source_win)
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
  end

  local buf = new_terminal_buffer()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)

  local args = { binary, "--tui", "-p", profile_name }
  if has_live_session and previous_profile == profile_name then
    table.insert(args, 3, "--continue")
  end
  local job = vim.fn.termopen(args, { cwd = root })
  if job <= 0 then
    vim.api.nvim_win_set_buf(win, previous_source_buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("No se pudo iniciar Hermes TUI (perfil: " .. profile_name .. ")", vim.log.levels.ERROR)
    return nil
  end

  local entry = {
    buf = buf,
    job = job,
    previous_buf = previous_source_buf,
    profile = profile_name,
  }
  terminals[root] = entry

  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) and #vim.fn.win_findbuf(previous_buf) == 0 then
    pcall(vim.api.nvim_buf_delete, previous_buf, { force = true })
  end

  vim.cmd.startinsert()
  return entry
end

---Toggle the default/root Hermes TUI window and reuse its live buffer when reopened.
---The keymap shows a VPS selector only when VPS config exists.
---@return table?
function M.smart_toggle()
  local binary = hermes_binary()
  if not binary then
    return nil
  end

  local root = M.project_root()
  local previous = terminals[root]
  local previous_buf = previous and previous.buf or nil
  local previous_profile = previous and previous.profile or "default"
  local win = previous_buf and visible_window_for(previous_buf) or nil

  local has_live_session = terminal_is_live(previous)

  -- Any visible Hermes window means toggle off, whether focused or in another tab.
  if has_live_session and win then
    local win_tab = vim.api.nvim_win_get_tabpage(win)
    if #vim.api.nvim_tabpage_list_wins(win_tab) > 1 then
      vim.api.nvim_win_hide(win)
    elseif previous.previous_buf and vim.api.nvim_buf_is_valid(previous.previous_buf) then
      vim.api.nvim_win_set_buf(win, previous.previous_buf)
    else
      vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    end
    return previous
  end

  -- If there's a live session but no window, reuse the buffer in a new split
  local previous_source_buf
  if has_live_session and previous_profile == "default" and previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
    local source_win = vim.api.nvim_get_current_win()
    previous_source_buf = vim.api.nvim_win_get_buf(source_win)
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
    vim.api.nvim_win_set_buf(win, previous_buf)
    vim.cmd.startinsert()
    return previous
  end

  -- No live session: create new terminal
  local source_win = vim.api.nvim_get_current_win()
  previous_source_buf = vim.api.nvim_win_get_buf(source_win)
  vim.cmd("botright vsplit")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))

  local buf = new_terminal_buffer()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)

  local args = { binary, "--tui" }
  local job = vim.fn.termopen(args, { cwd = root })
  if job <= 0 then
    vim.api.nvim_win_set_buf(win, previous_source_buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("No se pudo iniciar Hermes TUI", vim.log.levels.ERROR)
    return nil
  end

  local entry = {
    buf = buf,
    job = job,
    previous_buf = previous_source_buf,
    profile = "default",
  }
  terminals[root] = entry

  vim.cmd.startinsert()
  return entry
end

---Start Hermes TUI with a specific profile (always uses --continue).
---@param profile_name string
---@return table?
function M.focus_profile(profile_name)
  local binary = hermes_binary()
  if not binary then
    return nil
  end

  local root = M.project_root()
  local previous = terminals[root]
  local previous_buf = previous and previous.buf or nil
  local win = previous_buf and current_tab_window_for(previous_buf) or nil
  local previous_source_buf

  if win then
    previous_source_buf = previous.previous_buf
    if not previous_source_buf or not vim.api.nvim_buf_is_valid(previous_source_buf) then
      previous_source_buf = vim.api.nvim_win_get_buf(win)
    end
  else
    local source_win = vim.api.nvim_get_current_win()
    previous_source_buf = vim.api.nvim_win_get_buf(source_win)
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
  end

  local buf = new_terminal_buffer()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)

  local job = vim.fn.termopen({ binary, "--tui", "--continue", "-p", profile_name }, { cwd = root })
  if job <= 0 then
    vim.api.nvim_win_set_buf(win, previous_source_buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("No se pudo iniciar Hermes TUI (perfil: " .. profile_name .. ")", vim.log.levels.ERROR)
    return nil
  end

  local entry = {
    buf = buf,
    job = job,
    previous_buf = previous_source_buf,
  }
  terminals[root] = entry

  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) and #vim.fn.win_findbuf(previous_buf) == 0 then
    pcall(vim.api.nvim_buf_delete, previous_buf, { force = true })
  end

  vim.cmd.startinsert()
  return entry
end

local function start_terminal(root)
  local binary = hermes_binary()
  if not binary then
    return nil
  end

  local previous = terminals[root]
  local previous_buf = previous and previous.buf or nil
  local win = previous_buf and current_tab_window_for(previous_buf) or nil
  local previous_source_buf

  if win then
    previous_source_buf = previous.previous_buf
    if not previous_source_buf or not vim.api.nvim_buf_is_valid(previous_source_buf) then
      previous_source_buf = vim.api.nvim_win_get_buf(win)
    end
  else
    local source_win = vim.api.nvim_get_current_win()
    previous_source_buf = vim.api.nvim_win_get_buf(source_win)
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
  end

  local buf = new_terminal_buffer()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)

  local job = vim.fn.termopen({ binary, "--tui", "--continue" }, { cwd = root })
  if job <= 0 then
    vim.api.nvim_win_set_buf(win, previous_source_buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("No se pudo iniciar Hermes TUI", vim.log.levels.ERROR)
    return nil
  end

  local entry = {
    buf = buf,
    job = job,
    previous_buf = previous_source_buf,
  }
  terminals[root] = entry

  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) and #vim.fn.win_findbuf(previous_buf) == 0 then
    pcall(vim.api.nvim_buf_delete, previous_buf, { force = true })
  end

  vim.cmd.startinsert()
  return entry
end

---Open or focus Hermes for the current workspace, starting it when needed.
---@return table?
function M.focus()
  local root = M.project_root()
  local entry = terminals[root]

  if not terminal_is_live(entry) then
    return start_terminal(root)
  end

  for _, win in ipairs(vim.fn.win_findbuf(entry.buf)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
      return entry
    end
  end

  local source_win = vim.api.nvim_get_current_win()
  if not entry.previous_buf or not vim.api.nvim_buf_is_valid(entry.previous_buf) then
    entry.previous_buf = vim.api.nvim_win_get_buf(source_win)
  end

  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.max(30, math.floor(vim.o.columns * terminal_width)))
  vim.api.nvim_win_set_buf(win, entry.buf)
  vim.cmd.startinsert()
  return entry
end

---Focus Hermes and immediately send /resume to show session picker.
---@return table?
function M.focus_and_resume()
  local entry = M.focus()
  if not entry then
    return nil
  end
  -- Wait for TUI to be ready, then send /resume + Enter
  -- Retry a few times in case TUI takes longer to start
  local attempts = 0
  local max_attempts = 10
  local function try_send()
    attempts = attempts + 1
    if vim.fn.jobwait({ entry.job }, 0)[1] == -1 then
      -- Send Ctrl+X (raw byte 0x18) to open session picker directly
      vim.api.nvim_chan_send(entry.job, "\x18")
    elseif attempts < max_attempts then
      vim.defer_fn(try_send, 200)
    end
  end
  vim.defer_fn(try_send, 500)
  return entry
end


---Hide Hermes in the current tab, or show and focus it when hidden.
function M.toggle()
  local root = M.project_root()
  local entry = terminals[root]
  if terminal_is_live(entry) then
    local win = current_tab_window_for(entry.buf)
    if win then
      if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage()) > 1 then
        vim.api.nvim_win_hide(win)
      elseif entry.previous_buf and vim.api.nvim_buf_is_valid(entry.previous_buf) then
        vim.api.nvim_win_set_buf(win, entry.previous_buf)
      else
        vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
      end
      return
    end
  end

  M.focus()
end

---Paste context into Hermes without submitting the prompt.
---@param text string
---@return boolean
function M.send_context(text)
  local entry = M.focus()
  if not entry then
    return false
  end

  local safe_text = text:gsub("\27", "")
  vim.api.nvim_chan_send(entry.job, "\27[200~" .. safe_text .. "\27[201~")
  return true
end

---Execute a Hermes slash command in the current workspace's TUI.
---@param command string
---@param submit_delay_ms? integer Delay between typing the command and pressing Enter.
---@return boolean
function M.send_command(command, submit_delay_ms)
  local entry = M.focus()
  if not entry then
    return false
  end

  local safe_command = command:gsub("\27", ""):gsub("[\r\n]+", " ")
  if submit_delay_ms and submit_delay_ms > 0 then
    vim.api.nvim_chan_send(entry.job, safe_command)
    vim.defer_fn(function()
      if vim.fn.jobwait({ entry.job }, 0)[1] == -1 then
        vim.api.nvim_chan_send(entry.job, "\r")
      end
    end, submit_delay_ms)
  else
    vim.api.nvim_chan_send(entry.job, safe_command .. "\r")
  end
  return true
end

return M