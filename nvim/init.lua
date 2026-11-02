-- Target: Neovim 0.13 nightly. The APIs used here also work on 0.12.
if vim.fn.has("nvim-0.12") == 0 then
  error("This configuration requires Neovim 0.12 or newer (0.13 nightly recommended)")
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.appearance")
vim.cmd.colorscheme("default")
require("config.plugins")
require("config.lsp")
require("config.keymaps")
