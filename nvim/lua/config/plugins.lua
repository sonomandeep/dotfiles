vim.pack.add({
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/stevearc/conform.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/windwp/nvim-ts-autotag",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/folke/which-key.nvim",
}, { confirm = false })

require("config.autotag")
require("config.git")
require("config.which-key")

require("fzf-lua").setup({
  "default-title",
  winopts = { border = "single", preview = { default = "builtin" } },
  files = { hidden = true, fd_opts = "--type f --hidden --exclude .git" },
  grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git' -e" },
})

local project = require("config.project")
local function oxc_formatters(bufnr)
  return project.ox_tool(bufnr, "fmt") and { "project_oxfmt" } or {}
end

local formatters_by_ft = {}
for _, ft in ipairs({
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "astro",
  "json",
  "jsonc",
  "css",
  "scss",
  "less",
  "html",
  "markdown",
  "markdown.mdx",
  "yaml",
  "toml",
  "graphql",
}) do
  formatters_by_ft[ft] = oxc_formatters
end
formatters_by_ft.go = function(bufnr)
  return project.root(bufnr, { "go.mod", "go.work" }) and { "gofmt" } or {}
end

require("conform").setup({
  formatters_by_ft = formatters_by_ft,
  formatters = {
    project_oxfmt = {
      command = function(_, ctx)
        return project.ox_tool(ctx.buf, "fmt").command
      end,
      args = function(_, ctx)
        local tool = project.ox_tool(ctx.buf, "fmt")
        return vim.list_extend(vim.deepcopy(tool.args), { "--stdin-filepath", "$FILENAME" })
      end,
      cwd = function(_, ctx)
        return project.ox_tool(ctx.buf, "fmt").root
      end,
      stdin = true,
      require_cwd = true,
    },
  },
  default_format_opts = { lsp_format = "never" },
  format_on_save = function(bufnr)
    if vim.bo[bufnr].buftype == "" and not vim.b[bufnr].disable_autoformat then
      return { timeout_ms = 2000, lsp_format = "never" }
    end
  end,
})

vim.api.nvim_create_user_command("FormatToggle", function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  vim.notify("Format on save: " .. (vim.b.disable_autoformat and "off" or "on"))
end, { desc = "Toggle format on save for this buffer" })
