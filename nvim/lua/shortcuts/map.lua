--------------------------
-- Mapping
--------------------------

-- Global
vim.keymap.set("n", "<Leader>jj", "<C-z>") -- vim foreground
vim.keymap.set("n", "<Leader>qq", "<cmd>quitall<CR>") -- quit all vim instances
vim.keymap.set("n", "<Leader>cf", "<cmd>let @+=expand('%:p')<CR>") -- copy current file path to cb
vim.keymap.set("n", "<Leader>cd", "<cmd>let @+=getcwd()<CR>") -- copy current directory path to cb

-- toggle Gitsigns
vim.keymap.set("n", "<Leader>lb", "<cmd>Gitsigns toggle_current_line_blame<CR>")

-- split size
vim.keymap.set("n", "<Leader>++", "<C-w>|")
vim.keymap.set("n", "<Leader>==", "<C-w>=")

-- navigation
vim.keymap.set("n", "gb", "<C-^>")

-- Jumping centers screen
vim.keymap.set("n", "<C-d>", "4<C-d>zz")
vim.keymap.set("n", "<C-u>", "4<C-u>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")

-- Diffview
vim.keymap.set("n", "<Leader>gd", "<cmd>DiffviewOpen<CR>")
vim.keymap.set("n", "<Leader>gq", "<cmd>DiffviewClose<CR>")
vim.keymap.set("n", "<Leader>gf", "<cmd>DiffviewFileHistory<CR>")

-- Barbar
vim.keymap.set("n", "<C-j>", "<Cmd>BufferPrevious<CR>") -- navigate previous
vim.keymap.set("n", "<C-k>", "<Cmd>BufferNext<CR>") -- navigate next
vim.keymap.set("n", "<C-q>", "<Cmd>BufferClose<CR>") -- close

-- Folding
vim.keymap.set("n", "<C-f>", "za") -- toggle under cursor
vim.keymap.set("n", "<Leader>fa", "zM") -- fold all
vim.keymap.set("n", "<Leader>ufa", "zR") -- unfold all

-- Copy to clipboard
vim.keymap.set("n", "<Leader>yy", '"*y') -- in normal mode
vim.keymap.set("v", "<Leader>yy", '"*y') -- in visual mode
