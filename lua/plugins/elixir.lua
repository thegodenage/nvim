return {
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    ft = { "elixir", "eelixir", "heex" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "<leader>mx",
        function()
          vim.cmd("Mix")
        end,
        ft = { "elixir", "eelixir", "heex" },
        desc = "Mix command",
      },
    },
    config = function()
      local elixirls = require("elixir.elixirls")
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      require("elixir").setup({
        nextls = { enable = false },
        elixirls = {
          enable = true,
          capabilities = capabilities,
          settings = elixirls.settings({
            dialyzerEnabled = false,
            enableTestLenses = true,
            fetchDeps = false,
            suggestSpecs = true,
          }),
          on_attach = function(client, bufnr)
            local opts = function(desc)
              return { buffer = bufnr, desc = desc, silent = true }
            end

            vim.keymap.set("n", "<leader>cfp", ":ElixirFromPipe<CR>", opts("Elixir: from pipe"))
            vim.keymap.set("n", "<leader>ctp", ":ElixirToPipe<CR>", opts("Elixir: to pipe"))
            vim.keymap.set("v", "<leader>cem", ":ElixirExpandMacro<CR>", opts("Elixir: expand macro"))
            vim.keymap.set("n", "<leader>ct", vim.lsp.codelens.run, opts("Elixir: run test (codelens)"))
            vim.keymap.set("n", "<leader>cr", ":ElixirRestart<CR>", opts("Elixir: restart LSP"))
            vim.keymap.set("n", "<leader>co", ":ElixirOutputPanel<CR>", opts("Elixir: LSP output panel"))

            if client:supports_method("textDocument/codeLens") then
              vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
                buffer = bufnr,
                callback = function()
                  vim.lsp.codelens.refresh({ bufnr = bufnr })
                end,
              })
              vim.lsp.codelens.refresh({ bufnr = bufnr })
            end
          end,
        },
        projectionist = { enable = true },
      })
    end,
  },
}
