return {
    --     {
    --   "folke/trouble.nvim",
    --   branch = "dev", -- IMPORTANT!
    --   lazy = false,
    --   keys = {
    --     {
    --       "<leader>xx",
    --       "<cmd>Trouble diagnostics toggle<cr>",
    --       desc = "Diagnostics (Trouble)",
    --     },
    --     {
    --       "<leader>xX",
    --       "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
    --       desc = "Buffer Diagnostics (Trouble)",
    --     },
    --     {
    --       "<leader>cs",
    --       "<cmd>Trouble symbols toggle focus=false<cr>",
    --       desc = "Symbols (Trouble)",
    --     },
    --     {
    --       "<leader>cl",
    --       "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
    --       desc = "LSP Definitions / references / ... (Trouble)",
    --     },
    --     {
    --       "<leader>xL",
    --       "<cmd>Trouble loclist toggle<cr>",
    --       desc = "Location List (Trouble)",
    --     },
    --     {
    --       "<leader>xQ",
    --       "<cmd>Trouble qflist toggle<cr>",
    --       desc = "Quickfix List (Trouble)",
    --     },
    --   },
    --   opts = {},
    -- },
    --     {
    --   "hedyhli/outline.nvim",
    --   lazy = false,
    --   config = function()
    --     -- Example mapping to toggle outline
    --     vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>",
    --       { desc = "Toggle Outline" })
    --
    --     require("outline").setup {
    --       -- Your setup opts here (leave empty to use defaults)
    --     }
    --   end,
    -- },
    -- {
    --     "nvim-neo-tree/neo-tree.nvim",
    --     lazy = false,
    --     branch = "v3.x",
    --     dependencies = {
    --         "nvim-lua/plenary.nvim",
    --         "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    --         "MunifTanjim/nui.nvim",
    --         -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    --     },
    --     config = true,
    --     opts = {
    --         close_if_last_window = true
    --     }
    -- },
    -- {
    --     "rcarriga/nvim-dap-ui",
    --     lazy = false,
    --     dependencies = {
    --         "nvim-neotest/nvim-nio",
    --         "mfussenegger/nvim-dap"
    --     },
    --     config = true,
    -- },
    -- {
    --     "nvim-neotest/neotest",
    --     lazy = false,
    --     dependencies = {
    --         "nvim-neotest/nvim-nio",
    --         "nvim-lua/plenary.nvim",
    --         "antoinemadec/FixCursorHold.nvim",
    --     },
    --     config = true,
    --     opts = {
    --         floating = { max_width = 0.1 },
    --         strategies = { integrated = { width = 1 } },
    --     },
    -- },
    -- {
    --     'goolord/alpha-nvim',
    --     lazy = false,
    --     dependencies = { 'nvim-tree/nvim-web-devicons' },
    --     config = function ()
    --         require'alpha'.setup(require'alpha.themes.startify'.config)
    --     end
    -- },
    -- {
    --     "nvim-tree/nvim-tree.lua",
    --     lazy = false,
    --     dependencies = "mfussenegger/nvim-dap",
    --     config = true,
    -- },
    -- {
    --     "emmanueltouzery/agitator.nvim",
    --     lazy = false,
    -- },
    -- {
    --     "nvim-treesitter/playground",
    --     lazy = false,
    --     config = function ()
    --        require("nvim-treesitter.configs").setup({playground={enable=true}})
    --     end
    -- },
    -- {
    --     "mbbill/undotree",
    --     lazy = false,
    -- config = function ()
    --        require("mbbill/undotree").setup()
    -- end,
    -- },
    --     {
    --   "olimorris/persisted.nvim",
    --   opts = {
    --     autoload = true,
    --   },
    -- },
    -- {
    --     "b0o/incline.nvim",
    --     dependencies = {
    --         "nvim-tree/nvim-web-devicons",
    --     },
    --     config = function()
    --         local helpers = require("incline.helpers")
    --         local devicons = require("nvim-web-devicons")
    --         require("incline").setup({
    --             window = {
    --                 padding = 0,
    --                 margin = { horizontal = 0 },
    --             },
    --             render = function(props)
    --                 local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
    --                 if filename == "" then
    --                     filename = "[No Name]"
    --                 end
    --                 local ft_icon, ft_color = devicons.get_icon_color(filename)
    --                 local modified = vim.bo[props.buf].modified
    --                 return {
    --                     ft_icon and {
    --                         " ",
    --                         ft_icon,
    --                         " ",
    --                         guibg = ft_color,
    --                         guifg = helpers.contrast_color(ft_color),
    --                     } or "",
    --                     " ",
    --                     { filename, gui = modified and "bold,italic" or "bold" },
    --                     " ",
    --                     guibg = "#44406e",
    --                 }
    --             end,
    --         })
    --     end,
    --     event = "VeryLazy",
    -- },
    -- {
    --     "stevearc/aerial.nvim",
    --     -- Optional dependencies
    --     dependencies = {
    --         "nvim-treesitter/nvim-treesitter",
    --         "nvim-tree/nvim-web-devicons",
    --     },
    --     lazy = false,
    --     config = function()
    --         require("aerial").setup({
    --             -- optionally use on_attach to set keymaps when aerial has attached to a buffer
    --             on_attach = function(bufnr)
    --                 -- Jump forwards/backwards with '{' and '}'
    --                 vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    --                 vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    --             end,
    --         })
    --         -- You probably also want to set a keymap to toggle aerial
    --         vim.keymap.set("n", "<leader>ae", "<cmd>AerialToggle!<CR>")
    --     end,
    -- },
}
