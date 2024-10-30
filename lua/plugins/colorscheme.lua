return {
	{
		"catppucin/nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme catppucin]])
		end,
	},
}
