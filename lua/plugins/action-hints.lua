-- ⚡ Action Hints (roobert/action-hints.nvim)
-- Muestra bajo el cursor qué acciones LSP hay para la palabra actual:
--   ⊛   → definición disponible        ↱N  → N referencias (gr)
-- El plugin NO registra keymaps (solo autocmds CursorMoved/I con request LSP
-- debounced 100ms) → no choca con agy (<leader>ag/G/gg) ni con git.
--
-- Atajos dedicados (evitan pisar gd/gr ya ocupados por copilot-chat/LazyVim):
--   gT  → go-to-definition   gR  → references
-- ⚠️ nvim usa gT por defecto para "previous tab"; queda reasignado (los tabs
-- siguen disponibles con [T / ]T como en LazyVim).
return {
  {
    "roobert/action-hints.nvim",
    config = function()
      require("action-hints").setup({
        template = {
          definition = { text = " ⊛", color = "#add8e6" },
          references = { text = " ↱%s", color = "#ff6666" },
        },
        use_virtual_text = true,
      })

      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>gt", function() -- similar a <leader>gd (go to definition)
        telescope.lsp_definitions()
      end, { desc = "⚡ Go To Definición (LSP)", silent = true, nowait = true })
      vim.keymap.set("n", "<leader>gr", function() -- similar a <leader>sw (search word [RIPGREP])
        telescope.lsp_references()
      end, { desc = "⚡Go To Referencias (LSP)", silent = true, nowait = true })
      -- Reutiliza <leader>gO para abrir rutas literales del sistema o hacer fallback a gx
      vim.keymap.set("n", "<leader>gx", function()
        -- 1. Obtiene el string exacto bajo el cursor (sirve para rutas absolutas y relativas)
        local path = vim.fn.expand("<cfile>")

        -- 2. Limpia posibles caracteres extra comunes en Markdown (como comillas o acentos graves)
        path = path:gsub('^["`]', ""):gsub('["`]$', "")

        -- 🆕 Validación robusta: solo continuar si parece ruta real o URL
        -- Evita notificaciones falsas por basura del keymap (silent, nowait, desc, etc.)
        local is_path = path:find("^/") or path:find("^~") or path:find("^%./") or path:find("^%.%./")
        local is_url = path:match("^%w+://") or path:match("^[%w%-]+%.(com|org|net|io|dev|github%.io)")
        if not (is_path or is_url) then return end

        -- 3. Verifica si es una ruta válida en el disco (/home/diego/...)
        if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
          -- Abre la ruta con el comando de edición nativo de nvim (activa Neo-tree/Oil/netrw según tu LazyVim)
          vim.cmd("edit " .. vim.fn.fnameescape(path))
          vim.notify("✅ Abriendo ruta local: " .. path, vim.log.levels.INFO)
        else
          -- 4. Intenta abrir como URL en el navegador predeterminado
          -- Usamos vim.ui.open si está disponible (Neovim 0.10+), si no, fallback sistema
          local ok = pcall(function()
            vim.ui.open(path)
          end)
          if ok then
            -- Solo muestra notificación si la URL se abrió exitosamente
            vim.notify("🔗 Abriendo URL en navegador: " .. path, vim.log.levels.INFO)
          else
            -- Fallback: abrir con comando del sistema (Linux: xdg-open, macOS: open)
            local system_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
            vim.fn.system({ system_cmd, path })
            -- Mostrar notificación solo en fallback del sistema
            vim.notify("🔗 Abriendo URL con fallback del sistema: " .. path, vim.log.levels.INFO)
          end
        end
      end, {
        nowait = true,
        silent = true,
        desc = "📁 Abrir ruta literal o enlace bajo el cursor",
      })
      -- 🧠 Inspect e InspectTree NO son del plugin: son NATIVOS de LazyVim/LSP
      -- (builtins de nvim). Aparecen siempre en el menú de acciones al hacer
      -- click/saltar sobre una definición — estos atajos solo los hacen cómodos.
      --   <leader>gx → :Inspect      (nodo treesitter + grupos de highlight bajo el cursor)
      --   gX         → :InspectTree  (árbol treesitter completo del buffer)
      vim.keymap.set("n", "<leader>gX", "<cmd>Inspect<cr>", {
        desc = "⚡ Inspect: TS node + hl (nativo)",
        silent = true,
      })
      vim.keymap.set("n", "<leader>g?", "<cmd>InspectTree<cr>", {
        desc = "⚡ InspectTree: árbol de sintaxis TS (nativo)",
        silent = false,
      })
    end,
  },
}

