--------------------------
-- Mapping
--------------------------

local M = require('shortcuts.bind')

-- Global
M.nmap("<Leader>jj", "<C-z>") -- vim foreground
M.nmap("<Leader>qq", ":quitall<CR>") -- quit all vim instances

-- start zen mode
M.nnoremap("<Leader>kz", ":NoNeckPain<CR>")

-- split size
M.nnoremap("<Leader>++", "<C-w>|")
M.nnoremap("<Leader>==", "<C-w>=")

-- Jumping centers screen
M.nnoremap("<C-d>", "<C-d>zz")
M.nnoremap("<C-u>", "<C-u>zz")
M.nnoremap("n", "nzz")
M.nnoremap("N", "Nzz")

-- Telescope mappings
M.nnoremap("<C-p>", ":Telescope find_files<CR>") -- open find file
M.nnoremap("<Leader>fg", ":Telescope live_grep<CR>") -- open find in file
M.nnoremap("<Leader>fh", ":Telescope help_tags<CR>") -- open help

-- NvimTree
M.nnoremap("<C-b>", ":NvimTreeToggle<CR>") -- toggle tree

-- Barbar
M.nnoremap('<C-j>', '<Cmd>BufferPrevious<CR>') -- navigate previous
M.nnoremap('<C-k>', '<Cmd>BufferNext<CR>') -- navigate next
M.nnoremap('<C-q>', '<Cmd>BufferClose<CR>') -- close

-- Folding
M.nnoremap('<C-f>', 'za') -- toggle under cursor
M.nnoremap('<Leader>fa', 'zM') -- fold all
M.nnoremap('<Leader>ufa', 'zR') -- unfold all

-- Copy to clipboard
M.nnoremap('<Leader>yy', '"*y') -- in normal mode
M.vnoremap('<Leader>yy', '"*y') -- in visual mode
