local M = {}

-- Ripgrep -g globs for gitignored files that should still appear in <leader>pf.
-- Add entries here to surface other ignored files without enabling no_ignore globally.
M.gitignore_exceptions = {
  "**/*.env*",
  "**/.cursor/**",
}

local function shell_quote(arg)
  return "'" .. arg:gsub("'", "'\\''") .. "'"
end

local function build_find_command(exceptions)
  if vim.fn.executable("rg") ~= 1 then
    return nil
  end

  local base = "rg --files --color never --hidden 2>/dev/null"

  if #exceptions == 0 then
    return { "sh", "-c", base }
  end

  local exception_parts = { "rg", "--files", "--color", "never", "--hidden", "--no-ignore" }
  for _, glob in ipairs(exceptions) do
    table.insert(exception_parts, "-g")
    table.insert(exception_parts, shell_quote(glob))
  end
  table.insert(exception_parts, "2>/dev/null")

  local command = string.format(
    "{ %s; %s; } | sort -u",
    base,
    table.concat(exception_parts, " ")
  )

  return { "sh", "-c", command }
end

function M.find_files(opts)
  opts = opts or {}
  local exceptions = opts.gitignore_exceptions or M.gitignore_exceptions
  local find_command = build_find_command(exceptions)

  if not find_command then
    require("telescope.builtin").find_files(vim.tbl_extend("force", opts, { hidden = true }))
    return
  end

  require("telescope.builtin").find_files(vim.tbl_extend("force", opts, {
    hidden = true,
    find_command = find_command,
  }))
end

return M
