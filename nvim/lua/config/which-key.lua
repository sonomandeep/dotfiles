require("which-key").setup({
  preset = "classic",
  delay = 400,
  win = { border = "single" },
  icons = {
    mappings = false,
    breadcrumb = ">",
    separator = "->",
    ellipsis = "...",
  },
  -- Keep key labels readable without Nerd Font glyphs, including Ctrl/Esc keys.
  replace = { key = { { "<Space>", "SPC" } } },
  plugins = { spelling = { enabled = false } },
  spec = {
    { "<leader>f", group = "Search" },
    { "<leader>g", group = "Git" },
    { "<leader>c", group = "Code" },
  },
})
