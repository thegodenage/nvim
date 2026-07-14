return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    build = ":MasonUpdate",
    opts = {},
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
        float = { border = "rounded", source = "if_many" },
        update_in_insert = false,
      })

      local blink_capabilities = require("blink.cmp").get_lsp_capabilities()
      local mason_rust_analyzer = vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer"

      vim.lsp.config("*", { capabilities = blink_capabilities })

      vim.lsp.config("biome", {
        filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "jsonc" },
        root_markers = { "biome.json", "biome.jsonc", "package.json", ".git" },
      })

      vim.lsp.config("html", {
        filetypes = { "html", "templ" },
      })

      vim.lsp.config("tailwindcss", {
        filetypes = { "html", "templ", "javascriptreact", "typescriptreact", "css" },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })

      vim.lsp.config("ruff", {
        init_options = {
          settings = {
            -- ruff LSP just diagnostics + code actions; formatting goes through conform
            lint = { enable = true },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        cmd = {
          vim.uv.fs_stat(mason_rust_analyzer) and mason_rust_analyzer or "rust-analyzer",
        },
        root_markers = { "Cargo.toml", "Cargo.lock", "rust-project.json", ".git" },
        filetypes = { "rust" },
        capabilities = vim.tbl_deep_extend("force", blink_capabilities, {
          experimental = {
            serverStatusNotification = true,
          },
        }),
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = true,
          },
        },
        handlers = {
          ["experimental/serverStatus"] = function(_, result)
            if type(result) ~= "table" then
              return
            end
            if result.health == "error" then
              vim.notify(
                "rust-analyzer failed to load the Cargo workspace. Run :LspCargoReload after fixing cargo errors.",
                vim.log.levels.ERROR
              )
            end
          end,
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "gopls",
          "rust_analyzer",
          "biome",
          "helm_ls",
          "templ",
          "html",
          "tailwindcss",
          "pyright",
          "ruff",
          "ruby_lsp",
          "marksman",
        },
        -- ruby_lsp is started manually below: for Dockerized projects it must
        -- run inside the container, not on the host.
        automatic_enable = { exclude = { "ruby_lsp" } },
      })

      -- ruby-lsp: run inside the `web` container when the project is
      -- Dockerized (host ruby/gems won't match). Relies on a compose mount
      -- that exposes the repo at its host path inside the container, so file
      -- URIs line up on both sides. Falls back to the host binary otherwise.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ruby",
        desc = "Start ruby-lsp (in-container for Docker projects)",
        callback = function(args)
          local root = vim.fs.root(args.buf, { "Gemfile", ".git" })
          if not root then return end

          local cmd
          if vim.uv.fs_stat(root .. "/docker-compose.yml") then
            cmd = { "docker", "compose", "exec", "-w", root, "-T", "web", "bundle", "exec", "ruby-lsp" }
          else
            local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/ruby-lsp"
            cmd = { vim.uv.fs_stat(mason_bin) and mason_bin or "ruby-lsp" }
          end

          vim.lsp.start({
            name = "ruby_lsp",
            cmd = cmd,
            cmd_cwd = root,
            root_dir = root,
            capabilities = blink_capabilities,
          })
        end,
      })

      -- gd/gi/go are native Vim commands ("local declaration", "last insert", etc.).
      -- Bind them globally so they always override builtins; otherwise which-key
      -- shows Vim's defaults whenever LSP hasn't attached yet.
      local function lsp_keymap(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, function()
          if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
            vim.notify("LSP not attached to this buffer", vim.log.levels.WARN)
            return
          end
          rhs()
        end, { desc = desc })
      end

      lsp_keymap("n", "gd", vim.lsp.buf.definition, "Go to definition")
      lsp_keymap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
      lsp_keymap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
      lsp_keymap("n", "go", vim.lsp.buf.type_definition, "Go to type definition")
      lsp_keymap("n", "gr", vim.lsp.buf.references, "References")
      lsp_keymap("n", "gs", vim.lsp.buf.signature_help, "Signature help")

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP buffer keymaps",
        callback = function(event)
          local opts = function(desc)
            return { buffer = event.buf, desc = desc }
          end

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover"))
          vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts("Rename symbol"))
          vim.keymap.set({ "n", "x" }, "<F3>", function()
            vim.lsp.buf.format({ async = true })
          end, opts("Format buffer (LSP)"))
          vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts("Code action"))
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts("Open diagnostic float"))
          vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts("Prev diagnostic"))
          vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts("Next diagnostic"))
        end,
      })
    end,
  },
}
