return {
	'rgroli/other.nvim',
	keys = {
		{ "<C- >", "<cmd>Other<cr>", desc = "Other" },
	},
	config = function()
		require("other-nvim").setup({
			mappings = {
				"rails",
			},
		})
	end
}
