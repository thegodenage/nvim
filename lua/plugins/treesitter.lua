return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
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
          "elixir", "eelixir", "heex",
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

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
          },
        },
      },
    })
  end,
  },
}
