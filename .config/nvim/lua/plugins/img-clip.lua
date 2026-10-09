
return {
  "HakonHarnes/img-clip.nvim",

  event = "VeryLazy",

  opts = {
    default = {
      -- Save images as files instead of Base64
      embed_image_as_base64 = false,

      -- Automatically generate filenames
      prompt_for_file_name = false,

      -- Save images into an images/ directory
      dir_path = "images",

      -- Use relative paths for Typst portability
      use_absolute_path = false,
      relative_to_current_file = true,

      -- Enable drag and drop
      drag_and_drop = {
        enabled = true,
        insert_mode = true,
      },
    },

    filetypes = {
      typst = {
        template = '#image("$FILE_PATH", width: 40%)',
      },
    },
  },

  keys = {
    {
      "<leader>p",
      "<cmd>PasteImage<CR>",
      desc = "Paste image from clipboard",
    },
  },
}

