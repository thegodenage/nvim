local M = {}

local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

local function extract_assistant_text(event)
  if event.type ~= "assistant" or not event.message or not event.message.content then
    return nil
  end
  local text = ""
  for _, block in ipairs(event.message.content) do
    if block.type == "text" and block.text then
      text = text .. block.text
    end
  end
  return text ~= "" and text or nil
end

local function process_line(line, handlers, streamed)
  if line == "" then
    return streamed
  end
  local ok, event = pcall(vim.json.decode, line)
  if not ok or type(event) ~= "table" then
    return streamed
  end

  if event.type == "retry" then
    streamed = ""
    return streamed
  end

  local text = extract_assistant_text(event)
  if text then
    if streamed == "" or vim.startswith(text, streamed) then
      streamed = text
    elseif vim.startswith(streamed, text) then
      -- keep longer streamed
    else
      -- agent retry/resume sent a fresh answer — replace, don't append
      streamed = text
    end
    if handlers.on_text then
      handlers.on_text(streamed, false)
    end
  elseif event.type == "result" and event.result then
    streamed = event.result
    if handlers.on_text then
      handlers.on_text(streamed, true)
    end
  end

  return streamed
end

function M.create_chat(callback)
  if not executable("agent") then
    callback(nil, "agent CLI not found in PATH")
    return
  end

  return vim.system({ "agent", "create-chat" }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        callback(nil, (obj.stderr or obj.stdout or "create-chat failed"):gsub("\n$", ""))
        return
      end
      local chat_id = (obj.stdout or ""):gsub("%s+", "")
      if chat_id == "" then
        callback(nil, "create-chat returned empty id")
        return
      end
      callback(chat_id, nil)
    end)
  end)
end

function M.build_args(opts)
  local args = {
    "agent",
    "--print",
    "--output-format",
    "stream-json",
    "--stream-partial-output",
    "--mode",
    "ask",
    "--trust",
    "--workspace",
    opts.repo_root,
    "--resume",
    opts.chat_id,
  }

  if opts.model and opts.model ~= "" then
    vim.list_extend(args, { "--model", opts.model })
  end

  if opts.caveman_plugin_dir and vim.fn.isdirectory(opts.caveman_plugin_dir) == 1 then
    vim.list_extend(args, { "--plugin-dir", opts.caveman_plugin_dir })
  end

  table.insert(args, opts.prompt)
  return args
end

function M.run(opts, handlers)
  handlers = handlers or {}
  local streamed = ""
  local line_buf = ""

  local function flush_lines(final)
    while true do
      local nl = line_buf:find("\n", 1, true)
      if not nl then
        if final and line_buf ~= "" then
          streamed = process_line(line_buf, handlers, streamed)
          line_buf = ""
        end
        break
      end
      local line = line_buf:sub(1, nl - 1)
      line_buf = line_buf:sub(nl + 1)
      streamed = process_line(line, handlers, streamed)
    end
  end

  local args = M.build_args(opts)
  return vim.system(args, {
    cwd = opts.repo_root,
    text = true,
    stdout = function(_, data)
      if not data or data == "" then
        return
      end
      vim.schedule(function()
        line_buf = line_buf .. data
        flush_lines(false)
      end)
    end,
  }, function(obj)
    vim.schedule(function()
      flush_lines(true)
      if obj.code ~= 0 then
        local err = (obj.stderr or obj.stdout or "agent failed"):gsub("\n$", "")
        if handlers.on_error then
          handlers.on_error(err)
        end
        return
      end
      if handlers.on_done then
        handlers.on_done(streamed)
      end
    end)
  end)
end

return M
