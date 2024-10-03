-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- use alt+hjkl to move between windows
vim.keymap.set("n", "<A-h>", "<C-w>h")
vim.keymap.set("n", "<A-j>", "<C-w>j")
vim.keymap.set("n", "<A-k>", "<C-w>k")
vim.keymap.set("n", "<A-l>", "<C-w>l")

-- use alt+HJKL to move to windows
vim.keymap.set("n", "<A-H>", "<C-w>H")
vim.keymap.set("n", "<A-J>", "<C-w>J")
vim.keymap.set("n", "<A-K>", "<C-w>K")
vim.keymap.set("n", "<A-L>", "<C-w>L")

-- tab to cycle through buffers
vim.keymap.set("n", "<Tab>", "<cmd>bn<cr>")
vim.keymap.set("n", "<S-Tab>", "<cmd>bp<cr>")
