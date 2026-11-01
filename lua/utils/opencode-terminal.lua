local M = {}

---Find a live OpenCode TUI, preferring this project, then an ancestor
---(e.g. $HOME), then any other live TUI.
---@return integer? buf
function M.find()
  local cwd = vim.fn.getcwd()
  local exact, ancestor, any
  local ancestor_len = -1
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local opencode_cwd = vim.b[buf].opencode_cwd
      if opencode_cwd then
        local job = vim.bo[buf].channel
        if job > 0 and vim.fn.jobwait({ job }, 0)[1] == -1 then
          if opencode_cwd == cwd then
            exact = exact or buf
          elseif cwd:sub(1, #opencode_cwd + 1) == opencode_cwd .. "/" and #opencode_cwd > ancestor_len then
            ancestor, ancestor_len = buf, #opencode_cwd
          end
          any = any or buf
        end
      end
    end
  end
  return exact or ancestor or any
end

---Show the existing TUI or start OpenCode v2 using its shared service.
---@param continue? boolean Resume the last session when opening a new TUI.
---@return integer buf
function M.focus(continue)
  local buf = M.find()
  if buf then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        vim.cmd.startinsert()
        return buf
      end
    end
    for _, term in ipairs(require("snacks.terminal").list()) do
      if term.buf == buf then
        term:show():focus()
        vim.cmd.startinsert()
        return buf
      end
    end
    vim.cmd("botright vsplit")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_width(0, math.max(30, math.floor(vim.o.columns * 0.35)))
    vim.cmd.startinsert()
    return buf
  end

  local cwd = vim.fn.getcwd()
  for _, old in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(old) and vim.b[old].opencode_cwd == cwd then
      pcall(vim.api.nvim_buf_delete, old, { force = true })
    end
  end
  -- Resolve opencode binary robustly (cross-platform, works even if PATH isn't propagated to GUI apps)
  local opencode_bin = vim.fn.exepath("opencode")
  if opencode_bin == "" then
    local sysname = vim.loop.os_uname().sysname
    local home = vim.loop.os_homedir()
    local candidates = {}

    if sysname == "Linux" then
      -- Linux: Fedora/Bazzite, Arch/CachyOS, NixOS, Debian/Ubuntu, Termux, etc.
      candidates = {
        home .. "/.opencode/bin/opencode",           -- Official installer (most distros)
        home .. "/.local/bin/opencode",              -- pipx, cargo, local installs
        "/usr/local/bin/opencode",                   -- Manual / make install
        "/usr/bin/opencode",                         -- Distro package
        -- NixOS: if installed via nix, it's usually in PATH already.
        -- If not, user profile might be at ~/.nix-profile/bin/opencode
        home .. "/.nix-profile/bin/opencode",
        -- Termux
        (os.getenv("PREFIX") or "") .. "/bin/opencode",
      }
    elseif sysname == "Darwin" then
      -- macOS: Intel + Apple Silicon
      candidates = {
        home .. "/.opencode/bin/opencode",           -- Official installer
        home .. "/.local/bin/opencode",              -- pipx, cargo, local installs
        "/usr/local/bin/opencode",                   -- Intel Homebrew / manual
        "/opt/homebrew/bin/opencode",                -- Apple Silicon Homebrew
        "/usr/bin/opencode",                         -- System (rare)
      }
    elseif sysname == "Windows_NT" then
      -- Windows: native, scoop, chocolatey, winget, official installer
      local localappdata = os.getenv("LOCALAPPDATA") or ""
      local appdata = os.getenv("APPDATA") or ""
      local userprofile = os.getenv("USERPROFILE") or home
      candidates = {
        userprofile .. "\\.opencode\\bin\\opencode.exe",         -- Official installer
        localappdata .. "\\opencode\\bin\\opencode.exe",         -- Alternative installer location
        userprofile .. "\\scoop\\apps\\opencode\\current\\opencode.exe", -- Scoop
        userprofile .. "\\.scoop\\apps\\opencode\\current\\opencode.exe", -- Scoop (alt)
        "C:\\ProgramData\\chocolatey\\bin\\opencode.exe",        -- Chocolatey
        localappdata .. "\\Microsoft\\WinGet\\Links\\opencode.exe", -- Winget
        home .. "\\.local\\bin\\opencode.exe",                   -- Cargo/pipx in user profile
      }
    end

    -- Filter out empty strings and check each candidate
    for _, c in ipairs(candidates) do
      if c ~= "" and vim.fn.filereadable(c) == 1 and vim.fn.executable(c) == 1 then
        opencode_bin = c
        break
      end
    end
  end
  local cmd = { opencode_bin ~= "" and opencode_bin or "opencode" }
  if continue then
    cmd[#cmd + 1] = "--continue"
  end
  local term = require("snacks.terminal").open(cmd, {
    cwd = cwd,
    -- Keep exit output visible; M.focus removes dead buffers before restarting.
    auto_close = false,
    win = {
      position = "right",
      width = 0.35,
      enter = true,
      on_buf = function(win)
        vim.b[win.buf].opencode_cwd = cwd
      end,
    },
  })
  return term.buf
end

---Hide a TUI visible in this tab; otherwise show and focus it in one press.
function M.toggle()
  local buf = M.find()
  if buf then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() then
        vim.api.nvim_win_hide(win)
        return
      end
    end
  end
  M.focus()
end

---Close only this project's TUI; the shared OpenCode service remains available.
function M.close()
  local buf = M.find()
  if buf then
    vim.fn.jobstop(vim.bo[buf].channel)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

---Send control keys to an existing TUI, never to a headless server terminal.
---@param keys string
---@return boolean sent
function M.send(keys)
  local buf = M.find()
  if not buf then
    M.focus()
    vim.notify("OpenCode abierto. Repite el atajo cuando aparezca el prompt.", vim.log.levels.INFO)
    return false
  end
  M.focus()
  vim.api.nvim_chan_send(vim.bo[buf].channel, keys)
  return true
end

---Keep the fork's absolute-path contexts as configuration overrides.
---@return table<string, function>
function M.contexts()
  local builtins = require("opencode.context.builtins")
  local contexts = {}
  for placeholder, name in pairs({ ["@this"] = "this", ["@buffer"] = "buffer", ["@buffers"] = "buffers" }) do
    local builder = builtins[name]
    contexts[placeholder] = function(context)
      local absolute = setmetatable({
        format = function(opts)
          opts = vim.tbl_extend("force", {}, opts)
          opts.rel = nil
          return context.format(opts)
        end,
      }, { __index = context })
      return builder(absolute)
    end
  end
  return contexts
end

---Expand editor placeholders before changing focus, then paste without submitting.
---@param text string
---@param range? opencode.context.Range
function M.append(text, range)
  local context = require("opencode.context").new({}, range)
  local rendered = context:render(text).output:plaintext()
  context:clear()
  -- Strip escape characters so file/diagnostic text cannot terminate bracketed paste.
  rendered = rendered:gsub("\27", "")
  if not M.send("\27[200~" .. rendered .. "\27[201~") then
    -- Keep the captured text available without depending on terminal startup timing.
    vim.fn.setreg("o", rendered)
    vim.notify("Contexto conservado en el registro o; pégalo cuando el TUI esté listo.")
  end
end

---Capture an operator range and append it to the TUI without starting a model request.
---@return string
function M.operator()
  _G.opencode_append_operator = function(kind)
    local first = vim.api.nvim_buf_get_mark(0, "[")
    local last = vim.api.nvim_buf_get_mark(0, "]")
    if first[1] > last[1] or (first[1] == last[1] and first[2] > last[2]) then
      first, last = last, first
    end
    M.append("@this ", { from = first, to = last, kind = kind })
  end
  vim.o.operatorfunc = "v:lua.opencode_append_operator"
  return "g@"
end

return M
