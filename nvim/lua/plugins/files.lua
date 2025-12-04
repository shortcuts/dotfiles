return {
    {
        "stevearc/oil.nvim",
        opts = {
            keymaps = {
                ["<BS>"] = "actions.parent",
                ["<C-h>"] = false,
            },
            view_options = {
                show_hidden = true,
            },
        },
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
        lazy = false,
        keys = {
            { "<leader>fb", "<cmd>Oil<cr>" },
        },
    },
    {
        "nvim-lua/plenary.nvim",
    },
}
