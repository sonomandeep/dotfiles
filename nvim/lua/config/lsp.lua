local project = require("config.project")
local typescript = require("config.typescript")
local web = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

local function root(executable, markers, dependencies)
  return function(bufnr, on_dir)
    local dir = project.root(bufnr, markers, dependencies)
    if dir and project.executable(executable, dir) ~= "" then
      on_dir(dir)
    end
  end
end

vim.lsp.config("ts_ls", {
  cmd = project.command("typescript-language-server", { "--stdio" }),
  filetypes = web,
  root_dir = typescript.root(false),
  init_options = { hostInfo = "neovim" },
  before_init = typescript.classic_init,
})

vim.lsp.config("tsc", {
  cmd = typescript.native_command,
  filetypes = web,
  root_dir = typescript.root(true),
})

vim.lsp.config("astro", {
  cmd = project.command("astro-ls", { "--stdio" }),
  filetypes = { "astro" },
  root_dir = typescript.astro_root,
  init_options = { typescript = {} },
  before_init = function(_, config)
    config.init_options.typescript.tsdk = typescript.astro_sdk(config.root_dir)
  end,
})

vim.lsp.config("tailwindcss", {
  cmd = project.command("tailwindcss-language-server", { "--stdio" }),
  filetypes = vim.list_extend(vim.deepcopy(web), { "astro", "html", "css" }),
  root_dir = root("tailwindcss-language-server", {
    "tailwind.config.js",
    "tailwind.config.ts",
    "tailwind.config.cjs",
    "tailwind.config.mjs",
  }, { "tailwindcss" }),
  settings = {
    tailwindCSS = {
      classAttributes = { "class", "className", "class:list", "classList" },
      classFunctions = { "cn", "clsx", "cva", "tw" },
    },
  },
})

vim.lsp.config("oxlint", {
  cmd = function(dispatchers, config)
    local tool = project.ox_tool(vim.fs.joinpath(config.root_dir, "package.json"), "lint")
    local args = vim.list_extend({ tool.command }, vim.deepcopy(tool.args))
    args[#args + 1] = "--lsp"
    return vim.lsp.rpc.start(args, dispatchers, { cwd = config.root_dir })
  end,
  filetypes = vim.list_extend(vim.deepcopy(web), { "astro" }),
  root_dir = function(bufnr, on_dir)
    local tool = project.ox_tool(bufnr, "lint")
    if tool then
      on_dir(tool.root)
    end
  end,
})

vim.lsp.config("gopls", {
  cmd = project.command("gopls"),
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = root("gopls", { "go.work", "go.mod", ".git" }),
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("mando_lsp", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      -- Complete identifiers too, not just server-provided punctuation triggers.
      local triggers = client.server_capabilities.completionProvider.triggerCharacters or {}
      for char in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
        if not vim.list_contains(triggers, char) then
          triggers[#triggers + 1] = char
        end
      end
      client.server_capabilities.completionProvider.triggerCharacters = triggers
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
  end,
})

vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, { desc = "LSP completion" })
vim.lsp.enable({ "ts_ls", "tsc", "astro", "tailwindcss", "oxlint", "gopls" })
