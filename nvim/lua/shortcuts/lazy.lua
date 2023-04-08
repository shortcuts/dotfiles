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

    -- deps
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",

    -- Telescope
    { "nvim-telescope/telescope.nvim" },
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-file-browser.nvim" },

    -- Trees and LSPs
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
    },
    { "williamboman/mason.nvim", cmd = { "Mason" } },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp", lazy = false },
    { "hrsh7th/cmp-buffer", lazy = false },
    { "hrsh7th/cmp-path", lazy = false },
    { "hrsh7th/cmp-cmdline", lazy = false },
    { "hrsh7th/nvim-cmp", lazy = false },
    { "L3MON4D3/LuaSnip", lazy = false },
    { "saadparwaiz1/cmp_luasnip", lazy = false },
    { "ray-x/lsp_signature.nvim" },

    -- Language specific
    { "fatih/vim-go", build = ":GoUpdateBinaries", ft = "go" },

    -- Nice to have
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        dependencies = "nvim-lua/plenary.nvim",
        opts = {
            show_help_hints = false,
        },
    },
    { "windwp/nvim-autopairs", event = "VeryLazy" },
    { "lewis6991/gitsigns.nvim", event = "VeryLazy"  },
    { "numToStr/Comment.nvim", event = "VeryLazy", keys = { "gc" }  },

    -- Theme
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        lazy = false,
        config = function()
            require("nightfox").setup({
                transparent = true,
            })
            vim.cmd("colorscheme carbonfox")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },
    },
    { "romgrk/barbar.nvim", dependencies = "nvim-tree/nvim-web-devicons" },
}, {
    dev = { path = "~/Documents", fallback = true },
    performance = {
        cache = {
            enabled = true,
        },
    },
    defaults = {
        lazy = true,
    },
})
