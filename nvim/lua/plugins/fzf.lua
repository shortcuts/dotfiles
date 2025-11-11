return {
    {
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
        config = function()
            local fzflua = require("fzf-lua")
            vim.keymap.set("n", "<Leader>ff", function()
                fzflua.files()
            end, { silent = true, desc = "open file finder" })
            vim.keymap.set("n", "<Leader>fg", function()
                fzflua.live_grep()
            end, { silent = true, desc = "rg in the current nvim session" })
            vim.keymap.set("n", "<Leader>gs", function()
                fzflua.git_status()
            end, { silent = true })
            vim.keymap.set("n", "<Leader>fh", function()
                fzflua.helptags()
            end, { silent = true })
            vim.keymap.set("n", "<Leader>fr", function()
                fzflua.lsp_references()
            end, { silent = true })

            fzflua.setup({
                winopts = {
                header_prefix="mdr",
                    preview = {
                header_prefix="mdr",
                        layout = "vertical",
                        vertical = "down:70%",
                    },
                },
                keymap = {
                    builtin = {
                        true,
                        ["<C-d>"] = "preview-page-down",
                        ["<C-u>"] = "preview-page-up",
                    },
                },
            })
        end,
    },
}
