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

      local capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

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

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "gopls",
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
        automatic_enable = true,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP keymaps",
        callback = function(event)
          local opts = function(desc)
            return { buffer = event.buf, desc = desc }
          end

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover"))
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
          vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts("Go to type definition"))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("References"))
          vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts("Signature help"))
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
