local state_mod = require("pair.state")
local context_mod = require("pair.context")
local buffer_mod = require("pair.buffer")
local agent_mod = require("pair.agent")

local M = {}

local AU_GROUP = "PairPartner"

M.config = {
  caveman_level = "lite",
  caveman_plugin_dir = vim.fn.expand("~/.claude/plugins/cache/caveman/caveman/0d95a81d35a9/plugins/caveman"),
  debounce_ms = 800,
  model = nil,
}

local session = nil
local starting = false

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Pair Partner" })
end

local function clear_autocmds()
  pcall(vim.api.nvim_del_augroup_by_name, AU_GROUP)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function cancel_job()
  if session and session.job then
    pcall(function()
      session.job:kill(9)
    end)
  end
  if session then
    session.job = nil
    session.pending = false
  end
end

function M.stop()
  if not session then
    return
  end

  cancel_job()
  if session.debounce_timer then
    pcall(vim.fn.timer_stop, session.debounce_timer)
  end
  clear_autocmds()

  local work_win = session.work_win
  session = nil

  if work_win and vim.api.nvim_win_is_valid(work_win) then
    vim.api.nvim_set_current_win(work_win)
  end

  notify("Pair session ended")
end

local function persist_state()
  if not session then
    return
  end
  state_mod.save(session.repo_root, session.branch, {
    chat_id = session.chat_id,
    branch = session.branch,
    repo_root = session.repo_root,
    turn = session.turn,
    last_file = session.last_file,
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  })
end

local function run_ping(initial)
  if not session or session.pending then
    return
  end

  session.pending = true
  local turn = session.turn
  local file = vim.api.nvim_buf_get_name(session.work_buf)
  session.last_file = context_mod.relative_path(session.repo_root, file)

  if not initial then
    buffer_mod.append_turn_header(session.partner_buf, turn)
    buffer_mod.set_header(session.partner_buf, session.branch, turn)
  end
  session.response_start = buffer_mod.response_start(session.partner_buf)
  buffer_mod.set_thinking(session.partner_buf, session.partner_win, true, session.response_start)

  local prompt = context_mod.build_prompt({
    repo_root = session.repo_root,
    branch = session.branch,
    turn = turn,
    file = session.last_file,
    caveman_level = M.config.caveman_level,
  })

  session.job = agent_mod.run({
    repo_root = session.repo_root,
    chat_id = session.chat_id,
    prompt = prompt,
    model = M.config.model,
    caveman_plugin_dir = M.config.caveman_plugin_dir,
  }, {
    on_text = function(text, _)
      if not session then
        return
      end
      buffer_mod.set_thinking(session.partner_buf, session.partner_win, false, session.response_start)
      buffer_mod.set_response(session.partner_buf, session.partner_win, text, session.response_start)
    end,
    on_error = function(err)
      if not session then
        return
      end
      session.pending = false
      session.job = nil
      buffer_mod.append_error(session.partner_buf, session.partner_win, err, session.response_start)
      persist_state()
    end,
    on_done = function(_)
      if not session then
        return
      end
      buffer_mod.set_thinking(session.partner_buf, session.partner_win, false, session.response_start)
      session.pending = false
      session.job = nil
      persist_state()
    end,
  })
end

local function schedule_ping()
  if not session or session.pending then
    return
  end

  if session.debounce_timer then
    pcall(vim.fn.timer_stop, session.debounce_timer)
  end

  session.debounce_timer = vim.fn.timer_start(M.config.debounce_ms, function()
    if not session then
      return
    end
    session.turn = session.turn + 1
    run_ping(false)
  end)
end

local function register_autocmds()
  clear_autocmds()
  vim.api.nvim_create_augroup(AU_GROUP, { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = AU_GROUP,
    buffer = session.work_buf,
    callback = function()
      schedule_ping()
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = AU_GROUP,
    buffer = session.partner_buf,
    callback = function()
      M.stop()
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = AU_GROUP,
    buffer = session.partner_buf,
    callback = function()
      M.stop()
    end,
  })
end

local function begin_session(repo_root, branch, branch_state, work_buf)
  if session then
    return
  end

  local turn = (branch_state and branch_state.turn or 0) + 1

  session = {
    repo_root = repo_root,
    branch = branch,
    chat_id = branch_state.chat_id,
    work_buf = work_buf,
    turn = turn,
    last_file = "",
    pending = false,
    job = nil,
    debounce_timer = nil,
  }

  local partner_buf, partner_win, work_win = buffer_mod.open({
    branch = branch,
    turn = turn,
  })

  session.partner_buf = partner_buf
  session.partner_win = partner_win
  session.work_win = work_win

  register_autocmds()
  run_ping(true)
  notify(string.format("Pair session started on %s (turn %d)", branch, turn))
end

function M.start()
  if session then
    notify("Pair session already active — :q the partner buffer to end it", vim.log.levels.WARN)
    return
  end
  if starting then
    return
  end
  starting = true

  local function done_starting()
    starting = false
  end

  local cwd = vim.loop.cwd()
  local repo_root, repo_err = context_mod.repo_root(cwd)
  if not repo_root then
    done_starting()
    notify(repo_err or "not in a git repository", vim.log.levels.ERROR)
    return
  end

  local branch, branch_err = context_mod.branch(repo_root)
  if not branch then
    done_starting()
    notify(branch_err or "could not resolve git branch", vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable("agent") ~= 1 then
    done_starting()
    notify("agent CLI not found in PATH", vim.log.levels.ERROR)
    return
  end

  if M.config.caveman_plugin_dir and vim.fn.isdirectory(M.config.caveman_plugin_dir) ~= 1 then
    notify("caveman plugin dir missing: " .. M.config.caveman_plugin_dir, vim.log.levels.WARN)
  end

  local work_buf = vim.api.nvim_get_current_buf()
  local branch_state = state_mod.load(repo_root, branch) or {}

  if branch_state.chat_id then
    begin_session(repo_root, branch, branch_state, work_buf)
    done_starting()
    return
  end

  notify("Creating pair chat for branch…")
  agent_mod.create_chat(function(chat_id, err)
    done_starting()
    if session then
      return
    end
    if not chat_id then
      notify(err or "failed to create chat", vim.log.levels.ERROR)
      return
    end

    branch_state.chat_id = chat_id
    branch_state.branch = branch
    branch_state.repo_root = repo_root
    branch_state.turn = branch_state.turn or 0
    state_mod.save(repo_root, branch, branch_state)

    begin_session(repo_root, branch, branch_state, work_buf)
  end)
end

return M
