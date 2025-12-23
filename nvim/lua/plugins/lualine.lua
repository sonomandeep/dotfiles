-- Bauhaus / Swiss Design Lualine Configuration
-- Concept: Minimalist typography with primary color accents
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      -- Bauhaus Palette (Matching Ghostty & Tmux)
      local colors = {
        red = "#e60000",
        yellow = "#ffbe00",
        blue = "#0055d4",
        gray = "#4a4a4a",
        black = "#1a1a1a",
      }

      return {
        options = {
          theme = "auto", -- Inherits colors but we will override backgrounds
          component_separators = { left = "|", right = "|" }, -- Geometric grid lines
          section_separators = { left = "", right = "" }, -- No bulky arrows
          globalstatus = true, -- Single bar for Swiss layout
          disabled_filetypes = { statusline = { "dashboard", "alpha", "neo-tree" } },
        },
        sections = {
          -- Left Side: Mode (Red) and Starship-style Cursor
          lualine_a = {
            {
              function()
                return "❯"
              end,
              color = { fg = colors.red },
              padding = { left = 1, right = 0 },
            },
            { "mode", color = { fg = colors.black, gui = "bold" }, padding = { left = 1, right = 1 } },
          },
          -- Git Info (Cobalt Blue for branch)
          lualine_b = {
            { "branch", icon = "", color = { fg = colors.blue, gui = "bold" } },
          },
          -- Middle: File Info (Typographic Gray)
          lualine_c = {
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", color = { fg = colors.gray, gui = "bold" } },
            { "diagnostics", symbols = { error = "■ ", warn = "■ ", info = "■ " } },
          },
          -- Right Side: Progress (Yellow) and Session
          lualine_x = { "encoding", "fileformat" },
          lualine_y = {
            { "location", color = { fg = colors.yellow, gui = "bold" } },
            { "progress", color = { fg = colors.yellow } },
          },
          lualine_z = {
            {
              function()
                return "NEOVIM"
              end,
              color = { fg = colors.red, gui = "bold" },
            },
          },
        },
        -- Remove backgrounds for all sections to maintain transparency
        extensions = { "lazy" },
      }
    end,
    config = function(_, opts)
      local lualine = require("lualine")
      lualine.setup(opts)

      -- Customizing theme to force transparent backgrounds
      local custom_theme = require("lualine.themes.auto")
      for _, mode in pairs(custom_theme) do
        if type(mode) == "table" then
          for _, section in pairs(mode) do
            if type(section) == "table" then
              section.bg = "none"
            end
          end
        end
      end
      lualine.setup({ options = { theme = custom_theme } })
    end,
  },
}
