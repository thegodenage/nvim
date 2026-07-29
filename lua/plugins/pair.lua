return {
  dir = vim.fn.stdpath("config"),
  name = "pair.nvim",
  lazy = true,
  keys = {
    {
      "<leader>pair",
      function()
        require("pair").start()
      end,
      desc = "Pair programming partner",
    },
  },
  opts = {
    caveman_level = "lite",
    caveman_plugin_dir = vim.fn.expand("~/.claude/plugins/cache/caveman/caveman/0d95a81d35a9/plugins/caveman"),
    debounce_ms = 800,
    model = nil,
  },
  config = function(_, opts)
    require("pair").setup(opts)
  end,
}
