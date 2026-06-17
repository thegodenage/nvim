return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "vimdoc", "lua", "bash",
        "javascript", "typescript", "tsx", "jsdoc",
        "html", "css", "json", "json5", "yaml", "toml",
        "go", "gomod", "gosum", "gowork", "gotmpl",
        "rust", "c",
        "python",
        "ruby",
        "markdown", "markdown_inline",
        "helm",
        "templ",
        "dockerfile", "gitignore", "gitcommit",
        "diff", "regex",
      },

      sync_install = false,
      auto_install = true,

      indent = { enable = true },

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-Space>",
          node_incremental = "<C-Space>",
          scope_incremental = false,
          node_decremental = "<BS>",
        },
      },
    })
  end,
}
