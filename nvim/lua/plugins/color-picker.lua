return {
  "eero-lehtinen/oklch-color-picker.nvim",
  event = "VeryLazy",
  version = "*",
  keys = {
    {
      "<leader>v",
      function()
        require("oklch-color-picker").pick_under_cursor()
      end,
      desc = "Color pick under cursor",
    },
  },
  opts = {
    highlight = {
      enabled = true,
      style = "foreground+virtual_left",
      virtual_text = "■ ",
      emphasis = { threshold = { 0.1, 0.17 }, amount = { 45, -80 } },
    },
    patterns = {
      hex = { priority = -1, "()#%x%x%x+%f[%W]()" },
      numbers_in_brackets = false,
    },
    auto_download = true, -- Descarga automática para los parsers
    wsl_use_windows_app = true, -- ✅ Usar versión Windows desde WSL
    -- Ruta explícita al .exe de Windows
    picker_path = "/mnt/c/Users/Diego/AppData/Local/nvim-data/oklch-color-picker/oklch-color-picker.exe",
  },
  config = function(_, opts)
    -- Silenciar notificaciones durante la carga
    local notify_backup = vim.notify
    vim.notify = function(msg, level, notify_opts)
      if type(msg) == "string" and msg:match("oklch") then
        return
      end
      notify_backup(msg, level, notify_opts)
    end

    local ok, picker = pcall(require, "oklch-color-picker")
    vim.notify = notify_backup

    if ok then
      picker.setup(opts)
    end
  end,
}
