return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {
            disable_filetype = { "TelescopePrompt" },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = true,
    },
    {
        "numToStr/Comment.nvim",
        event = "BufReadPost",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = true,
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
}
