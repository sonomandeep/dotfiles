return {
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    config = function()
      require("ayu").setup({ mirage = false })
      vim.cmd("colorscheme ayu")
    end,
  },
}
