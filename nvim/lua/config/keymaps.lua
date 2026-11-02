local map = vim.keymap.set
local function picker(name)
  return function()
    local filename = vim.api.nvim_buf_get_name(0)
    local cwd = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
    cwd = vim.fs.root(cwd, { ".git", "pnpm-workspace.yaml", "package.json", "go.mod" }) or cwd
    require("fzf-lua")[name]({ cwd = cwd })
  end
end

map("i", "jj", "<Esc>", { desc = "Leave insert mode" })
map("n", "<leader>ff", picker("files"), { desc = "Find files" })
map("n", "<leader>fg", picker("live_grep"), { desc = "Search project text" })
map("n", "<leader>fb", picker("buffers"), { desc = "Find buffers" })
map("n", "<leader>fd", picker("diagnostics_workspace"), { desc = "Find diagnostics" })
map("n", "<leader>fs", picker("lsp_document_symbols"), { desc = "Find document symbols" })
map("n", "<leader>e", "<Cmd>Explore<CR>", { desc = "Explore files (netrw)" })
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "never" })
end, { desc = "Format with project formatter" })
map("n", "<leader>gg", function()
  require("config.terminal").lazygit()
end, { desc = "Lazygit" })
