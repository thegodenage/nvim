vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", ":NvimTreeFocus<CR>", { desc = "Focus file tree" })

-- Closes quickfix/location list panes (e.g. `gr` results) and lands the cursor
-- back where it started. The target window is resolved before closing, because
-- closing the pane you are standing in otherwise hands focus to whatever window
-- the layout happens to pick, usually the file tree.
local function close_result_lists()
  local current = vim.api.nvim_get_current_win()
  local previous = vim.fn.win_getid(vim.fn.winnr("#"))

  pcall(vim.cmd.cclose)
  pcall(vim.cmd.lclose)

  local target = vim.api.nvim_win_is_valid(current) and current or previous
  if vim.api.nvim_win_is_valid(target) then
    vim.api.nvim_set_current_win(target)
  end
end

vim.keymap.set("n", "<leader>q", close_result_lists, { desc = "Close quickfix / location list" })
vim.api.nvim_create_user_command("ListClose", close_result_lists, { desc = "Close quickfix / location list" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(args)
    vim.keymap.set("n", "q", close_result_lists, { buffer = args.buf, desc = "Close quickfix / location list" })
  end,
})

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.termguicolors = true

vim.opt.clipboard = "unnamedplus"

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
  },
  pattern = {
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.ya?ml"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
  },
})
