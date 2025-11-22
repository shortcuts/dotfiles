return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "BufReadPost",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                hide_during_completion = true,
                keymap = {
                    accept = false,
                    next = "<M-]>",
                    prev = "<M-[>",
                },
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                copilot = { enabled = false },
            },
        },
    },

    vim.g.ai_cmp
            and {
                -- copilot cmp source
                {
                    "hrsh7th/nvim-cmp",
                    optional = true,
                    dependencies = { -- this will only be evaluated if nvim-cmp is enabled
                        {
                            "zbirenbaum/copilot-cmp",
                            opts = {},
                            config = function(_, opts)
                                local copilot_cmp = require("copilot_cmp")
                                copilot_cmp.setup(opts)
                                -- attach cmp source whenever copilot attaches
                                -- fixes lazy-loading issues with the copilot cmp source
                                Snacks.util.lsp.on({ name = "copilot" }, function()
                                    copilot_cmp._on_insert_enter({})
                                end)
                            end,
                            specs = {
                                {
                                    "hrsh7th/nvim-cmp",
                                    optional = true,
                                    ---@param opts cmp.ConfigSchema
                                    opts = function(_, opts)
                                        table.insert(opts.sources, 1, {
                                            name = "copilot",
                                            group_index = 1,
                                            priority = 100,
                                        })
                                    end,
                                },
                            },
                        },
                    },
                },
                {
                    "saghen/blink.cmp",
                    optional = true,
                    dependencies = { "fang2hou/blink-copilot" },
                    opts = {
                        sources = {
                            default = { "copilot" },
                            providers = {
                                copilot = {
                                    name = "copilot",
                                    module = "blink-copilot",
                                    score_offset = 100,
                                    async = true,
                                },
                            },
                        },
                    },
                },
            }
        or nil,
}
