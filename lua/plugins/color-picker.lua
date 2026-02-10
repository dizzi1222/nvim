return {
  "eero-lehtinen/oklch-color-picker.nvim",
  -- ✅ Auto-deshabilitar en Android/Termux
  enabled = vim.fn.isdirectory("/data/data/com.termux") == 0,
  cond = function()
    -- Solo cargar si:
    -- 1. NO estamos en Termux
    -- 2. El picker existe (WSL o Linux)
    local is_termux = vim.fn.isdirectory("/data/data/com.termux") == 1
    if is_termux then
      return false
    end

    -- En WSL, verificar que el .exe existe
    if vim.fn.has("wsl") == 1 then
      local picker_path = "/mnt/c/Users/Diego/AppData/Local/nvim-data/oklch-color-picker/oklch-color-picker.exe"
      return vim.fn.filereadable(picker_path) == 1
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
    auto_download = true, -- Descarga automática para los parsers
    wsl_use_windows_app = true, -- ✅ Usar versión Windows desde WSL
    -- Ruta explícita al .exe de Windows
    picker_path = "/mnt/c/Users/Diego/AppData/Local/nvim-data/oklch-color-picker/oklch-color-picker.exe",
  },
  config = function()
    -- config = function(_, opts)
    require("oklch-color-picker").setup({
      -- ✅ CRÍTICO: Deshabilitar en buffers de Avante
      disable_in_buffers = {
        "Avante",
        "AvanteInput",
        "AvanteAsk",
      },
    })
    -- ✅ DESHABILITAR en buffers de Avante
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "Avante", "AvanteInput", "AvanteAsk", "AvanteSelectedFiles" },
      callback = function()
        vim.b.oklch_color_picker_disable = true
      end,
    })
    -- Silenciar notificaciones durante la carga
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      if type(msg) == "string" and msg:match("oklch") then
        return
      end
      original_notify(msg, level, opts)
    end

    local ok, picker = pcall(require, "oklch-color-picker")
    vim.notify = original_notify

    if ok then
      picker.setup(opts)
    end
  end,
}
