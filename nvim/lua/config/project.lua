local M = {}

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

-- Search ancestors, including workspace packages, but never leave the Git repo.
function M.root(bufnr, markers, dependencies)
  local filename = type(bufnr) == "string" and bufnr or vim.api.nvim_buf_get_name(bufnr)
  local dir = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
  while dir do
    for _, marker in ipairs(markers or {}) do
      if exists(vim.fs.joinpath(dir, marker)) then
        return dir
      end
    end
    if dependencies then
      local path = vim.fs.joinpath(dir, "package.json")
      local ok, package = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
      end)
      if ok and type(package) == "table" then
        for _, section in ipairs({ "dependencies", "devDependencies", "optionalDependencies" }) do
          for _, name in ipairs(dependencies) do
            if type(package[section]) == "table" and package[section][name] then
              return dir
            end
          end
        end
      end
    end
    if exists(vim.fs.joinpath(dir, ".git")) then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.executable(name, root)
  local dir = root
  while dir do
    local path = vim.fs.joinpath(dir, "node_modules", ".bin", name)
    if vim.fn.executable(path) == 1 then
      return path
    end
    if exists(vim.fs.joinpath(dir, ".git")) then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return vim.fn.exepath(name)
end

-- Vite+ opts a project into its own formatter/linter defaults. Standalone Oxc
-- tools require a dependency or a config; a generic vite.config.ts is not enough.
function M.ox_tool(bufnr, kind)
  local root = M.root(bufnr, {}, { "vite-plus" })
  local name, args = "vp", { kind == "fmt" and "fmt" or "lint" }
  if not root then
    name = kind == "fmt" and "oxfmt" or "oxlint"
    local markers = kind == "fmt" and { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
      or { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
    root = M.root(bufnr, markers, { name })
    args = {}
  end
  if not root then
    return
  end
  local executable = M.executable(name, root)
  if executable ~= "" then
    return { root = root, command = executable, args = args }
  end
end

function M.command(name, args)
  return function(dispatchers, config)
    local executable = M.executable(name, config.root_dir)
    if executable == "" then
      vim.schedule(function()
        vim.notify("Missing LSP executable: " .. name .. ". See nvim/README.md", vim.log.levels.WARN)
      end)
      return nil
    end
    return vim.lsp.rpc.start(vim.list_extend({ executable }, args or {}), dispatchers)
  end
end

return M
