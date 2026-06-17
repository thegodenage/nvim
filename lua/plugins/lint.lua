return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      -- python diagnostics come from the ruff LSP server, so leaving python empty here
      -- markdown = { "markdownlint" }, -- needs `npm i -g markdownlint-cli`
    }

    local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = group,
      callback = function()
        if next(lint.linters_by_ft) ~= nil then
          lint.try_lint()
        end
      end,
    })
  end,
}
