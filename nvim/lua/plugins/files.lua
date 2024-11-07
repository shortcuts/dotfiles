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
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        lazy = false,
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()

            vim.keymap.set("n", "<leader>a", function()
                harpoon:list():add()
            end)
            vim.keymap.set("n", "<C-h>", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)
        end,
    },
}
