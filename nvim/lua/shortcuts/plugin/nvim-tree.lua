require("nvim-tree").setup({
    update_focused_file = {
        ignore_list = { "node_modules" },
    },
    view = {
        side = "left",
        mappings = {
            list = {
                { key = "<C-v>", action = false },
                { key = "<S-CR>", action = "vsplit" },
            },
        },
    },
    git = {
        enable = false,
        timeout = 1000,
    },
    filters = {
        dotfiles = false,
        custom = {
            "^.bin$",
            "^.git$",
        },
    },
    actions = {
        open_file = {
            quit_on_open = true,
        },
    },
})

require("nvim-tree").toggle(false, true)
