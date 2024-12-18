return {
    {
        {
            'VonHeikemen/lsp-zero.nvim',
            branch = 'v4.x',
            lazy = true,
            config = function()
                local lsp_zero = require('lsp-zero')

                -- don't add this function in the `LspAttach` event.
                -- `format_on_save` should run only once.
                lsp_zero.format_on_save({
                    format_opts = {
                        async = false,
                        timeout_ms = 10000,
                    },
                    servers = {
                        ['biome'] = { 'javascript', 'typescript', 'js', 'ts', 'jsx', 'tsx' },
                        ['gopls'] = { 'go' },
                    }
                })
            end,
        },
        {
            'williamboman/mason.nvim',
            lazy = false,
            opts = {},
        },

        -- Autocompletion
        {
            'hrsh7th/nvim-cmp',
            event = 'InsertEnter',
            config = function()
                local cmp = require('cmp')

                cmp.setup({
                    sources = {
                        { name = 'nvim_lsp' },
                    },
                    mapping = cmp.mapping.preset.insert({
                        ['<C-Space>'] = cmp.mapping.complete(),
                        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                        ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    }),
                    snippet = {
                        expand = function(args)
                            vim.snippet.expand(args.body)
                        end,
                    },
                })
            end
        },

        -- LSP
        {
            'neovim/nvim-lspconfig',
            cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
            event = { 'BufReadPre', 'BufNewFile' },
            dependencies = {
                { 'hrsh7th/cmp-nvim-lsp' },
                { 'williamboman/mason.nvim' },
                { 'williamboman/mason-lspconfig.nvim' },
            },
            init = function()
                -- Reserve a space in the gutter
                -- This will avoid an annoying layout shift in the screen
                vim.opt.signcolumn = 'yes'
            end,
            config = function()
                local lsp_defaults = require('lspconfig').util.default_config

                -- Add cmp_nvim_lsp capabilities settings to lspconfig
                -- This should be executed before you configure any language server
                lsp_defaults.capabilities = vim.tbl_deep_extend(
                    'force',
                    lsp_defaults.capabilities,
                    require('cmp_nvim_lsp').default_capabilities()
                )

                -- LspAttach is where you enable features that only work
                -- if there is a language server active in the file
                vim.api.nvim_create_autocmd('LspAttach', {
                    desc = 'LSP actions',
                    callback = function(event)
                        local opts = { buffer = event.buf }

                        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
                        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
                        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
                        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
                        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
                        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
                        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
                        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
                        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
                        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
                    end,
                })

                require('mason-lspconfig').setup({
                    ensure_installed = { "gopls", 'biome', 'helm_ls', 'templ', 'html' },
                    handlers = {
                        -- this first function is the "default handler"
                        -- it applies to every language server without a "custom handler"
                        function(server_name)
                            require('lspconfig')[server_name].setup({})
                        end,
                        ['html'] = function()
                            require('lspconfig').html.setup({
                                filetypes = { 'html', 'templ' },
                            })
                        end,
                        ['biome'] = function()
                            require('lspconfig').biome.setup({
                                filetypes = { 'javascript', 'typescript', 'jsx', 'tsx', 'js', 'ts' },
                                root_dir = require('lspconfig').util.root_pattern('.git', 'package.json'),
                                on_attach = function(client, bufnr)
                                    -- Force-enable formatting capability
                                    client.server_capabilities.documentFormattingProvider = true

                                    -- Create a manual Format command
                                    vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
                                        vim.lsp.buf.format({ async = true })
                                    end, { desc = "Format using Biome" })

                                    -- Optionally set up formatting on save
                                    vim.api.nvim_create_autocmd('BufWritePre', {
                                        buffer = bufnr,
                                        callback = function()
                                            vim.lsp.buf.format({ async = false })
                                        end,
                                    })
                                end,
                            })
                        end
                    }
                })
            end
        }
    }
}
