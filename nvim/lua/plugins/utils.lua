return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {
            disable_filetype = { "TelescopePrompt" },
        },
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
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
    {
        "vuciv/golf",
        priority = 1000,
        lazy = false,
    },
}
