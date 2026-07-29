--- MDM scenario HCL (.hcl): treesitter highlights + mdm-dsl-check diagnostics

local M = {}

local NS_DIAG = vim.api.nvim_create_namespace("mdm-scenario")

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

function M.is_scenario_hcl(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name:match("/scenarios/.*%.hcl$") or name:match("/cases/.*%.hcl$") then
    return true
  end
  return vim.bo[bufnr].filetype == "hcl" and name ~= ""
end

function M.run_diagnostics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.is_scenario_hcl(bufnr) then
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
        source = "mdm-scenario",
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
            source = "mdm-scenario",
          },
        })
        return
      end

      local diags = {}
      for line in vim.gsplit(obj.stdout or "", "\n", { plain = true, trimempty = true }) do
        local _, lnum, col, msg = line:find(":(%d+):(%d+): error: (.+)$")
        if lnum then
          table.insert(diags, {
            lnum = tonumber(lnum) - 1,
            col = tonumber(col) - 1,
            end_col = tonumber(col),
            message = msg:gsub("^%s+", ""),
            severity = vim.diagnostic.severity.ERROR,
            source = "mdm-scenario",
          })
        end
      end

      vim.diagnostic.set(NS_DIAG, bufnr, diags)
    end)
  end)
end

function M.attach_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.is_scenario_hcl(bufnr) then
    return
  end

  vim.bo[bufnr].commentstring = "# %s"

  pcall(function()
    require("nvim-treesitter.configs").ensure_installed({ "hcl" })
  end)

  M.run_diagnostics(bufnr)
end

function M.setup()
  vim.filetype.add({
    extension = {
      hcl = "hcl",
    },
  })

  local group = vim.api.nvim_create_augroup("MdmScenarioHcl", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "hcl",
    callback = function(args)
      M.attach_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave" }, {
    group = group,
    pattern = "*.hcl",
    callback = function(args)
      vim.defer_fn(function()
        M.run_diagnostics(args.buf)
      end, 250)
    end,
  })

  vim.api.nvim_create_user_command("MdmScenarioCheck", function()
    M.run_diagnostics(0)
  end, { desc = "Run mdm-dsl-check on current scenario .hcl buffer" })
end

return M
