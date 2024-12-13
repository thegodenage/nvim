require("config.lazy")
require("thegodenage")
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.api.nvim_set_keymap('n', '<C-j>', ':Treewalker Down<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-k>', ':Treewalker Up<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-h>', ':Treewalker Left<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-l>', ':Treewalker Right<CR>', { noremap = true })
