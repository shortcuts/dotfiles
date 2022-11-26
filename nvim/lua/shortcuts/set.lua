--------------------------
-- Options
--------------------------

-- Plugin global opts
vim.g.catppuccin_flavour = "frappe" -- available latte, frappe, macchiato, mocha
vim.g.go_gopls_gofumpt = 1
vim.g.go_fmt_cmd = "gopls"
vim.g.go_def_mode = "gopls"
vim.g.go_info_mode = "gopls"

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Global display settings
vim.opt.guicursor = ""
vim.opt.colorcolumn = "90"

-- Give more space for displaying messages.
vim.opt.cmdheight = 1

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8

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

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50

-- Don't pass messages to |ins-completion-menu|.
vim.opt.shortmess:append("c")

-- Leader key
vim.g.mapleader = ";"

-- Completion
vim.opt.completeopt = "menu,menuone,noselect"

-- Split display
vim.opt.splitbelow = true
vim.opt.splitright = true
