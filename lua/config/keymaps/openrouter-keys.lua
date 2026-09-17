local keymap = vim.keymap

local function list_openrouter_models()
  local api_key = vim.env.OPEN_ROUTER_API_KEY
  if not api_key or api_key == "" then
    vim.notify("❌ OPEN_ROUTER_API_KEY no definida", vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart({
    "curl",
    "-s",
    "-H",
    "Authorization: Bearer " .. api_key,
    "https://openrouter.ai/api/v1/models",
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then
        return
      end
      local ok, result = pcall(vim.json.decode, table.concat(data, ""))
      if not ok or not result.data then
        vim.notify("❌ Error al obtener modelos", vim.log.levels.ERROR)
        return
      end

      local lines = { " 󱋭 OpenRouter modelos gratis:", "" }
      for _, m in ipairs(result.data) do
        local p = m.pricing or {}
        local free = tonumber(p.prompt) == 0 and tonumber(p.completion) == 0
        local free_tag = m.id:match(":free$")
        if free and free_tag then
          table.insert(lines, " 󰄱 " .. m.id)
        elseif free then
          table.insert(lines, " 󰄱 " .. m.id .. " (gratis sin :free)")
        end
      end

      table.insert(lines, "")
      table.insert(lines, "Presiona q para cerrar")

      vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
        relative = "editor",
        width = 72,
        height = math.min(#lines + 2, 30),
        row = 2,
        col = math.floor((vim.o.columns - 72) / 2),
        style = "minimal",
        border = "rounded",
        title = " OpenRouter Models ",
      })
      vim.api.nvim_buf_set_name(0, "openrouter://models")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.bo.filetype = "markdown"
      vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = true, desc = "Cerrar" })
      vim.cmd("stopinsert")
    end,
    on_stderr = function(_, err)
      vim.notify("❌ Error curl: " .. table.concat(err or {}, ""), vim.log.levels.ERROR)
    end,
  })
end

keymap.set({ "n" }, "<leader>aL", list_openrouter_models, { desc = " 󱋭 Listar modelos OpenRouter" })

-- which-key: registrar después de VeryLazy
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>aL", icon = { icon = "󱋭" } },
      })
    end
  end,
})
