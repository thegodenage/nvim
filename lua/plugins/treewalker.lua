return {
  "aaronik/treewalker.nvim",
  event = "VeryLazy",
  opts = {
    highlight = true,
  },
  keys = {
    { "<C-j>", "<cmd>Treewalker Down<cr>",  desc = "Treewalker down" },
    { "<C-k>", "<cmd>Treewalker Up<cr>",    desc = "Treewalker up" },
    { "<C-h>", "<cmd>Treewalker Left<cr>",  desc = "Treewalker left" },
    { "<C-l>", "<cmd>Treewalker Right<cr>", desc = "Treewalker right" },
  },
}
