local M = {}

local function git_cmd(args, cwd)
  local obj = vim.system({ "git", unpack(args) }, { cwd = cwd, text = true })
  local result = obj:wait()
  if result.code ~= 0 then
    return nil, result.stderr or ""
  end
  return (result.stdout or ""):gsub("\n$", ""), nil
end

function M.repo_root(cwd)
  cwd = cwd or vim.loop.cwd()
  local root, err = git_cmd({ "rev-parse", "--show-toplevel" }, cwd)
  if not root or root == "" then
    return nil, err or "not a git repository"
  end
  return root
end

function M.branch(repo_root)
  local branch, err = git_cmd({ "rev-parse", "--abbrev-ref", "HEAD" }, repo_root)
  if not branch or branch == "" then
    return nil, err or "could not resolve branch"
  end
  return branch
end

function M.relative_path(repo_root, file_path)
  if file_path == "" then
    return "(unsaved buffer)"
  end
  if vim.startswith(file_path, repo_root) then
    local rel = file_path:sub(#repo_root + 2)
    return rel ~= "" and rel or vim.fn.fnamemodify(file_path, ":t")
  end
  return file_path
end

function M.diff(repo_root, mode)
  mode = mode or "delta"
  local parts = {}

  if mode == "initial" then
    local diff, err = git_cmd({ "diff", "HEAD" }, repo_root)
    if diff and diff ~= "" then
      parts[#parts + 1] = "### git diff HEAD\n```diff\n" .. diff .. "\n```"
    end
    local stat, _ = git_cmd({ "diff", "HEAD", "--stat" }, repo_root)
    if stat and stat ~= "" then
      parts[#parts + 1] = "### stat\n" .. stat
    end
    if #parts == 0 then
      parts[#parts + 1] = "(no changes vs HEAD yet)"
    end
    return table.concat(parts, "\n\n")
  end

  local unstaged, _ = git_cmd({ "diff" }, repo_root)
  if unstaged and unstaged ~= "" then
    parts[#parts + 1] = "### unstaged\n```diff\n" .. unstaged .. "\n```"
  end

  local staged, _ = git_cmd({ "diff", "--cached" }, repo_root)
  if staged and staged ~= "" then
    parts[#parts + 1] = "### staged\n```diff\n" .. staged .. "\n```"
  end

  if #parts == 0 then
    parts[#parts + 1] = "(no unstaged or staged changes)"
  end

  return table.concat(parts, "\n\n")
end

function M.build_prompt(opts)
  local caveman = opts.caveman_level or "lite"
  local diff_mode = opts.turn == 1 and "initial" or "delta"
  local diff = M.diff(opts.repo_root, diff_mode)

  return table.concat({
    "/pair-programming /caveman " .. caveman,
    "",
    string.format("Branch: %s | Turn: %d | File: %s", opts.branch, opts.turn, opts.file),
    "",
    "## Since last ping",
    diff,
    "",
    "## Your job this ping",
    "Partner review only. No edits. Build on prior turns if any.",
    "If turn > 1, start by acknowledging what changed since last time.",
    "Max ~120 words unless security concern.",
  }, "\n")
end

return M
