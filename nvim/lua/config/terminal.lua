local M = {}

function M.lazygit()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("Install lazygit with: brew install lazygit", vim.log.levels.WARN)
    return
  end
  local filename = vim.api.nvim_buf_get_name(0)
  local cwd = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
  cwd = vim.fs.root(cwd, ".git") or cwd
  vim.cmd.tabnew()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    cwd = cwd,
    on_exit = function(_, code)
      if code == 0 then
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_list_wins() > 1 then
            vim.api.nvim_win_close(win, true)
          elseif vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end)
      end
    end,
  })
  vim.cmd.startinsert()
end

return M
