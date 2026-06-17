return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-telescope/telescope-ui-select.nvim",
  },
  keys = {
    { "<leader>pf", function() require("telescope.builtin").find_files() end,    desc = "Find files" },
    { "<C-p>",      function() require("telescope.builtin").git_files() end,     desc = "Find git files" },
    { "<leader>pb", function() require("telescope.builtin").buffers() end,       desc = "Find buffers" },
    { "<leader>pt", function() require("telescope.builtin").treesitter() end,    desc = "Find treesitter symbols" },
    { "<leader>vh", function() require("telescope.builtin").help_tags() end,     desc = "Help tags" },
    { "<leader>pr", function() require("telescope.builtin").resume() end,        desc = "Resume last picker" },
    { "<leader>pd", function() require("telescope.builtin").diagnostics() end,   desc = "Diagnostics" },
    { "<leader>pk", function() require("telescope.builtin").keymaps() end,       desc = "Keymaps" },
    {
      "<leader>pws",
      function() require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") }) end,
      desc = "Grep word under cursor",
    },
    {
      "<leader>pWs",
      function() require("telescope.builtin").grep_string({ search = vim.fn.expand("<cWORD>") }) end,
      desc = "Grep WORD under cursor",
    },
    {
      "<leader>ps",
      function() require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") }) end,
      desc = "Grep prompt",
    },
    {
      "<leader>pg",
      function() require("telescope.builtin").live_grep() end,
      desc = "Live grep",
    },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        path_display = { "truncate" },
        mappings = {
          i = {
            ["<C-u>"] = false,
            ["<C-d>"] = false,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
      },
    })

    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ui-select")
  end,
}
