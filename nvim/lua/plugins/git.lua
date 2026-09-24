return {
    {
        "hrsh7th/nvim-cmp",
        optional = true,
        dependencies = {
            { "petertriho/cmp-git", opts = {} },
        },
        ---@module 'cmp'
        ---@param opts cmp.ConfigSchema
        opts = function(_, opts)
            table.insert(opts.sources or {}, { name = "git" })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = true,
        keys = {
            { "<Leader>gb", "<cmd>Gitsigns blame<CR>" },
        },
    },
    {
        "linrongbin16/gitlinker.nvim",
        cmd = "GitLink",
        config = true,
        keys = {
            { "<Leader>gc", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Yank git link" },
            { "<Leader>go", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git link" },
        },
    },
    {
        "dlyongemallo/diffview-plus.nvim",
        version = "*",
        init = function()
            vim.api.nvim_create_user_command("Git", function(o)
                local sub, rest = o.fargs[1], table.concat(vim.list_slice(o.fargs, 2), " ")
                if sub == "diff" then
                    vim.cmd("DiffviewOpen " .. rest)
                elseif sub == "show" then
                    -- `rev^!` limits diffview to the changes of that one commit, like `git show`.
                    vim.cmd("DiffviewOpen " .. (rest == "" and "HEAD" or rest) .. "^!")
                elseif sub == "log" then
                    local range = o.range > 0 and (o.line1 .. "," .. o.line2) or ""
                    vim.cmd(range .. "DiffviewFileHistory " .. rest)
                elseif sub == "stash" and rest == "" then
                    vim.cmd("DiffviewFileHistory -g --range=stash")
                else
                    vim.cmd("!git " .. o.args)
                end
            end, { nargs = "+", range = true })
            -- User commands must start uppercase, so expand a typed `:git` to `:Git`.
            for lhs, rhs in pairs({ git = "Git", gd = "Git diff", gsh = "Git show" }) do
                vim.cmd(
                    ("cnoreabbrev <expr> %s getcmdtype() == ':' && getcmdline() ==# '%s' ? '%s' : '%s'"):format(
                        lhs,
                        lhs,
                        rhs,
                        lhs
                    )
                )
            end
        end,
        opts = function()
            local cycle = {
                {
                    "n",
                    "<Leader>gx",
                    require("diffview.actions").cycle_layout,
                    { desc = "Cycle layouts" },
                },
            }
            return {
                view = {
                    cycle_layouts = {
                        default = { "diff2_horizontal", "diff1_plain", "diff1_inline" },
                    },
                },
                keymaps = { view = cycle, file_panel = cycle, file_history_panel = cycle },
            }
        end,
        keys = {
            {
                "<Leader>gq",
                "<cmd>DiffviewClose<cr>",
                mode = { "n", "v" },
                desc = "close git diff",
            },
        },
        cmd = {
            "DiffviewOpen",
            "DiffviewToggle",
            "DiffviewFileHistory",
            "DiffviewDiffFiles",
            "DiffviewLog",
        },
    },
}
