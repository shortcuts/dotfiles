--------------------------
-- Options
--------------------------

vim.g.mapleader = ";"

-- Plugin global opts
vim.g.go_gopls_gofumpt = 1
vim.g.go_imports_autosave = 0
vim.g.go_imports_mode = "goimports"
vim.g.go_fmt_command = "gopls"
vim.g.go_def_mode = "gopls"
vim.g.go_info_mode = "gopls"
vim.g.go_doc_popup_window = 1

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Global display settings
vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 4

-- Indent
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

-- Features
vim.opt.termguicolors = true
vim.opt.errorbells = false
vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 250

-- Don't pass messages to |ins-completion-menu|.
vim.opt.shortmess:append("c")

-- Completion
vim.opt.completeopt = "menu,menuone,noselect"

-- Split display
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Transparent support
vim.api.nvim_create_autocmd("ColorScheme", {
    once = true,
    callback = vim.schedule_wrap(function()
        vim.cmd([[
            hi FloatBorder guibg=none
            hi NormalFloat guibg=none

            " telescope
            hi TelescopeBorder guibg=none

            " tressitter
            hi TreesitterContext guibg=none
            hi TreesitterContextLineNumber guifg=orange

            " barbar - current buffer
            hi BufferCurrent guibg=none guifg=orange
            hi BufferCurrentADDED guibg=none
            hi BufferCurrentCHANGED guibg=none
            hi BufferCurrentDELETED guibg=none
            hi BufferCurrentERROR guibg=none
            hi BufferCurrentHINT guibg=none
            hi BufferCurrentIcon guibg=none
            hi BufferCurrentIndex guibg=none
            hi BufferCurrentINFO guibg=none
            hi BufferCurrentMod guibg=none
            hi BufferCurrentNumber guibg=none
            hi BufferCurrentSign guibg=none
            hi BufferCurrentSignRight guibg=none
            hi BufferCurrentTarget guibg=none
            hi BufferCurrentWARN guibg=none

            " barbar - inactive buffer
            hi BufferInactive guibg=none
            hi BufferInactiveADDED guibg=none
            hi BufferInactiveCHANGED guibg=none
            hi BufferInactiveDELETED guibg=none
            hi BufferInactiveERROR guibg=none
            hi BufferInactiveHINT guibg=none
            hi BufferInactiveIcon guibg=none
            hi BufferInactiveIndex guibg=none
            hi BufferInactiveINFO guibg=none
            hi BufferInactiveMod guibg=none
            hi BufferInactiveNumber guibg=none
            hi BufferInactiveSign guibg=none
            hi BufferInactiveSignRight guibg=none
            hi BufferInactiveTarget guibg=none
            hi BufferInactiveWARN guibg=none

            " barbar - tabline
            hi BufferTabpageFill ctermbg=black
        ]])
    end),
    group = vim.api.nvim_create_augroup("customcolorscheme", {}),
})
