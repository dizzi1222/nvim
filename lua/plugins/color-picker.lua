return {
  "eero-lehtinen/oklch-color-picker.nvim",
  enabled = vim.fn.isdirectory("/data/data/com.termux") == 0,
  cond = function()
    local is_termux = vim.fn.isdirectory("/data/data/com.termux") == 1
    if is_termux then
      return false
    end
    -- WSL: auto_download se encarga de descargar el binario
    if vim.fn.has("wsl") == 1 then
      return true
    end
    return true
  end,
  event = "VeryLazy",
  version = "*",
  keys = {
    {
      "<leader>v",
      function()
        require("oklch-color-picker").pick_under_cursor()
      end,
      desc = "󰸱 󰇀 Color pick under cursor",
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
    auto_download = true,
    -- WSL: cambiar a true si la versión Windows llega a funcionar
    -- picker_path = "/mnt/c/Users/Diego/AppData/Local/nvim-data/oklch-color-picker/oklch-color-picker.exe",
    wsl_use_windows_app = false,
    disable_in_buffers = {
      "Avante",
      "AvanteInput",
      "AvanteAsk",
    },
  },
  config = function(_, opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "Avante", "AvanteInput", "AvanteAsk", "AvanteSelectedFiles" },
      callback = function()
        vim.b.oklch_color_picker_disable = true
      end,
    })
    local original_notify = vim.notify
    vim.notify = function(msg, level, notify_opts)
      -- Silenciar warnings de oklch y MESA/libEGL (WSLg)
      if type(msg) == "string" and (msg:match("oklch") or msg:match("libEGL") or msg:match("MESA")) then
        return
      end
      original_notify(msg, level, notify_opts)
    end
    local ok, picker = pcall(require, "oklch-color-picker")
    vim.notify = original_notify
    if ok then
      picker.setup(opts)
    end
  end,
}
