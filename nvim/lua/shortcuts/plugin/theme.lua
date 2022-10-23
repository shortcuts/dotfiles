-- theme
require("catppuccin").setup()

-- fancy status line
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 5000,
            tabline = 5000,
            winbar = 5000,
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {
            {
                'filename',
                path = 1
            }
        },
        lualine_x = {'fileformat', 'filetype'},
        lualine_y = {},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_x = {'location'},
    },
}

-- gitsigns in files
require('gitsigns').setup()

-- enable `gc` shortcuts for comments
require('Comment').setup()
