local project = require("config.project")
local conform = require("conform")
vim.lsp.enable({ "ts_ls", "astro", "tailwindcss", "oxlint", "gopls" }, false)

assert(#vim.pack.get() == 5, "Expected exactly five plugins")
assert(vim.g.colors_name == "mando", "Custom colorscheme not loaded")
assert(vim.fn.exists(":Explore") == 2, "netrw must remain available")
assert(vim.fn.exists(":FormatToggle") == 2)
assert(package.loaded["lazy"] == nil, "lazy.nvim must not load")

local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
temp = vim.uv.fs_realpath(temp)
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end
local function buffer(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "const value=1" })
  vim.bo[buf].filetype = "typescript"
  return buf
end
local function eq(expected, actual)
  assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end

local ok, err = pcall(function()
  local root = temp .. "/workspace"
  write(root .. "/.git", { "gitdir: elsewhere" })
  write(root .. "/package.json", { '{"devDependencies":{"vite-plus":"*"}}' })
  write(root .. "/apps/web/package.json", { '{"devDependencies":{"tailwindcss":"*"}}' })
  local vp = root .. "/node_modules/.bin/vp"
  write(vp, {
    "#!/bin/sh",
    'printf "%s\\n" "$PWD" "$*" > "' .. temp .. '/invocation"',
    "cat >/dev/null",
    'printf "const value = 1;\\n"',
  })
  vim.fn.setfperm(vp, "rwxr-xr-x")
  local buf = buffer(root .. "/apps/web/src/main.ts")
  eq(root, project.root(buf, {}, { "vite-plus" }))
  eq(root .. "/apps/web", project.root(buf, {}, { "tailwindcss" }))
  eq(vp, project.executable("vp", root .. "/apps/web"))
  eq({ "fmt" }, project.ox_tool(buf, "fmt").args)
  eq({ "lint" }, project.ox_tool(buf, "lint").args)
  assert(conform.get_formatter_info("project_oxfmt", buf).available)
  conform.format({ bufnr = buf, timeout_ms = 2000 })
  eq({ "const value = 1;" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  local invocation = vim.fn.readfile(temp .. "/invocation")
  eq(root, invocation[1])
  assert(invocation[2]:find("fmt --stdin-filepath " .. root, 1, true))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "const value=2" })
  vim.cmd.FormatToggle()
  vim.cmd.write()
  eq({ "const value=2" }, vim.fn.readfile(vim.api.nvim_buf_get_name(buf)))
  vim.cmd.FormatToggle()
  vim.cmd.write()
  eq({ "const value = 1;" }, vim.fn.readfile(vim.api.nvim_buf_get_name(buf)))

  -- A bare Vite config is not permission to use Vite+/Oxfmt defaults.
  local plain = temp .. "/plain"
  write(plain .. "/vite.config.ts", { "export default {}" })
  local plain_buf = buffer(plain .. "/main.ts")
  eq(nil, project.ox_tool(plain_buf, "fmt"))
  eq({}, conform.list_formatters(plain_buf))
  vim.cmd.write()
  eq({ "const value=1" }, vim.fn.readfile(plain .. "/main.ts"))

  -- Do not inherit a formatter from outside the Git checkout.
  write(temp .. "/.oxfmtrc.json", { "{}" })
  write(plain .. "/.git", { "gitdir: elsewhere" })
  eq(nil, project.root(plain_buf, { ".oxfmtrc.json" }))

  -- Standalone Oxc uses local tools, not an implicit global formatter.
  write(plain .. "/.oxfmtrc.json", { "{}" })
  local oxfmt = plain .. "/node_modules/.bin/oxfmt"
  write(oxfmt, { "#!/bin/sh", "cat" })
  vim.fn.setfperm(oxfmt, "rwxr-xr-x")
  eq(oxfmt, project.ox_tool(plain_buf, "fmt").command)
  eq({}, project.ox_tool(plain_buf, "fmt").args)

  -- Astro's TypeScript SDK resolves a workspace-local installation.
  write(root .. "/node_modules/typescript/lib/tsserverlibrary.js", { "" })
  eq(root .. "/node_modules/typescript/lib", project.typescript_sdk(root .. "/apps/web"))

  -- Root callbacks must not start Tailwind in an unrelated project.
  local started = false
  vim.lsp.config.tailwindcss.root_dir(plain_buf, function()
    started = true
  end)
  eq(false, started)

  -- Lazygit should use a native terminal tab and clean up after normal exit.
  local old_path = vim.env.PATH
  write(temp .. "/bin/lazygit", { "#!/bin/sh", "exit 0" })
  vim.fn.setfperm(temp .. "/bin/lazygit", "rwxr-xr-x")
  vim.env.PATH = temp .. "/bin:" .. old_path
  local tabs = #vim.api.nvim_list_tabpages()
  require("config.terminal").lazygit()
  assert(
    vim.wait(3000, function()
      return #vim.api.nvim_list_tabpages() == tabs
    end, 20),
    "Lazygit terminal tab was not cleaned up"
  )
  vim.env.PATH = old_path
end)
assert(ok, err)
print("PASS: startup, plugins, roots, local tools, formatting, toggles, SDK, LSP gating and Lazygit")
dofile(vim.fn.stdpath("config") .. "/tests/utilities.lua")
vim.fn.delete(temp, "rf")
