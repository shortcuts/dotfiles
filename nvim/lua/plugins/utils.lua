return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },
    {
        "numToStr/Comment.nvim",
        event = "BufReadPost",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = true,
    },
    {
        "fatih/vim-go",
        build = ":GoUpdateBinaries",
        ft = "go",
    },
}
