local M = {}

local TARGET_REL = "lua/cord/internal/activity/workspace.lua"

M.default_dir = function()
  return vim.fn.stdpath("data") .. "/lazy/cord.nvim"
end

M.unpatch_cord = function(dir)
  dir = dir or M.default_dir()
  if vim.fn.isdirectory(dir .. "/.git") == 0 then
    return
  end
  vim.fn.system({ "git", "-C", dir, "update-index", "--no-assume-unchanged", TARGET_REL })
  vim.fn.system({ "git", "-C", dir, "checkout", "--", TARGET_REL })
end

M.patch_cord = function(dir)
  dir = dir or M.default_dir()
  if vim.fn.isdirectory(dir) == 0 then
    return
  end
  local function read(p)
    return vim.fn.readfile(p)
  end
  local function write(p, lines)
    vim.fn.writefile(lines, p)
  end
  local function has_mark(lines)
    for _, l in ipairs(lines) do
      if l:find("dizzi patch") then
        return true
      end
    end
    return false
  end

  -- 1) Strip any previously applied patch so lazy updates never fail
  -- on local changes, then reapply (idempotent).
  M.unpatch_cord(dir)

  -- 2) lua/cord/internal/activity/workspace.lua: find_git_repository climbs
  -- parent dirs looking for .git/config (upstream only checks workspace_path)
  local f = dir .. "/" .. TARGET_REL
  if vim.fn.filereadable(f) == 0 then
    return
  end
  local lines = read(f)
  if not has_mark(lines) then
    local out = {}
    for _, l in ipairs(lines) do
      out[#out + 1] = l
      if l:find("local content = fs%.readfile%(config_path%):await%(%)") then
        out[#out + 1] = "  if not content then"
        out[#out + 1] = "    -- [dizzi patch] Climb parent dirs looking for .git/config so the"
        out[#out + 1] = "    -- repo button resolves when nvim starts in a subdirectory."
        out[#out + 1] = "    -- Auto-reapplied by the plugin build."
        out[#out + 1] = "    local curr_dir = workspace_path"
        out[#out + 1] = "    while not content do"
        out[#out + 1] = "      local parent = vim.fn.fnamemodify(curr_dir, ':h')"
        out[#out + 1] = "      if parent == curr_dir then break end"
        out[#out + 1] = "      curr_dir = parent"
        out[#out + 1] = "      content = fs.readfile(curr_dir .. '/.git/config'):await()"
        out[#out + 1] = "    end"
        out[#out + 1] = "  end"
      end
    end
    write(f, out)
  end

  -- 3) Hide from `git ls-files -d -m` so Lazy's git.status check never fails
  if vim.fn.isdirectory(dir .. "/.git") == 1 then
    vim.fn.system({ "git", "-C", dir, "update-index", "--assume-unchanged", TARGET_REL })
  end
end

return M
