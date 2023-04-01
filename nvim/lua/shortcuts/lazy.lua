--------------------------
-- Plugin management
--------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- my plugins
    { "shortcuts/no-neck-pain.nvim", dev = true },

    { "nvim-lua/plenary.nvim", lazy = true },
    "nvim-tree/nvim-web-devicons",

    -- Telescope
    "nvim-telescope/telescope.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-file-browser.nvim",
    {
        "sindrets/diffview.nvim",
        dependencies = "nvim-lua/plenary.nvim",
        opts = {
            show_help_hints = false,
        },
    },

    -- Tree management
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
    },
    "nvim-treesitter/nvim-treesitter-context",

    -- Go
    { "fatih/vim-go", build = ":GoUpdateBinaries" },

    -- lsps plugins
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "ray-x/lsp_signature.nvim",

    -- Auto closing pairs
    { "windwp/nvim-autopairs", lazy = true },

    -- Theme
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        lazy = false,
        config = function()
            require("nightfox").setup({
                -- compile = true,
                transparent = true,
                -- colors = { theme = { wave = { ui = { bg_gutter = "none" } } } },
            })
            vim.cmd("colorscheme carbonfox")
        end,
    },
    { "lewis6991/gitsigns.nvim", lazy = true },
    { "numToStr/Comment.nvim", lazy = true },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },
    },
    { "romgrk/barbar.nvim", dependencies = "nvim-tree/nvim-web-devicons", lazy = true },
}, {
    dev = { path = "~/Documents", fallback = true },
})
