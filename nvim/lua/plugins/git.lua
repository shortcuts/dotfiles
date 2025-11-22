return {
    {
        "hrsh7th/nvim-cmp",
        optional = true,
        dependencies = {
            { "petertriho/cmp-git", opts = {} },
        },
        ---@module 'cmp'
        ---@param opts cmp.ConfigSchema
        opts = function(_, opts)
            table.insert(opts.sources or {}, { name = "git" })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = true,
        keys = {
            { "<leader>glb", "<cmd>Gitsigns toggle_current_line_blame<CR>" },
            { "<leader>gb", "<cmd>Gitsigns blame<CR>" },
        },
    },
    {
        "linrongbin16/gitlinker.nvim",
        cmd = "GitLink",
        config = true,
        event = { "BufReadPre", "BufNewFile" },
        keys = {
            { "<leader>gc", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Yank git link" },
            { "<leader>go", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git link" },
        },
    },
}
