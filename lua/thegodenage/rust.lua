local function cargo(cmd)
  vim.cmd("botright split | resize 15 | terminal cargo " .. cmd)
  vim.cmd("startinsert")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  desc = "Rust / cargo keymaps",
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc, silent = true })
    end

    map("<leader>rx", function()
      vim.ui.input({ prompt = "cargo " }, function(cmd)
        if cmd and cmd ~= "" then
          cargo(cmd)
        end
      end)
    end, "Cargo: run command")

    map("<leader>rb", function() cargo("build") end, "Cargo: build")
    map("<leader>rc", function() cargo("check") end, "Cargo: check")
    map("<leader>rt", function() cargo("test") end, "Cargo: test")
    map("<leader>rr", function() cargo("run") end, "Cargo: run")
    map("<leader>rl", "<cmd>LspCargoReload<cr>", "Rust: reload Cargo workspace")
  end,
})
