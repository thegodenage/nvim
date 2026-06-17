return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<S-h>",      "<cmd>BufferLineCyclePrev<cr>",    desc = "Prev buffer" },
    { "<S-l>",      "<cmd>BufferLineCycleNext<cr>",    desc = "Next buffer" },
    { "<leader>bd", "<cmd>bdelete<cr>",                desc = "Delete buffer" },
    { "<leader>bp", "<cmd>BufferLineTogglePin<cr>",    desc = "Pin buffer" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>",  desc = "Close other buffers" },
    { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned buffers" },
    { "[b",         "<cmd>BufferLineCyclePrev<cr>",    desc = "Prev buffer" },
    { "]b",         "<cmd>BufferLineCycleNext<cr>",    desc = "Next buffer" },
  },
  opts = {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      show_buffer_close_icons = false,
      show_close_icon = false,
      separator_style = "thin",
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          highlight = "Directory",
          separator = true,
        },
      },
    },
  },
}
