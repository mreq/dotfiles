return {
	"stevearc/oil.nvim",
	lazy = false,
	opts = {},
	keymaps = {
		["<CR>"] = { "actions.select", opts = { close = true } },
	},
	keys = {
		{ "<leader>l", function() require("oil").open() end, desc = "Open folder in Oil" },
	},
}
