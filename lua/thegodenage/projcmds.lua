-- Per-repo shell commands, stored centrally (not in the repo).
-- Keyed by cwd, persisted to stdpath("data")/projcmds.json.
local store = vim.fn.stdpath("data") .. "/projcmds.json"

local function load()
  local f = io.open(store, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return (ok and data) or {}
end

local function save(data)
  local f = assert(io.open(store, "w"))
  f:write(vim.json.encode(data))
  f:close()
end

local function repo_cmds()
  return load()[vim.fn.getcwd()] or {}
end

local function run(cmd)
  vim.cmd("botright split | resize 15 | terminal " .. cmd)
  vim.cmd("startinsert")
end

local function create()
  vim.ui.input({ prompt = "Name: " }, function(name)
    if not name or name == "" then return end
    vim.ui.input({ prompt = "Command: " }, function(cmd)
      if not cmd or cmd == "" then return end
      local data = load()
      local cwd = vim.fn.getcwd()
      data[cwd] = data[cwd] or {}
      data[cwd][name] = cmd
      save(data)
      vim.notify("Saved project command: " .. name)
    end)
  end)
end

local function delete(name)
  local data = load()
  local cwd = vim.fn.getcwd()
  if data[cwd] then
    data[cwd][name] = nil
    save(data)
  end
end

-- Telescope picker: <CR> runs, <C-d> deletes (and refreshes the list).
local function explore()
  local cmds = repo_cmds()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function make_finder()
    local names = vim.tbl_keys(repo_cmds())
    table.sort(names)
    return finders.new_table({
      results = names,
      entry_maker = function(name)
        return { value = name, display = name .. "  →  " .. cmds[name], ordinal = name }
      end,
    })
  end

  if vim.tbl_isempty(cmds) then
    return vim.notify("No project commands here yet. Use :Pcc to create one.")
  end

  pickers
    .new({}, {
      prompt_title = "Project commands (" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. ")",
      finder = make_finder(),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          if entry then run(cmds[entry.value]) end
        end)
        local function delete_selected()
          local entry = action_state.get_selected_entry()
          if not entry then return end
          delete(entry.value)
          cmds = repo_cmds()
          action_state.get_current_picker(bufnr):refresh(make_finder(), {})
        end
        map("i", "<C-d>", delete_selected)
        map("n", "<C-d>", delete_selected)
        map("n", "dd", delete_selected)
        return true
      end,
    })
    :find()
end

local function run_picker()
  local cmds = repo_cmds()
  local names = vim.tbl_keys(cmds)
  if #names == 0 then return vim.notify("No project commands here. Use :Pcc to create one.") end
  table.sort(names)
  vim.ui.select(names, { prompt = "Run project command:" }, function(name)
    if name then run(cmds[name]) end
  end)
end

vim.api.nvim_create_user_command("Pcc", create, { desc = "Project command: create" })
vim.api.nvim_create_user_command("Pcr", run_picker, { desc = "Project command: run" })
vim.api.nvim_create_user_command("Pce", explore, { desc = "Project commands: explore (Telescope)" })

-- Lowercase cmdline aliases (user commands must be capitalized).
vim.cmd([[
  cnoreabbrev <expr> pcc (getcmdtype() == ':' && getcmdline() ==# 'pcc') ? 'Pcc' : 'pcc'
  cnoreabbrev <expr> pcr (getcmdtype() == ':' && getcmdline() ==# 'pcr') ? 'Pcr' : 'pcr'
  cnoreabbrev <expr> pce (getcmdtype() == ':' && getcmdline() ==# 'pce') ? 'Pce' : 'pce'
]])

vim.keymap.set("n", "<leader>Pc", create, { desc = "Project command: create" })
vim.keymap.set("n", "<leader>Pr", run_picker, { desc = "Project command: run" })
vim.keymap.set("n", "<leader>Pe", explore, { desc = "Project commands: explore" })
