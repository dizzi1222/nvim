-- 🐐🗣️🔥️✍️  NO REQUIERE API. | ✍️ Activar con:TabnineLoginWithAuthToken |  Autocompletado 󰄭 .
-- NO FUNCIONA LA API?????????
---- Get platform dependant build script [Unix, Windows]
local function tabnine_build_path()
  -- Replace vim.uv with vim.loop if using NVIM 0.9.0 or below
  if vim.uv.os_uname().sysname == "Windows_NT" then
    return "pwsh.exe -file .\\dl_binaries.ps1"
  else
    return "./dl_binaries.sh"
  end
end

return {
  "codota/tabnine-nvim",
  build = tabnine_build_path(), -- ✅ Llamar la función con ()
  config = function()
    require("tabnine").setup({
      disable_auto_comment = true,
      accept_keymap = "<Tab>",
      dismiss_keymap = "<C-]>",
      accept_word = "<C-Enter>", -- antes estaba como C-j
      debounce_ms = 800,
      suggestion_color = { gui = "#caa99b", cterm = 244 }, -- #808080
      exclude_filetypes = { "TelescopePrompt", "NvimTree" },
      log_file_path = nil, -- absolute path to Tabnine log file
      ignore_certificate_errors = false,
      -- workspace_folders = {
      --   paths = { "/your/project" },
      --   get_paths = function()
      --     return { "/your/project" }
      --   end,
      -- },
    })

    -- Mostrar el status de Tabnine para Ver si arranca
    vim.notify("Tabnine Status: " .. require("tabnine.status").status(), vim.log.levels.INFO)
  end,
}
