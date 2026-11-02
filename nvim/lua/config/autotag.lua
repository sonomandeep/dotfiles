local M = {}

-- Shared parsers for highlighting and Autotag. No custom folds, indentation
-- or text objects. Keep these separate from the previous config's parsers.
local treesitter = require("nvim-treesitter")
local install_dir = vim.fn.stdpath("data") .. "/autotag"
treesitter.setup({ install_dir = install_dir })
M.parsers = { "html", "javascript", "typescript", "tsx", "astro", "css" }
local filetypes = { "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "astro", "css" }

local function highlight(bufnr)
  if M.ready and vim.list_contains(filetypes, vim.bo[bufnr].filetype) then
    local ok, err = pcall(vim.treesitter.start, bufnr)
    if not ok then
      vim.notify("Tree-sitter highlighting: " .. tostring(err), vim.log.levels.WARN)
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("mando_treesitter", { clear = true }),
  pattern = filetypes,
  callback = function(ev)
    highlight(ev.buf)
  end,
})

if vim.fn.executable("tree-sitter") == 1 then
  M.install_task = treesitter.install(M.parsers)
  M.install_task:await(vim.schedule_wrap(function(err, installed)
    if not err and installed then
      -- Refresh runtime/query caches after the first asynchronous installation.
      vim.opt.runtimepath:remove(install_dir)
      vim.opt.runtimepath:prepend(install_dir)
      M.ready = true
      -- Also highlight files opened while the first parser install was running.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          highlight(bufnr)
        end
      end
    end
  end))
else
  vim.schedule(function()
    vim.notify("Tree-sitter needs parsers. Run: brew install tree-sitter-cli, then restart Neovim", vim.log.levels.WARN)
  end)
end

require("nvim-ts-autotag").setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})

return M
