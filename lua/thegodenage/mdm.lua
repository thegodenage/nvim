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
  if vim.fn.filereadable(lib) == 1 then
    return lib
  end

  local build_sh = grammar_dir .. "/build.sh"
  if vim.fn.filereadable(build_sh) ~= 1 then
    return nil
  end

  vim.notify("mdm: building tree-sitter parser…", vim.log.levels.INFO)
  local out = vim.fn.system({ "bash", build_sh })
  if vim.v.shell_error ~= 0 then
    vim.notify("mdm: build failed:\n" .. out, vim.log.levels.ERROR)
    return nil
  end

  if vim.fn.filereadable(lib) == 1 then
    return lib
  end

  return nil
end

function M.install_parser(bufnr)
  if PARSER_REGISTERED then
    return true
  end

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

  vim.treesitter.language.register("mdm", "mdm")
  PARSER_REGISTERED = true
  return true
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
    ["@comment.mdm"] = { link = "Comment", default = true },
    ["@string.mdm"] = { link = "String", default = true },
    ["@string.special.mdm"] = { link = "Special", default = true },
    ["@number.mdm"] = { link = "Number", default = true },
    ["@boolean.mdm"] = { link = "Boolean", default = true },
    ["@variable.mdm"] = { link = "Identifier", default = true },
    ["@type.mdm"] = { link = "Type", default = true },
    ["@type.builtin.mdm"] = { link = "Type", default = true },
    ["@tag.mdm"] = { link = "Type", default = true },
    ["@keyword.mdm"] = { link = "Keyword", default = true },
    ["@label.mdm"] = { link = "Label", default = true },
    ["@constant.builtin.mdm"] = { link = "Constant", default = true },
    ["@function.mdm"] = { link = "Function", default = true },
    ["@function.builtin.mdm"] = { link = "Function", default = true },
    ["@property.mdm"] = { link = "Identifier", default = true },
    ["@operator.mdm"] = { link = "Operator", default = true },
    ["@punctuation.bracket.mdm"] = { link = "Delimiter", default = true },
    ["@punctuation.delimiter.mdm"] = { link = "Delimiter", default = true },
    ["@markup.heading.mdm"] = { link = "Title", default = true },
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

function M.attach_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.install_parser(bufnr) then
    return
  end

  vim.bo[bufnr].commentstring = "# %s"
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

  local ok, err = pcall(vim.treesitter.start, bufnr, "mdm")
  if not ok then
    vim.notify("mdm: treesitter highlight failed: " .. tostring(err), vim.log.levels.ERROR)
  end
  M.run_diagnostics(bufnr)
end

function M.setup()
  M.setup_highlights()

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
      vim.notify("mdm: parser registered", vim.log.levels.INFO)
      M.attach_buffer(0)
    end
  end, { desc = "Build and register local mdm tree-sitter parser" })

  vim.api.nvim_create_user_command("MdmDslHighlight", function()
    if M.install_parser(0) then
      M.attach_buffer(0)
    end
  end, { desc = "Re-attach mdm treesitter highlighting" })
end

return M
