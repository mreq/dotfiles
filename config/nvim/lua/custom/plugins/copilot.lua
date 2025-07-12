return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = true,
  auto_trigger = true,

  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        -- Disable the built-in mapping, we'll configure it in nvim-cmp.
        accept = '<A-Space>',
      },
    },
  },
}
