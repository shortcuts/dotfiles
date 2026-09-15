return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "mason.nvim",
            { "mason-org/mason-lspconfig.nvim", config = function() end },
            "hrsh7th/cmp-nvim-lsp",
            "j-hui/fidget.nvim",
        },
        opts = function(_, opts)
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities()
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
                    float = {
                        scope = "cursor",
                        focusable = false,
                        style = "minimal",
                        border = "rounded",
                        source = true,
                        header = "",
                        prefix = "",
                    },
                },
                inlay_hints = {
                    enabled = true,
                    exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
                },
                codelens = {
                    enabled = true,
                },
                servers = {
                    -- merged into every server by nvim itself
                    ["*"] = {
                        capabilities = capabilities,
                    },
                    bashls = {},
                    clangd = {},
                    cssls = {},
                    docker_compose_language_service = {},
                    dockerls = {},
                    fish_lsp = {},
                    html = {},
                    jsonls = {},
                    rust_analyzer = {},
                    sqlls = {},
                    terraformls = {},
                    vimls = {},
                    yamlls = {},
                    lua_ls = {
                        settings = {
                            Lua = {
                                workspace = { checkThirdParty = false },
                                runtime = { version = "LuaJIT" },
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
            -- specs imported before this file already merged into `opts`; keep their settings on top
            return vim.tbl_deep_extend("force", ret, opts or {})
        end,

        ---@param opts PluginLspOpts
        config = function(_, opts)
            require("fidget").setup({})
            require("mason-lspconfig").setup({ automatic_enable = false })

            vim.diagnostic.config(opts.diagnostics)

            local servers = opts.servers or {}
            if servers["*"] then
                vim.lsp.config("*", servers["*"])
            end
            local enabled = {}
            for name, cfg in pairs(servers) do
                if name ~= "*" and cfg.enabled ~= false then
                    cfg = vim.deepcopy(cfg)
                    cfg.enabled = nil
                    vim.lsp.config(name, cfg)
                    -- a declared-but-uninstalled server would only surface as an attach-time error
                    local cmd = (vim.lsp.config[name] or {}).cmd
                    if type(cmd) ~= "table" or vim.fn.executable(cmd[1]) == 1 then
                        enabled[#enabled + 1] = name
                    end
                end
            end
            vim.lsp.enable(enabled)

            -- FileType already fired for the buffer that triggered this load; replay it so it attaches
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
                    vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
                end
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp_features", {}),
                callback = function(e)
                    local client = vim.lsp.get_client_by_id(e.data.client_id)
                    if not client then
                        return
                    end
                    if
                        opts.inlay_hints.enabled
                        and client:supports_method("textDocument/inlayHint")
                        and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[e.buf].filetype)
                    then
                        vim.lsp.inlay_hint.enable(true, { bufnr = e.buf })
                    end
                    if
                        opts.codelens.enabled and client:supports_method("textDocument/codeLens")
                    then
                        vim.lsp.codelens.refresh({ bufnr = e.buf })
                        vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
                            buffer = e.buf,
                            callback = function()
                                vim.lsp.codelens.refresh({ bufnr = e.buf })
                            end,
                        })
                    end
                end,
            })
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            {
                "ray-x/lsp_signature.nvim",
                event = "InsertEnter",
                opts = {
                    bind = true,
                    hint_enable = false,
                },
            },
        },
        config = function()
            local cmp = require("cmp")
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
            -- registry refresh is a network call; only pay it on demand
            vim.api.nvim_create_user_command("MasonEnsureInstalled", function()
                local mr = require("mason-registry")
                mr.refresh(function()
                    for _, tool in ipairs(opts.ensure_installed) do
                        local p = mr.get_package(tool)
                        if not p:is_installed() then
                            p:install()
                        end
                    end
                end)
            end, { desc = "Install missing Mason tools" })
        end,
    },
}
