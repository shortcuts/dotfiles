return {
    {
        "tpope/vim-fugitive",
        lazy = false,
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        dependencies = "nvim-lua/plenary.nvim",
        opts = {
            show_help_hints = false,
            enhanced_diff_hl = true,
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = true,
        keys = {
            { "<leader>lb", "<cmd>Gitsigns toggle_current_line_blame<CR>" },
        },
    },
}
