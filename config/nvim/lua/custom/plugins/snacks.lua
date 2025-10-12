return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bufdelete = {},
    bigfile = {},
    explorer = {},
    input = {},
    gitbrowse = {},
  },
  keys = {
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit',
    },
    {
      '<leader>gb',
      function()
        Snacks.git.blame_line()
      end,
      desc = 'blame line',
    },
    {
      '<leader>go',
      function()
        Snacks.gitbrowse()
      end,
      desc = 'Open file on origin',
    },
    {
      '\\',
      function()
        Snacks.explorer()
      end,
      desc = 'Explorer',
    },
    {
      '<S-x>',
      function()
        Snacks.bufdelete()
      end,
      desc = 'Close Buffer',
    },
    {
      '<leader>qq',
      function()
        Snacks.bufdelete.all()
      end,
      desc = 'Close All Buffers',
    },
    {
      '<leader>qo',
      function()
        Snacks.bufdelete.other()
      end,
      desc = 'Close Other Buffers',
    },
  },
}
