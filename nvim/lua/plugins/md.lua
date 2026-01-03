return {
    {
        "nvimtools/none-ls.nvim",
        optional = true,
        opts = function(_, opts)
            local nls = require("null-ls")
            opts.sources = vim.list_extend(opts.sources or {}, {
                nls.builtins.diagnostics.markdownlint_cli2,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                marksman = {},
            },
        },
    },
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*",
        ft = "markdown",
        opts = {
            legacy_commands = false,
            workspaces = {
                {
                    name = "notes",
                    path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes",
                },
            },
        },
    },
}
