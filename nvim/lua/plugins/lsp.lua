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
        event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        branch = "master",
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
        config = function()
            require("nvim-treesitter.configs").setup({
                -- A list of parser names, or "all"
                ensure_installed = "all",

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
                auto_install = true,

                ignore_install = { "ipkg" },

                indent = {
                    enable = true,
                },

                highlight = {
                    -- `false` will disable the whole extension
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "mason.nvim",
            { "mason-org/mason-lspconfig.nvim", config = function() end },
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            {
                "hrsh7th/nvim-cmp",
                event = "InsertEnter",
                dependencies = {
                    {
                        "ray-x/lsp_signature.nvim",
                        event = "InsertEnter",
                        opts = {
                            bind = true,
                            hint_enable = false,
                        },
                    },
                },
            },
            "hrsh7th/nvim-cmp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
        },
        opts = function()
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            ---@class PluginLspOpts
            local ret = {
                -- options for vim.diagnostic.config()
                ---@type vim.diagnostic.Opts
                diagnostics = {
                    underline = true,
                    update_in_insert = false,
                    virtual_text = {
                        spacing = 4,
                        source = "if_many",
                        prefix = "●",
                    },
                    severity_sort = true,
                },
                inlay_hints = {
                    enabled = true,
                    exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
                },
                codelens = {
                    enabled = true,
                },
                folds = {
                    enabled = false,
                },
                format = {
                    formatting_options = nil,
                    timeout_ms = nil,
                },
                servers = {
                    -- copilot.lua only works with its own copilot lsp server
                    copilot = { enabled = false },
                    -- configuration for all lsp servers
                    ["*"] = {
                        capabilities = capabilities,
                    },
                    stylua = { enabled = false },
                    lua_ls = {
                        settings = {
                            Lua = {
                                workspace = {
                                    checkThirdParty = false,
                                    library = vim.api.nvim_get_runtime_file("lua", true),
                                },
                                runtime = { version = "Lua 5.4" },
                                completion = {
                                    callSnippet = "Replace",
                                },
                                doc = {
                                    privateName = { "^_" },
                                },
                                diagnostics = {
                                    globals = {
                                        "bit",
                                        "vim",
                                        "it",
                                        "describe",
                                        "before_each",
                                        "after_each",
                                    },
                                },
                                hint = {
                                    enable = true,
                                    setType = false,
                                    paramType = true,
                                    paramName = "Disable",
                                    semicolon = "Disable",
                                    arrayIndex = "Disable",
                                },
                            },
                        },
                    },
                },
            }
            return ret
        end,

        config = function()
            local cmp = require("cmp")

            require("fidget").setup({})
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "bashls",
                    "clangd",
                    "cssls",
                    "docker_compose_language_service",
                    "dockerls",
                    "dotls",
                    "fish_lsp",
                    "gopls",
                    "html",
                    "htmx",
                    "jsonls",
                    "lua_ls",
                    "pylsp",
                    "pyright",
                    "ruff",
                    "rust_analyzer",
                    "sqlls",
                    "terraformls",
                    "ts_ls",
                    "vimls",
                    "yamlls",
                },
            })

            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            cmp.setup({
                keyword_length = 2,
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<Tab>"] = nil,
                    ["<S-Tab>"] = nil,
                }),
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                sources = cmp.config.sources({
                    { name = "path" },
                    { name = "nvim_lsp" },
                    { name = "luasnip" }, -- For luasnip users.
                }, {
                    { name = "buffer" },
                }),
            })

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

            vim.diagnostic.config({
                float = {
                    scope = "cursor",
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end,
    },
    {

        "mason-org/mason.nvim",
        cmd = "Mason",
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        build = ":MasonUpdate",
        opts_extend = { "ensure_installed" },
        opts = {
            ensure_installed = {
                "stylua",
                "shfmt",
            },
        },
        ---@param opts MasonSettings | {ensure_installed: string[]}
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            mr.refresh(function()
                for _, tool in ipairs(opts.ensure_installed) do
                    local p = mr.get_package(tool)
                    if not p:is_installed() then
                        p:install()
                    end
                end
            end)
        end,
    },
}
