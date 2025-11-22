return {
    {
        "nvimtools/none-ls.nvim",
        optional = true,
        opts = function(_, opts)
            local nls = require("null-ls")
            opts.sources = vim.list_extend(opts.sources or {}, {
                nls.builtins.diagnostics.cmake_lint,
            })
        end,
    },
    {
        "mason.nvim",
        opts = { ensure_installed = { "cmakelang", "cmakelint" } },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                neocmake = {},
            },
        },
    },
}
