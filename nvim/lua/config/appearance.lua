local function transparent_background()
  for _, group in ipairs({
    "Normal",
    "NormalNC",
    "EndOfBuffer",
    "SignColumn",
    "FoldColumn",
    "LineNr",
    "WinSeparator",
    "NormalFloat",
    "FloatBorder",
  }) do
    -- Keep the colorscheme's foreground and styles; clear only the background.
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = nil
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("mando_appearance", { clear = true }),
  callback = transparent_background,
})

transparent_background()
