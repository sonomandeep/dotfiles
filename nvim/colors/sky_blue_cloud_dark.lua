local c = {
  bg = "#071E2F",
  fg = "#F2FAFF",

  cursor = "#4FC3FF",
  sel_bg = "#0F4C75",
  sel_fg = "#FFFFFF",

  black = "#041421",
  red = "#FF6B6B",
  green = "#2ED8A7",
  yellow = "#FFD166",
  blue = "#3FA9F5",
  magenta = "#C77DFF",
  cyan = "#4DD9FF",
  white = "#E6F6FF",
  br_black = "#0A2A44",
  br_red = "#FF8787",
  br_green = "#5CF2C2",
  br_yellow = "#FFE08A",
  br_blue = "#6FC4FF",
  br_magenta = "#D4A6FF",
  br_cyan = "#8AEAFF",
  br_white = "#FFFFFF",
}

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "sky_blue_cloud_dark"

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hl("Normal", { fg = c.fg, bg = "none" })
hl("NormalNC", { fg = c.fg, bg = "none" })
hl("NormalFloat", { fg = c.fg, bg = "none" })
hl("FloatBorder", { fg = c.br_blue, bg = "none" })
hl("SignColumn", { bg = "none" })
hl("LineNr", { fg = c.br_black, bg = "none" })
hl("CursorLineNr", { fg = c.br_blue, bg = "none", bold = true })
hl("Cursor", { fg = c.bg, bg = c.cursor })
hl("CursorLine", { bg = "#0A263D" })
hl("CursorColumn", { bg = "#0A263D" })
hl("VertSplit", { fg = "#0A263D", bg = "none" })
hl("WinSeparator", { fg = "#0A263D", bg = "none" })

hl("Visual", { bg = c.sel_bg })
hl("VisualNOS", { bg = c.sel_bg })
hl("Search", { fg = c.bg, bg = c.br_yellow })
hl("IncSearch", { fg = c.bg, bg = c.br_yellow })

hl("Comment", { fg = c.br_black, italic = true })
hl("Constant", { fg = c.br_blue })
hl("String", { fg = c.br_green })
hl("Character", { fg = c.br_green })
hl("Number", { fg = c.br_yellow })
hl("Boolean", { fg = c.br_yellow })
hl("Float", { fg = c.br_yellow })

hl("Identifier", { fg = c.br_magenta })
hl("Function", { fg = c.br_blue })

hl("Statement", { fg = c.blue })
hl("Conditional", { fg = c.blue })
hl("Repeat", { fg = c.blue })
hl("Label", { fg = c.blue })
hl("Operator", { fg = c.fg })
hl("Keyword", { fg = c.br_magenta })
hl("Exception", { fg = c.red })

hl("PreProc", { fg = c.cyan })
hl("Include", { fg = c.cyan })
hl("Define", { fg = c.cyan })
hl("Macro", { fg = c.cyan })

hl("Type", { fg = c.br_cyan })
hl("StorageClass", { fg = c.br_cyan })
hl("Structure", { fg = c.br_cyan })
hl("Typedef", { fg = c.br_cyan })

hl("Special", { fg = c.br_blue })
hl("SpecialComment", { fg = c.br_black, italic = true })
hl("Todo", { fg = c.bg, bg = c.br_yellow, bold = true })

hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.br_yellow })
hl("DiagnosticInfo", { fg = c.br_blue })
hl("DiagnosticHint", { fg = c.br_cyan })

hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.br_yellow })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.br_blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.br_cyan })

hl("Pmenu", { fg = c.fg, bg = "#0A263D" })
hl("PmenuSel", { fg = c.bg, bg = c.br_blue })
hl("PmenuSbar", { bg = "#071E2F" })
hl("PmenuThumb", { bg = "#0F4C75" })

hl("StatusLine", { fg = c.fg, bg = "none" })
hl("StatusLineNC", { fg = c.br_black, bg = "none" })
hl("TabLine", { fg = c.br_black, bg = "none" })
hl("TabLineSel", { fg = c.br_blue, bg = "none", bold = true })
hl("TabLineFill", { bg = "none" })

hl("DiffAdd", { bg = "#0B3A2C" })
hl("DiffChange", { bg = "#0B2E4A" })
hl("DiffDelete", { bg = "#3A1220" })
hl("DiffText", { bg = "#0F4C75" })
