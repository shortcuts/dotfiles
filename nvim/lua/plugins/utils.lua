return {
    {
        "windwp/nvim-autopairs",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        dependencies = "nvim-lua/plenary.nvim",
        opts = {
            show_help_hints = false,
        },
    },
    {
        "fatih/vim-go",
        build = ":GoUpdateBinaries",
        ft = "go",
    },
}
