return {
	'nvim-pack/nvim-spectre',
	dependencies = { 'nvim-lua/plenary.nvim' },
	keys = {
		{ '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', desc = "Toggle Spectre" },
		{ '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = "Search current word" },
		{ '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', desc = "Search current word" },
		{ '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', desc = "Search on current file" },
	}
}
