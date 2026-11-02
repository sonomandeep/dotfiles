local autotag = require("config.autotag")
assert(autotag.install_task, "tree-sitter CLI is required for the parser tests")
assert(autotag.install_task:wait(300000), "Autotag parser installation failed")
assert(
  vim.wait(1000, function()
    return autotag.ready
  end, 20),
  "Parser runtime paths were not refreshed"
)

-- Files opened before parser installation finished should be highlighted too.
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "typescript" then
    assert(vim.treesitter.highlighter.active[bufnr], "Pre-opened TypeScript buffer was not highlighted")
  end
end

local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local function keys(input)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(input, true, false, true), "xt", false)
end
local function check_line(expected)
  local actual = vim.api.nvim_get_current_line()
  assert(actual == expected, vim.inspect({ filetype = vim.bo.filetype, expected = expected, actual = actual }))
end
local function tag_buffer(ft, extension)
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, temp .. "/tags." .. extension)
  vim.bo.filetype = ft
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "<div " })
  vim.api.nvim_win_set_cursor(0, { 1, 4 })
  keys("i><Esc>")
  check_line("<div></div> ")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Tree-sitter highlighting must be active")
  assert(not vim.bo.indentexpr:find("nvim-treesitter", 1, true), "Tree-sitter indentation must remain disabled")
  assert(vim.wo.foldmethod ~= "expr", "Tree-sitter folding must remain disabled")
  keys("0lciwspan<Esc>")
  check_line("<span></span> ")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "<article" })
  keys("A><Esc>")
  check_line("<article></article>")
  vim.bo.modified = false
end

local ok, err = pcall(function()
  tag_buffer("html", "html")
  tag_buffer("javascriptreact", "jsx")
  tag_buffer("typescriptreact", "tsx")
  tag_buffer("astro", "astro")

  for _, ft in ipairs({ "javascript", "typescript", "css" }) do
    vim.cmd.enew()
    vim.bo.filetype = ft
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Missing highlighting for " .. ft)
    assert(vim.treesitter.query.get(ft, "highlights"), "Missing highlight queries for " .. ft)
  end

  -- Astro should parse and highlight its embedded TypeScript and CSS as well.
  vim.cmd.enew()
  vim.bo.filetype = "astro"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "---",
    'const label: string = "hello";',
    "---",
    "<div>{label}</div>",
    "<style>div { color: red; }</style>",
  })
  local parser = vim.treesitter.get_parser(0)
  parser:parse(true)
  local languages = {}
  parser:for_each_tree(function(_, language_tree)
    languages[language_tree:lang()] = true
  end)
  assert(languages.astro and languages.typescript and languages.css, "Astro language injections are missing")
  vim.bo.modified = false

  vim.cmd.enew()
  vim.bo.filetype = "text"
  assert(
    vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] == nil,
    "Plain text should not use Tree-sitter"
  )

  local repo = temp .. "/repo"
  vim.fn.mkdir(repo, "p")
  local function git(args)
    local command = { "git", "-C", repo, "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false" }
    local result = vim.system(vim.list_extend(command, args), { text = true }):wait()
    assert(result.code == 0, result.stderr)
  end
  git({ "init", "--quiet" })
  vim.fn.writefile({ "original" }, repo .. "/tracked.txt")
  git({ "add", "tracked.txt" })
  git({ "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "fixture" })
  vim.cmd.edit(repo .. "/tracked.txt")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "modified" })
  local gitsigns = require("gitsigns")
  assert(
    vim.wait(5000, function()
      local hunks = gitsigns.get_hunks()
      local status = vim.b.gitsigns_status_dict
      return hunks and #hunks == 1 and status and status.changed == 1
    end, 20),
    "Gitsigns did not detect the changed hunk"
  )
  assert(vim.b.gitsigns_status_dict.changed == 1)
  assert(vim.fn.maparg("]c", "n", false, true).buffer == 1)
  assert(vim.fn.maparg("<leader>gh", "n", false, true).buffer == 1)
  assert(vim.fn.maparg("<leader>gb", "n", false, true).buffer == 1)
  gitsigns.detach()
  vim.bo.modified = false
end)
vim.fn.delete(temp, "rf")
assert(ok, err)
print("PASS: Autotag, Tree-sitter highlighting/injections, unchanged indentation/folding, Git hunks and mappings")
