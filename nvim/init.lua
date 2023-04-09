--------------------------
-- Global
--------------------------

require("shortcuts.set")
require("shortcuts.map")

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

local opts = {
    install = {
        missing = true,
        notify = false,
        colorscheme = { "carbonfox" },
    },
    change_detection = {
        enabled = true,
        notify = false,
    },
    ui = {
        border = "rounded",
    },
    performance = {
        rtp = {
            reset = false,
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    defaults = { lazy = true },
    dev = {
        path = "~/Documents",
        fallback = true,
    },
}

require("lazy").setup("plugins", opts)
