vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.mouse = ""
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.opt.statusline = "%f %h%m%r%=%l:%c %P"

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = false,
  float = { border = "single" },
})
