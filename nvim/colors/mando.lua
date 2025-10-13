-- colors/mando.lua — nero + accenti rosso/giallo, trasparente per Ghostty/tmux
local c = {
  fg = "#E6E6E6",
  red = "#FF5252",
  yellow = "#FFD21F",
  yellow_alt = "#FFE166",
  green = "#57FF85",
  blue = "#64B5FF",
  magenta = "#FF84FF",
  cyan = "#73FFFF",
  gray = "#555555",
  border = "#555555",
}

vim.opt.background = "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "mando"

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- === BASE UI ===
hi("Normal", { fg = c.fg, bg = "none" })
hi("NormalNC", { fg = c.fg, bg = "none" })
hi("NormalFloat", { fg = c.fg, bg = "none" })
hi("FloatBorder", { fg = c.border, bg = "none" })
hi("WinSeparator", { fg = c.border, bg = "none" })
hi("VertSplit", { fg = c.border, bg = "none" })
hi("LineNr", { fg = c.gray, bg = "none" })
hi("CursorLineNr", { fg = c.yellow, bold = true, bg = "none" })
hi("CursorLine", { bg = "none" })
hi("Visual", { bg = "#1A1A1A" })
hi("Search", { fg = "#000000", bg = c.yellow_alt, bold = true })
hi("IncSearch", { fg = "#000000", bg = c.red, bold = true })
hi("StatusLine", { fg = c.fg, bg = "none" })
hi("StatusLineNC", { fg = c.gray, bg = "none" })
hi("Pmenu", { fg = c.fg, bg = "#111111" })
hi("PmenuSel", { fg = "#000000", bg = c.red })
hi("PmenuThumb", { bg = c.red })
hi("MatchParen", { fg = c.yellow_alt, bold = true })

-- === Syntax ===
hi("Comment", { fg = c.gray, italic = true })
hi("Keyword", { fg = c.red, bold = true })
hi("Identifier", { fg = c.fg })
hi("Function", { fg = c.yellow })
hi("Type", { fg = c.blue })
hi("String", { fg = c.green })
hi("Number", { fg = c.magenta })
hi("Boolean", { fg = c.red })
hi("Operator", { fg = c.cyan })
hi("Constant", { fg = c.magenta })
hi("Special", { fg = c.yellow_alt })
hi("DiagnosticError", { fg = c.red })
hi("DiagnosticWarn", { fg = c.yellow })
hi("DiagnosticInfo", { fg = c.cyan })
hi("DiagnosticHint", { fg = c.blue })
