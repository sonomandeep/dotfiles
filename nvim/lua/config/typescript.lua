local M = {}
local project = require("config.project")
local warned = {}

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_json(path)
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  return ok and type(data) == "table" and data or nil
end

local function warn(root, message)
  local key = root .. message
  if not warned[key] then
    warned[key] = true
    vim.schedule(function()
      vim.notify(message .. "\nProject: " .. root, vim.log.levels.WARN)
    end)
  end
end

-- Resolve the installed package, including a hoisted workspace dependency.
-- Never fall back to a global compiler or infer a version from a semver range.
function M.resolve(root)
  local owner = project.root(vim.fs.joinpath(root, "package.json"), { "node_modules/typescript/package.json" })
  if not owner then
    return
  end
  local dir = vim.fs.joinpath(owner, "node_modules", "typescript")
  local package = read_json(vim.fs.joinpath(dir, "package.json"))
  local major = package and type(package.version) == "string" and tonumber(package.version:match("^(%d+)"))
  if major then
    return {
      major = major,
      version = package.version,
      sdk = vim.fs.joinpath(dir, "lib"),
      tsc = vim.fs.joinpath(dir, "bin", "tsc"),
    }
  end
end

function M.root(native)
  return function(bufnr, on_dir)
    local dir = project.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
    if not dir then
      return
    end
    local ts = M.resolve(dir)
    if not ts then
      warn(dir, "No project-local TypeScript SDK found. Install the project's dependencies with vp install.")
      return
    end
    if ts.major < 5 then
      warn(dir, "Unsupported TypeScript " .. ts.version .. ": this configuration supports TypeScript 5 and newer.")
      return
    end
    if native ~= (ts.major >= 7) then
      return
    end
    if native then
      if vim.fn.executable(ts.tsc) ~= 1 then
        warn(dir, "The project's native TypeScript executable is missing. Run vp install.")
        return
      end
    elseif not exists(vim.fs.joinpath(ts.sdk, "tsserver.js")) then
      warn(dir, "The project's TypeScript SDK is incomplete. Run vp install.")
      return
    elseif project.executable("typescript-language-server", dir) == "" then
      warn(dir, "Missing typescript-language-server. Run install.sh or install it with vp install --global.")
      return
    end
    on_dir(dir)
  end
end

function M.native_command(dispatchers, config)
  local ts = assert(M.resolve(config.root_dir), "Project TypeScript dependency disappeared; restart the LSP")
  return vim.lsp.rpc.start({ ts.tsc, "--lsp", "--stdio" }, dispatchers, { cwd = config.root_dir })
end

function M.classic_init(_, config)
  local ts = assert(M.resolve(config.root_dir), "Project TypeScript dependency disappeared; restart the LSP")
  config.init_options.tsserver = { path = vim.fs.joinpath(ts.sdk, "tsserver.js") }
end

local function compatible_sdk(sdk)
  local package = read_json(vim.fs.joinpath(sdk, "..", "package.json"))
  local major = package and type(package.version) == "string" and tonumber(package.version:match("^(%d+)"))
  return major
    and major >= 5
    and major < 7
    and (exists(vim.fs.joinpath(sdk, "typescript.js")) or exists(vim.fs.joinpath(sdk, "tsserverlibrary.js")))
end

function M.astro_sdk(root)
  local ts = M.resolve(root)
  if ts and compatible_sdk(ts.sdk) then
    return ts.sdk
  end
  -- Private editor SDK: never exposes a tsc/tsserver binary on the shell PATH.
  local sdk = vim.fn.stdpath("data") .. "/lsp/astro-sdk/node_modules/typescript/lib"
  if compatible_sdk(sdk) then
    return sdk
  end
end

function M.astro_root(bufnr, on_dir)
  local dir = project.root(bufnr, { "package.json", "tsconfig.json", ".git" })
  if dir and project.executable("astro-ls", dir) ~= "" then
    if M.astro_sdk(dir) then
      on_dir(dir)
    else
      warn(dir, "Astro needs a JavaScript TypeScript SDK (5/6). Run install.sh to install its isolated SDK.")
    end
  end
end

return M
