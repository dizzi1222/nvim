-- Compatibilidad local: todos los puntos de entrada comparten el mismo TUI v2.
local ok, opencode = pcall(require, "opencode")
if not ok then
  return
end

local terminal = require("utils.opencode-terminal")
opencode.toggle = terminal.toggle
opencode.start = terminal.focus
opencode.stop = terminal.close

---Report whether this project's TUI is already running.
opencode.ensure_open = function()
  return terminal.find() ~= nil
end
