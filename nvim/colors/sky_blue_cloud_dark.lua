local c = {
  bg = "#071E2F",
  fg = "#F8FBFF",

  cursor = "#5FD3FF",
  sel_bg = "#165F90",

  black = "#020D17",
  br_black = "#123A5A",

  red = "#FF4D6D",
  br_red = "#FF7A8A",

  green = "#2CFFB7",
  br_green = "#72FFD6",

  yellow = "#FFD24A",
  br_yellow = "#FFE58A",

  blue = "#3FA9F5",
  br_blue = "#7CC8FF",

  magenta = "#D36BFF",
  br_magenta = "#E6A8FF",

  cyan = "#2FEAFF",
  br_cyan = "#8AF4FF",

  white = "#EEF7FF",
  br_white = "#FFFFFF",

  ui_0 = "#0B2F4A",
  ui_1 = "#0F3A5C",
  ui_2 = "#1C6FA6",
}

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "sky_blue_cloud_dark_vivid2"

local function hl(g, o)
  vim.api.nvim_set_hl(0, g, o)
end

hl("Normal", { fg = c.fg, bg = "none" })
hl("NormalNC", { fg = c.fg, bg = "none" })
hl("NormalFloat", { fg = c.fg, bg = "none" })
hl("FloatBorder", { fg = c.br_blue, bg = "none" })
hl("SignColumn", { bg = "none" })
hl("LineNr", { fg = c.br_black, bg = "none" })
hl("CursorLineNr", { fg = c.br_blue, bg = "none", bold = true })
hl("Cursor", { fg = c.bg, bg = c.cursor })
hl("CursorLine", { bg = c.ui_0 })
hl("CursorColumn", { bg = c.ui_0 })
hl("VertSplit", { fg = c.ui_0, bg = "none" })
hl("WinSeparator", { fg = c.ui_0, bg = "none" })

hl("Visual", { bg = c.sel_bg })
hl("Search", { fg = c.bg, bg = c.br_yellow, bold = true })
hl("IncSearch", { fg = c.bg, bg = c.br_yellow, bold = true })

hl("Comment", { fg = c.br_black, italic = true })
hl("Todo", { fg = c.bg, bg = c.br_yellow, bold = true })

hl("String", { fg = c.green })
hl("Character", { fg = c.green })
hl("Number", { fg = c.yellow })
hl("Boolean", { fg = c.yellow })
hl("Float", { fg = c.yellow })

hl("Identifier", { fg = c.cyan })
hl("Function", { fg = c.br_blue, bold = true })

hl("Keyword", { fg = c.magenta, bold = true })
hl("Statement", { fg = c.magenta, bold = true })
hl("Conditional", { fg = c.magenta, bold = true })
hl("Repeat", { fg = c.magenta, bold = true })
hl("Exception", { fg = c.red, bold = true })
hl("Operator", { fg = c.fg })

hl("Type", { fg = c.br_cyan, bold = true })
hl("StorageClass", { fg = c.br_cyan, bold = true })
hl("Structure", { fg = c.br_cyan, bold = true })
hl("Typedef", { fg = c.br_cyan, bold = true })

hl("Constant", { fg = c.br_magenta })
hl("PreProc", { fg = c.br_cyan })
hl("Include", { fg = c.br_cyan })
hl("Define", { fg = c.br_cyan })
hl("Macro", { fg = c.br_cyan })
hl("Special", { fg = c.br_blue })
hl("SpecialComment", { fg = c.br_black, italic = true })

hl("Pmenu", { fg = c.fg, bg = c.ui_0 })
hl("PmenuSel", { fg = c.bg, bg = c.br_blue, bold = true })
hl("PmenuSbar", { bg = c.ui_1 })
hl("PmenuThumb", { bg = c.ui_2 })

hl("StatusLine", { fg = c.fg, bg = "none" })
hl("StatusLineNC", { fg = c.br_black, bg = "none" })
hl("TabLine", { fg = c.br_black, bg = "none" })
hl("TabLineSel", { fg = c.br_blue, bg = "none", bold = true })
hl("TabLineFill", { bg = "none" })

hl("DiffAdd", { bg = "#073A2E" })
hl("DiffChange", { bg = "#072E4A" })
hl("DiffDelete", { bg = "#3A0F1F" })
hl("DiffText", { bg = c.sel_bg })

hl("DiagnosticError", { fg = c.red, bold = true })
hl("DiagnosticWarn", { fg = c.yellow, bold = true })
hl("DiagnosticInfo", { fg = c.br_blue })
hl("DiagnosticHint", { fg = c.br_cyan })
hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.br_blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.br_cyan })

hl("@comment", { link = "Comment" })
hl("@string", { link = "String" })
hl("@string.regex", { fg = c.br_magenta })
hl("@string.escape", { fg = c.br_yellow, bold = true })
hl("@character", { link = "Character" })
hl("@number", { link = "Number" })
hl("@boolean", { link = "Boolean" })
hl("@float", { link = "Float" })

hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.cyan, italic = true })
hl("@parameter", { fg = c.br_cyan })
hl("@property", { fg = c.cyan })
hl("@field", { fg = c.cyan })

hl("@function", { link = "Function" })
hl("@function.builtin", { fg = c.br_blue, bold = true })
hl("@method", { fg = c.br_blue })
hl("@constructor", { fg = c.br_cyan, bold = true })

hl("@keyword", { link = "Keyword" })
hl("@keyword.return", { fg = c.red, bold = true })
hl("@keyword.operator", { fg = c.magenta, bold = true })
hl("@operator", { link = "Operator" })

hl("@type", { link = "Type" })
hl("@type.builtin", { fg = c.br_cyan, bold = true })
hl("@constant", { fg = c.br_magenta })
hl("@constant.builtin", { fg = c.br_magenta, bold = true })
hl("@punctuation.delimiter", { fg = c.br_black })
hl("@punctuation.bracket", { fg = c.br_blue })
hl("@tag", { fg = c.magenta })
hl("@tag.attribute", { fg = c.yellow })
hl("@tag.delimiter", { fg = c.br_black })

hl("@markup.heading", { fg = c.br_blue, bold = true })
hl("@markup.link", { fg = c.cyan, underline = true })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })

hl("@lsp.type.class", { link = "Type" })
hl("@lsp.type.interface", { fg = c.br_cyan, bold = true })
hl("@lsp.type.enum", { fg = c.br_cyan, bold = true })
hl("@lsp.type.function", { link = "Function" })
hl("@lsp.type.method", { fg = c.br_blue })
hl("@lsp.type.parameter", { fg = c.br_cyan })
hl("@lsp.type.property", { fg = c.cyan })
hl("@lsp.type.variable", { fg = c.fg })
