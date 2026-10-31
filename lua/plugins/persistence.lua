return {
  {
    "folke/persistence.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("persistence_arglist", { clear = true }),
        pattern = "PersistenceSavePre",
        callback = function()
          local seen = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            vim.api.nvim_win_call(win, function()
              local id = vim.fn.arglistid()
              if seen[id] then
                return
              end
              seen[id] = true
              -- :bdelete no quita el archivo de :args; :mksession lo vuelve a crear.
              local args = vim.fn.argv()
              for i = #args, 1, -1 do
                if vim.fn.buflisted(vim.fn.fnamemodify(args[i], ":p")) == 0 then
                  vim.cmd(i .. "argdelete")
                end
              end
            end)
          end
        end,
      })
    end,
  },
}
