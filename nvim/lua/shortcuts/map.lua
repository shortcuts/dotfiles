--------------------------
-- Mapping
--------------------------

local M = require("shortcuts.bind")
local T = require("shortcuts.plugin.telescope")

-- Global
M.nmap("<Leader>jj", "<C-z>") -- vim foreground
M.nmap("<Leader>qq", ":quitall<CR>") -- quit all vim instances

-- toggle undotree
M.nmap("<Leader>u", ":UndotreeToggle<CR>") -- quit all vim instances

-- toggle Gitsigns
M.nnoremap("<Leader>lb", ":Gitsigns toggle_current_line_blame<CR>")

-- split size
M.nnoremap("<Leader>++", "<C-w>|")
M.nnoremap("<Leader>==", "<C-w>=")

-- Jumping centers screen
M.nnoremap("<C-d>", "4<C-d>zz")
M.nnoremap("<C-u>", "4<C-u>zz")
M.nnoremap("<C-i>", "<C-i>zz")
M.nnoremap("<C-o>", "<C-o>zz")
M.nnoremap("<S-[>", "<S-[>zz")
M.nnoremap("<S-]>", "<S-]>zz")
M.nnoremap("n", "nzz")
M.nnoremap("N", "Nzz")

-- Telescope mappings
M.nnoremap("<C-p>", ":Telescope find_files<CR>") -- open find file
M.nnoremap("<Leader>fg", ":Telescope live_grep<CR>") -- open find in file
M.nnoremap("<Leader>fh", ":Telescope help_tags<CR>") -- open help
-- Telescope file browser
M.nnoremap("<C-b>", ":Telescope file_browser<CR>") -- toggle file_browser
-- Telescope x Delta git status previewer
M.nnoremap("<Leader>gs", function()
    T.my_git_status()
end)

-- Barbar
M.nnoremap("<C-j>", "<Cmd>BufferPrevious<CR>") -- navigate previous
M.nnoremap("<C-k>", "<Cmd>BufferNext<CR>") -- navigate next
M.nnoremap("<C-q>", "<Cmd>BufferClose<CR>") -- close

-- -- Folding
M.nnoremap("<C-f>", "za") -- toggle under cursor
M.nnoremap("<Leader>fa", "zM") -- fold all
M.nnoremap("<Leader>ufa", "zR") -- unfold all

-- Copy to clipboard
M.nnoremap("<Leader>yy", '"*y') -- in normal mode
M.vnoremap("<Leader>yy", '"*y') -- in visual mode
