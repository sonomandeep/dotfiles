return {
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NormalFloat", -- Floating windows
          "NvimTreeNormal", -- File explorer
          "NeoTreeNormal", -- Neo-tree
          "StatusLine", -- Status line background
          "TabLineFill", -- Tab bar background
          "CursorLine", -- Line highlight
        },
      })
      -- Auto-enable transparency on startup
      vim.cmd("TransparentEnable")
    end,
  },
  -- Ensure the colorscheme doesn't overwrite transparency
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight", -- Or your preferred Bauhaus-like scheme
    },
  },
}
