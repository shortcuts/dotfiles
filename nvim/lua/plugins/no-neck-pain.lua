return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        opts = {
            width = 75,
            minSideBufferWidth = 30,
            autocmds = {
                enableOnVimEnter = true,
                enableOnTabEnter = true,
                reloadOnColorSchemeChange = true,
            },
            mappings = {
                enabled = true,
                toggle = "<Leader>kz",
            },
            buffers = {
                left = {
                    bo = {
                        filetype = "md",
                    },
                    scratchPad = {
                        enabled = false,
                        fileName = "notes",
                        location = "~/",
                    },
                },
                right = {
                    enabled = false,
                },
            },
        },
    },
}
