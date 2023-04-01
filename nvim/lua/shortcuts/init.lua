--------------------------
-- Global
--------------------------

require("shortcuts.set")
require("shortcuts.lazy")
require("shortcuts.plugin")
require("shortcuts.map")

vim.api.nvim_create_augroup("OnVimEnter", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = "OnVimEnter",
    pattern = "*",
    callback = function()
        vim.schedule(function()
            -- open telescope on VimEnter, inspired by https://github.com/nvim-telescope/telescope-file-browser.nvim/pull/111
            local bufname = vim.api.nvim_buf_get_name(0)
            local netrw_bufname
            if vim.fn.isdirectory(bufname) == 0 then
                netrw_bufname = vim.fn.expand("#:p:h")
                return
            end

            if netrw_bufname == bufname then
                netrw_bufname = nil
                return
            else
                netrw_bufname = bufname
            end

            require("telescope.builtin").find_files({ initial_mode = "normal" })
        end)
    end,
})
