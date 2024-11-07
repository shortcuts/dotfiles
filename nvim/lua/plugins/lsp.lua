return {
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPre",
        opts = {
            max_lines = 2,
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        module = true,
        event = { "BufReadPost", "BufNewFile" },
        cmd = {
            "TSInstall",
            "TSInstallInfo",
            "TSUpdate",
            "TSBufEnable",
            "TSBufDisable",
            "TSEnable",
            "TSDisable",
            "TSModuleInfo",
        },
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                playground = { enable = true },
                ensure_installed = "all",
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
            })
        end,
    },
    {
        "VonHeikemen/lsp-zero.nvim",
        lazy = false,
        dependencies = {
            {
                "hrsh7th/nvim-cmp",
                event = "InsertEnter",
                dependencies = {
                    { "neovim/nvim-lspconfig" },
                    { "hrsh7th/cmp-nvim-lsp" },
                    { "hrsh7th/cmp-buffer" },
                    { "hrsh7th/cmp-path" },
                    { "hrsh7th/cmp-cmdline" },
                    {
                        "L3MON4D3/LuaSnip",
                        build = "make install_jsregexp",
                    },
                    { "saadparwaiz1/cmp_luasnip" },
                    {
                        "ray-x/lsp_signature.nvim",
                        opts = {
                            bind = true,
                            hint_enable = false,
                        },
                    },
                    { "williamboman/mason.nvim" },
                    { "williamboman/mason-lspconfig.nvim" },
                    { "saadparwaiz1/cmp_luasnip" },
                },
            },
        },
        config = function()
            ---------------------- lsp-zero
            local lsp = require("lsp-zero")

            lsp.preset("recommended")

            lsp.configure("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                    },
                },
            })
            lsp.configure("gopls", {
                cmd = { "gopls", "serve" },
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = true,
                        },
                        staticcheck = true,
                    },
                },
            })

            local diagnosticOpts = {
                focusable = false,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                border = "rounded",
                source = "always",
                prefix = " ",
                scope = "cursor",
            }

            lsp.on_attach(function(_, bufnr)
                local opts = { buffer = bufnr, remap = false }

                vim.keymap.set("n", "gd", function()
                    vim.lsp.buf.definition()
                end, opts)
                vim.keymap.set("n", "K", function()
                    vim.lsp.buf.hover()
                end, opts)
                vim.keymap.set("n", "<leader>vd", function()
                    vim.diagnostic.open_float(diagnosticOpts)
                end, opts)
                vim.keymap.set("n", "[d", function()
                    vim.diagnostic.goto_next(diagnosticOpts)
                end, opts)
                vim.keymap.set("n", "]d", function()
                    vim.diagnostic.goto_prev(diagnosticOpts)
                end, opts)
                vim.keymap.set("n", "<leader>vca", function()
                    vim.lsp.buf.code_action()
                end, opts)
                vim.keymap.set("n", "<leader>vcl", function()
                    vim.diagnostic.setqflist()
                end, opts)
                vim.keymap.set("n", "<leader>vr", function()
                    vim.lsp.buf.references()
                end, opts)
            end)

            lsp.setup()

            ---------------------- cmp
            local cmp = require("cmp")

            -- Use buffer source for `/`.
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = { { name = "buffer" } },
            })

            -- Use cmdline & path source for ':'.
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
            })

            cmp.setup({
                keyword_length = 2,
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = {
                    ["<C-p>"] = cmp.mapping.select_prev_item({
                        behavior = cmp.SelectBehavior.Select,
                    }),
                    ["<C-n>"] = cmp.mapping.select_next_item({
                        behavior = cmp.SelectBehavior.Select,
                    }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = nil,
                    ["<S-Tab>"] = nil,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                sources = {
                    { name = "path" },
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "luasnip" },
                },
            })

            require("mason").setup()
            require("mason-lspconfig").setup({
                handlers = {
                    lsp.default_setup,
                },
                ensure_installed = {
                    "bashls",
                    "cssls",
                    "docker_compose_language_service",
                    "dockerls",
                    "dotls",
                    "gopls",
                    "html",
                    "htmx",
                    "jsonls",
                    "lua_ls",
                    "pylsp",
                    "pyright",
                    "ruff",
                    "ruff_lsp",
                    "rust_analyzer",
                    "sqlls",
                    "terraformls",
                    "ts_ls",
                    "vimls",
                    "yamlls",
                },
            })
        end,
    },
}
