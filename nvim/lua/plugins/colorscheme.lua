return {
  {
    "scottmckendry/cyberdream.nvim",
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_pickers = true,
      })
      vim.cmd("colorscheme cyberdream")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream",
    },
  },
}
