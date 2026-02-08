-- Soporte para pegar imágenes en Neovim
return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      -- Carpeta donde guardar las imágenes (relativa al archivo actual)
      dir_path = "assets/images",
      -- Formato del nombre: año-mes-día-hora-minuto-segundo
      file_name = "%Y-%m-%d-%H-%M-%S",
      -- No incrustar como base64 (usar ruta de archivo)
      embed_image_as_base64 = false,
      -- No pedir nombre de archivo (usar formato automático)
      prompt_for_file_name = false,
      -- Usar rutas absolutas
      use_absolute_path = false,
      -- Ruta relativa al archivo actual
      relative_to_current_file = true,
      -- Arrastrar y soltar
      drag_and_drop = {
        insert_mode = true,
      },
    },
    -- Configuración específica para Markdown
    filetypes = {
      markdown = {
        url_encode_path = true,
        template = "![$CURSOR]($FILE_PATH)",
      },
      html = {
        template = '<img src="$FILE_PATH" alt="$CURSOR">',
      },
    },
  },
  keys = {
    -- Pegar imagen desde clipboard
    { "<leader>ip", "<cmd>PasteImage<cr>", desc = "󰋩 Pegar imagen [Avante]", mode = { "n", "i" } },
    { "<leader>aP", "<cmd>PasteImage<cr>", desc = "󰋩 Pegar imagen [Avante]", mode = { "n", "i" } },
    { "<leader>aP1", "<cmd>PasteImage<cr>", desc = "󰋩 Pegar imagen [Avante]", mode = { "n", "i" } },
    -- Pegar con preview (completo)
    {
      "<leader>iP",
      function()
        require("img-clip").paste_image()
      end,
      desc = "  Pegar con preview  [Avante]",
      mode = { "n", "i" },
    },
  },
}
