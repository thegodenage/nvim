local M = {}

local store_root = vim.fn.stdpath("data") .. "/pair"

local function repo_hash(repo_root)
  return vim.fn.sha256(repo_root)
end

local function sanitize_branch(branch)
  return (branch:gsub("/", "--"))
end

function M.path(repo_root, branch)
  return string.format("%s/%s/%s.json", store_root, repo_hash(repo_root), sanitize_branch(branch))
end

function M.load(repo_root, branch)
  local path = M.path(repo_root, branch)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return nil
  end
  return data
end

function M.save(repo_root, branch, data)
  local path = M.path(repo_root, branch)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = assert(io.open(path, "w"))
  f:write(vim.json.encode(data))
  f:close()
end

return M
