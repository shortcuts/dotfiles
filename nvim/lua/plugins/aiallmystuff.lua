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
                    accept = "<S-TAB>",
                    next = "<C-n>",
                    prev = "<C-p>",
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

    {
        "hrsh7th/nvim-cmp",
        optional = true,
        dependencies = {
            {
                "zbirenbaum/copilot-cmp",
                opts = {},
                config = function(_, opts)
                    local copilot_cmp = require("copilot_cmp")
                    copilot_cmp.setup(opts)
                    copilot_cmp._on_insert_enter({})
                end,
                specs = {
                    {
                        "hrsh7th/nvim-cmp",
                        optional = true,
                        ---@param opts cmp.ConfigSchema
                        opts = function(_, opts)
                            table.insert(opts.sources or {}, 1, {
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
        "NickvanDyke/opencode.nvim",
        dependencies = {
            -- Recommended for `ask()` and `select()`.
            -- Required for `snacks` provider.
            ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
            { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
        },
        lazy = false,
        config = function()
            ---@type opencode.Opts
            -- Required for `opts.events.reload`.
            vim.o.autoread = true

            -- Recommended/example keymaps.
            vim.keymap.set({ "n", "v" }, "<Leader>oc", function()
                require("opencode").select()
            end, { desc = "Execute opencode action…" })
            vim.keymap.set({ "n", "t" }, "<Leader>och", function()
                require("opencode").toggle()
            end, { desc = "Toggle opencode" })
        end,
    },
}
