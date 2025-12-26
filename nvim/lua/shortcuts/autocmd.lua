local augroup = vim.api.nvim_create_augroup("shortcuts", {})

vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(e)
        local opts = { buffer = e.buf, remap = false }
        vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
        end, opts)
        vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({
                focusable = false,
                style = "minimal",
                border = "rounded",
                max_width = 100,
            })
        end, opts)
        vim.keymap.set("n", "<leader>vws", function()
            vim.lsp.buf.workspace_symbol()
        end, opts)
        vim.keymap.set("n", "<leader>vd", function()
            vim.diagnostic.open_float()
        end, opts)
        vim.keymap.set("n", "<leader>vca", function()
            vim.lsp.buf.code_action()
        end, opts)
        vim.keymap.set("n", "<leader>vcl", function()
            vim.diagnostic.setqflist()
        end, opts)
        vim.keymap.set("n", "<leader>vr", function()
            vim.lsp.buf.references()
        end, opts)
        vim.keymap.set("i", "<C-h>", function()
            vim.lsp.buf.signature_help()
        end, opts)
        vim.keymap.set("n", "[d", function()
            vim.diagnostic.goto_next()
        end, opts)
        vim.keymap.set("n", "]d", function()
            vim.diagnostic.goto_prev()
        end, opts)
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "md", "mdx", "markdown" },
    callback = function()
        vim.opt.conceallevel = 2
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        for _, hl_group in pairs({
            "BufferCurrent",
            "BufferCurrentADDED",
            "BufferCurrentCHANGED",
            "BufferCurrentDELETED",
            "BufferCurrentERROR",
            "BufferCurrentHINT",
            "BufferCurrentINFO",
            "BufferCurrentIcon",
            "BufferCurrentIndex",
            "BufferCurrentMod",
            "BufferCurrentNumber",
            "BufferCurrentSign",
            "BufferCurrentSignRight",
            "BufferCurrentTarget",
            "BufferCurrentWARN",
            "BufferInactive",
            "BufferInactiveADDED",
            "BufferInactiveCHANGED",
            "BufferInactiveDELETED",
            "BufferInactiveERROR",
            "BufferInactiveHINT",
            "BufferInactiveINFO",
            "BufferInactiveIcon",
            "BufferInactiveIndex",
            "BufferInactiveMod",
            "BufferInactiveNumber",
            "BufferInactiveSign",
            "BufferInactiveSignRight",
            "BufferInactiveTarget",
            "BufferInactiveWARN",
            "BufferTabpageFill",
            "FzfLuaBorder",
            "NormalFloat",
            "StatusLine",
            "StatusLineNC",
            "TabLineFill",
            "TabLineSel",
            "Tabline",
            "TreesitterContext",
            "Winbar",
            "WinbarNC",
        }) do
            vim.api.nvim_set_hl(0, hl_group, { bg = "none" })
        end
    end,
    group = vim.api.nvim_create_augroup("foo", {}),
})
