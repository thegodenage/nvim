return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<leader>p", group = "pick / find" },
      { "<leader>x", group = "trouble / diagnostics" },
      { "<leader>c", group = "code / lsp" },
      { "<leader>g", group = "git (fugitive)" },
      { "<leader>h", group = "git hunk / harpoon nav" },
      { "<leader>b", group = "buffer (bufferline)" },
      { "<leader>v", group = "vim help" },
      { "<leader>f", desc = "format" },
      { "<leader>u", desc = "undotree" },
      { "<leader>e", desc = "diagnostic float" },
      { "<leader>a", desc = "harpoon add file" },
      { "<leader>1", desc = "harpoon slot 1" },
      { "<leader>2", desc = "harpoon slot 2" },
      { "<leader>3", desc = "harpoon slot 3" },
      { "<leader>4", desc = "harpoon slot 4" },
      { "<leader>5", desc = "harpoon slot 5" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer-local keymaps",
    },
  },
}
