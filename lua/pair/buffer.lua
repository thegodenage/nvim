local M = {}

function M.open(opts)
  local work_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local partner_win = vim.api.nvim_get_current_win()
  local partner_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(partner_win, partner_buf)
  vim.api.nvim_buf_set_name(partner_buf, "Pair Partner")
  vim.bo[partner_buf].buftype = "nofile"
  vim.bo[partner_buf].bufhidden = "wipe"
  vim.bo[partner_buf].swapfile = false
  vim.bo[partner_buf].filetype = "markdown"
  vim.bo[partner_buf].modifiable = true

  local header = string.format("# Pair Partner — %s — turn %d", opts.branch, opts.turn)
  vim.api.nvim_buf_set_lines(partner_buf, 0, -1, false, { header, "" })

  vim.api.nvim_set_current_win(work_win)

  return partner_buf, partner_win, work_win
end

function M.set_header(partner_buf, branch, turn)
  if not vim.api.nvim_buf_is_valid(partner_buf) then
    return
  end
  local header = string.format("# Pair Partner — %s — turn %d", branch, turn)
  vim.bo[partner_buf].modifiable = true
  -- end=2 replaces existing header lines; end=0 would insert and duplicate
  vim.api.nvim_buf_set_lines(partner_buf, 0, 2, false, { header, "" })
end

function M.append_turn_header(partner_buf, turn)
  if not vim.api.nvim_buf_is_valid(partner_buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(partner_buf, 0, -1, false)
  if #lines > 0 and lines[#lines] ~= "" then
    table.insert(lines, "")
  end
  vim.list_extend(lines, { "---", string.format("## Turn %d", turn), "" })
  vim.bo[partner_buf].modifiable = true
  vim.api.nvim_buf_set_lines(partner_buf, 0, -1, false, lines)
end

function M.response_start(partner_buf)
  return vim.api.nvim_buf_line_count(partner_buf) + 1
end

function M.set_thinking(partner_buf, partner_win, thinking, response_start)
  if not vim.api.nvim_buf_is_valid(partner_buf) then
    return
  end

  local marker = "* thinking..."
  vim.bo[partner_buf].modifiable = true

  if thinking then
    local prefix = vim.api.nvim_buf_get_lines(partner_buf, 0, response_start - 1, false)
    vim.api.nvim_buf_set_lines(partner_buf, response_start - 1, -1, false, { marker })
  else
    local lines = vim.api.nvim_buf_get_lines(partner_buf, response_start - 1, -1, false)
    if lines[1] == marker then
      vim.api.nvim_buf_set_lines(partner_buf, response_start - 1, -1, false, {})
    end
  end

  M.scroll_if_focused(partner_buf, partner_win)
end

function M.set_response(partner_buf, partner_win, text, response_start)
  if not vim.api.nvim_buf_is_valid(partner_buf) or text == "" then
    return
  end

  vim.bo[partner_buf].modifiable = true
  local prefix = vim.api.nvim_buf_get_lines(partner_buf, 0, response_start - 1, false)
  local response_lines = vim.split(text, "\n", { plain = true })
  vim.list_extend(prefix, response_lines)
  vim.api.nvim_buf_set_lines(partner_buf, 0, -1, false, prefix)
  M.scroll_if_focused(partner_buf, partner_win)
end

function M.append_error(partner_buf, partner_win, err, response_start)
  M.set_thinking(partner_buf, partner_win, false, response_start)
  M.set_response(partner_buf, partner_win, "**Error:** " .. err, response_start)
end

function M.scroll_if_focused(partner_buf, partner_win)
  if not vim.api.nvim_buf_is_valid(partner_buf) then
    return
  end
  if vim.api.nvim_get_current_win() == partner_win then
    local line_count = vim.api.nvim_buf_line_count(partner_buf)
    vim.api.nvim_win_set_cursor(partner_win, { line_count, 0 })
  end
end

return M
