return {
  'sindrets/diffview.nvim',
  keys = {
    {
      '<leader>dv',
      '<cmd>DiffviewOpen<cr>',
      desc = 'Open Diffview',
    },
    {
      '<leader>dc',
      '<cmd>DiffviewClose<cr>',
      desc = 'Close Diffview',
    },
  },
  config = function()
    require('diffview').setup({
      keymaps = {
        view = {
          {
            'n',
            '<leader>q',
            '<cmd>DiffviewClose<cr>',
            { desc = 'Close diffview' }
          },
        },
        file_panel = {
          {
            'n', 
            '<leader>q',
            '<cmd>DiffviewClose<cr>',
            { desc = 'Close diffview' }
          },
        },
      },
    })
  end,
}