--- MDM deployment scenario DSL (.mdm): treesitter, highlights, diagnostics

local M = {}

local NS_DIAG = vim.api.nvim_create_namespace("mdm-dsl")
local PARSER_REGISTERED = false

local DEFAULT_GRAMMAR = vim.fn.expand("~/Projects/daemon-mdm-test/mdm-dsl/tree-sitter")

function M.resolve_grammar_dir(bufnr)
  if vim.env.MDM_TS_GRAMMAR and vim.env.MDM_TS_GRAMMAR ~= "" then
    return vim.fn.fnamemodify(vim.env.MDM_TS_GRAMMAR, ":p")
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr or 0)
  if bufname ~= "" then
    local found = vim.fs.find("mdm-dsl/tree-sitter/grammar.js", {
      upward = true,
      path = vim.fs.dirname(bufname),
    })
    if found[1] then
      return vim.fn.fnamemodify(vim.fs.dirname(found[1]), ":p")
    end
  end

  local cwd_found = vim.fs.find("mdm-dsl/tree-sitter/grammar.js", {
    upward = true,
    path = vim.loop.cwd(),
  })
  if cwd_found[1] then
    return vim.fn.fnamemodify(vim.fs.dirname(cwd_found[1]), ":p")
  end

  if vim.fn.isdirectory(DEFAULT_GRAMMAR) == 1 then
    return vim.fn.fnamemodify(DEFAULT_GRAMMAR, ":p")
  end

  return nil
end

function M.parser_lib_path(grammar_dir)
  if vim.fn.has("mac") == 1 then
    return grammar_dir .. "/parser.dylib"
  end
  if vim.fn.has("win32") == 1 then
    return grammar_dir .. "/parser.dll"
  end
  return grammar_dir .. "/parser.so"
end

function M.ensure_parser_built(grammar_dir)
  local lib = M.parser_lib_path(grammar_dir)
  local build_sh = grammar_dir .. "/build.sh"
  local grammar_js = grammar_dir .. "/grammar.js"
  local grammar_mtime = vim.fn.getftime(grammar_js)
  local lib_mtime = vim.fn.filereadable(lib) == 1 and vim.fn.getftime(lib) or 0

  if vim.fn.filereadable(lib) ~= 1 or lib_mtime < grammar_mtime then
    if vim.fn.filereadable(build_sh) ~= 1 then
      return nil
    end
    vim.notify("mdm: rebuilding tree-sitter parser…", vim.log.levels.INFO)
    local out = vim.fn.system({ "bash", build_sh })
    if vim.v.shell_error ~= 0 then
      vim.notify("mdm: build failed:\n" .. out, vim.log.levels.ERROR)
      return nil
    end
  elseif vim.fn.filereadable(lib) == 1 then
    return lib
  end

  if vim.fn.filereadable(lib) == 1 then
    return lib
  end

  return nil
end

function M.load_queries(grammar_dir)
  local queries_src = grammar_dir .. "/queries"
  if vim.fn.isdirectory(queries_src) ~= 1 then
    return false, "queries directory missing"
  end

  local names = { "highlights", "indents", "folds" }
  local loaded = 0
  local last_err = nil

  for _, name in ipairs(names) do
    local path = queries_src .. "/" .. name .. ".scm"
    if vim.fn.filereadable(path) == 1 then
      local text = table.concat(vim.fn.readfile(path), "\n")
      pcall(vim.treesitter.query.set, "mdm", name, nil)
      local ok, err = pcall(vim.treesitter.query.set, "mdm", name, text)
      if ok then
        loaded = loaded + 1
      else
        last_err = err
      end
    end
  end

  if loaded < 1 then
    return false, last_err or "failed to load highlights query"
  end
  return true
end

function M.install_queries(grammar_dir)
  local ok = M.load_queries(grammar_dir)
  if ok then
    return true
  end

  local queries_src = grammar_dir .. "/queries"
  if vim.fn.isdirectory(queries_src) ~= 1 then
    return false
  end

  local destinations = {
    vim.fn.stdpath("config") .. "/queries/mdm",
    vim.fn.stdpath("data") .. "/site/queries/mdm",
  }

  local linked = 0
  for _, queries_dst in ipairs(destinations) do
    vim.fn.mkdir(queries_dst, "p")
    for _, file in ipairs(vim.fn.glob(queries_src .. "/*.scm", false, true)) do
      local name = vim.fn.fnamemodify(file, ":t")
      local target = queries_dst .. "/" .. name
      if vim.fn.filereadable(target) == 1 or vim.fn.islink(target) == 1 then
        vim.fn.delete(target, "d")
      end
      local link_ok = pcall(vim.fn.symlink, file, target)
      if link_ok then
        linked = linked + 1
      end
    end
  end

  return linked > 0
end

function M.install_parser(bufnr)
  PARSER_REGISTERED = false

  local grammar_dir = M.resolve_grammar_dir(bufnr)
  if not grammar_dir then
    vim.notify(
      "mdm: grammar not found (set MDM_TS_GRAMMAR or open a file in daemon-mdm-test)",
      vim.log.levels.WARN
    )
    return false
  end

  local lib = M.ensure_parser_built(grammar_dir)
  if not lib then
    vim.notify(
      "mdm: parser library missing — run: cd mdm-dsl/tree-sitter && ./build.sh",
      vim.log.levels.ERROR
    )
    return false
  end

  local ok, err = vim.treesitter.language.add("mdm", { path = lib })
  if not ok then
    vim.notify("mdm: failed to register parser: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  local queries_ok, query_err = M.load_queries(grammar_dir)
  if not queries_ok then
    if not M.install_queries(grammar_dir) then
      vim.notify(
        "mdm: query files not installed — highlights may be missing"
          .. (query_err and (": " .. tostring(query_err)) or ""),
        vim.log.levels.WARN
      )
    end
  end

  vim.treesitter.language.register("mdm", "mdm")
  PARSER_REGISTERED = true
  return true
end

function M.resolve_fmt_cmd(bufnr)
  if vim.env.MDM_DSL_FMT and vim.env.MDM_DSL_FMT ~= "" then
    return vim.env.MDM_DSL_FMT
  end

  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local search_root = path ~= "" and vim.fs.dirname(path) or vim.loop.cwd()

  local found = vim.fs.find("target/debug/mdm-dsl-fmt", {
    upward = true,
    path = search_root,
  })
  if found[1] then
    return found[1]
  end

  local fallback = vim.fn.expand("~/Projects/daemon-mdm-test/target/debug/mdm-dsl-fmt")
  if vim.fn.executable(fallback) == 1 then
    return fallback
  end

  if vim.fn.executable("mdm-dsl-fmt") == 1 then
    return "mdm-dsl-fmt"
  end

  return nil
end

function M.setup_conform()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end

  conform.formatters.mdm_fmt = {
    command = function(ctx)
      return M.resolve_fmt_cmd(ctx.buf) or "mdm-dsl-fmt"
    end,
    stdin = false,
  }
end

function M.resolve_check_cmd(bufnr)
  if vim.env.MDM_DSL_CHECK and vim.env.MDM_DSL_CHECK ~= "" then
    return vim.env.MDM_DSL_CHECK
  end

  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local search_root = path ~= "" and vim.fs.dirname(path) or vim.loop.cwd()

  local found = vim.fs.find("target/debug/mdm-dsl-check", {
    upward = true,
    path = search_root,
  })
  if found[1] then
    return found[1]
  end

  local fallback = vim.fn.expand("~/Projects/daemon-mdm-test/target/debug/mdm-dsl-check")
  if vim.fn.executable(fallback) == 1 then
    return fallback
  end

  if vim.fn.executable("mdm-dsl-check") == 1 then
    return "mdm-dsl-check"
  end

  return nil
end

function M.setup_highlights()
  local hl = {
    ["@comment.mdm"] = { link = "Comment" },
    ["@string.mdm"] = { link = "String" },
    ["@string.special.mdm"] = { link = "Special" },
    ["@number.mdm"] = { link = "Number" },
    ["@boolean.mdm"] = { link = "Boolean" },
    ["@variable.mdm"] = { link = "Identifier" },
    ["@type.mdm"] = { link = "Type" },
    ["@type.builtin.mdm"] = { link = "Type" },
    ["@keyword.mdm"] = { link = "Keyword" },
    ["@label.mdm"] = { link = "Label" },
    ["@constant.builtin.mdm"] = { link = "Constant" },
    ["@function.mdm"] = { link = "Function" },
    ["@function.builtin.mdm"] = { link = "Function" },
    ["@property.mdm"] = { link = "@property" },
    ["@operator.mdm"] = { link = "Operator" },
    ["@punctuation.bracket.mdm"] = { link = "Delimiter" },
    ["@punctuation.delimiter.mdm"] = { link = "Delimiter" },
  }

  for name, spec in pairs(hl) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

function M.run_diagnostics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "mdm" then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.bo[bufnr].buftype ~= "" then
    return
  end

  local cmd = M.resolve_check_cmd(bufnr)
  if not cmd then
    vim.diagnostic.set(NS_DIAG, bufnr, {
      {
        lnum = 0,
        col = 0,
        message = "mdm-dsl-check not found — run: cargo build -p mdm-dsl",
        severity = vim.diagnostic.severity.WARN,
        source = "mdm-dsl",
      },
    })
    return
  end

  vim.system({ cmd, path }, { text = true }, function(obj)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      if obj.code ~= 0 and obj.code ~= 1 and obj.stderr and obj.stderr ~= "" then
        vim.diagnostic.set(NS_DIAG, bufnr, {
          {
            lnum = 0,
            col = 0,
            message = obj.stderr:gsub("\n$", ""),
            severity = vim.diagnostic.severity.ERROR,
            source = "mdm-dsl",
          },
        })
        return
      end

      local diags = {}
      for line in vim.gsplit(obj.stdout or "", "\n", { plain = true, trimempty = true }) do
        local _, lnum, col, msg = line:find(":(%d+):(%d+): error: (.+)$")
        if lnum then
          local clean = msg:gsub("^%s+", "")
          table.insert(diags, {
            lnum = tonumber(lnum) - 1,
            col = tonumber(col) - 1,
            end_col = tonumber(col),
            message = clean,
            severity = vim.diagnostic.severity.ERROR,
            source = "mdm-dsl",
          })
        end
      end

      vim.diagnostic.set(NS_DIAG, bufnr, diags)
    end)
  end)
end

function M.strip_import_path(text)
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text:sub(1, 1) == '"' and text:sub(-1) == '"' then
    return text:sub(2, -2)
  end
  return text
end

function M.resolve_import_target(bufnr, import_path)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return nil
  end
  local rel = M.strip_import_path(import_path)
  return vim.fn.fnamemodify(vim.fs.joinpath(vim.fs.dirname(bufname), rel), ":p")
end

function M.find_node_at_cursor(bufnr, query_str, capture_name)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "mdm")
  if not ok or not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil
  end
  local query = vim.treesitter.query.parse("mdm", query_str)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  for _, match, metadata in query:iter_matches(tree:root(), bufnr, 0, -1) do
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      if name == capture_name then
        for _, node in ipairs(nodes) do
          local start_row, start_col, end_row, end_col = node:range()
          if row >= start_row and row <= end_row and col >= start_col and col <= end_col then
            return node, metadata[id]
          end
        end
      end
    end
  end
  return nil
end

function M.goto_import_target(bufnr)
  local node = M.find_node_at_cursor(bufnr, '(import_case (import_path) @path)', "path")
  if not node then
    return false
  end
  local target = M.resolve_import_target(bufnr, vim.treesitter.get_node_text(node, bufnr))
  if not target or vim.fn.filereadable(target) ~= 1 then
    vim.notify("mdm: imported file not found: " .. (target or "?"), vim.log.levels.ERROR)
    return false
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target))
  vim.defer_fn(function()
    local new_buf = vim.api.nvim_get_current_buf()
    local case_node = M.find_node_at_cursor(new_buf, '(case_block) @case', "case")
    if case_node then
      local row = select(1, case_node:range())
      vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    end
  end, 50)
  return true
end

function M.goto_case_definition(bufnr)
  local node = M.find_node_at_cursor(bufnr, '(case_block (case_id) @id) @case', "id")
  if not node then
    return false
  end
  local row = select(1, node:range())
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
  return true
end

function M.setup_navigation(bufnr)
  local function goto_definition()
    if M.goto_import_target(bufnr) then
      return
    end
    if M.goto_case_definition(bufnr) then
      return
    end
    vim.notify("mdm: no definition found at cursor", vim.log.levels.INFO)
  end

  vim.keymap.set("n", "gd", goto_definition, { buffer = bufnr, desc = "Go to MDM definition" })
  vim.keymap.set("n", "gD", goto_definition, { buffer = bufnr, desc = "Go to MDM declaration" })
end

function M.attach_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.install_parser(bufnr) then
    return
  end

  vim.bo[bufnr].commentstring = "# %s"

  local ok, err = pcall(vim.treesitter.start, bufnr, "mdm")
  if not ok then
    vim.notify("mdm: treesitter highlight failed: " .. tostring(err), vim.log.levels.ERROR)
  else
    pcall(function()
      local parser = vim.treesitter.get_parser(bufnr, "mdm")
      if parser then
        parser:parse(true)
      end
    end)
  end
  M.setup_navigation(bufnr)
  M.run_diagnostics(bufnr)
end

function M.setup()
  M.setup_highlights()
  M.setup_conform()

  vim.filetype.add({
    extension = {
      mdm = "mdm",
    },
  })

  local group = vim.api.nvim_create_augroup("MdmDsl", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "mdm",
    callback = function(args)
      M.attach_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      M.setup_highlights()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave" }, {
    group = group,
    pattern = "*.mdm",
    callback = function(args)
      vim.defer_fn(function()
        M.run_diagnostics(args.buf)
      end, 250)
    end,
  })

  vim.api.nvim_create_user_command("MdmDslCheck", function()
    M.run_diagnostics(0)
  end, { desc = "Run mdm-dsl parser diagnostics on current buffer" })

  vim.api.nvim_create_user_command("MdmDslInstallParser", function()
    PARSER_REGISTERED = false
    if M.install_parser(0) then
      vim.notify("mdm: parser and queries registered", vim.log.levels.INFO)
      M.attach_buffer(0)
    end
  end, { desc = "Build and register local mdm tree-sitter parser + queries" })

  vim.api.nvim_create_user_command("MdmDslHighlight", function()
    if M.install_parser(0) then
      M.attach_buffer(0)
    end
  end, { desc = "Re-attach mdm treesitter highlighting" })
end

return M
