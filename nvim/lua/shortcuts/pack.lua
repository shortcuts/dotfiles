--------------------------
-- Plugin management
--------------------------

local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({
			"git",
			"clone",
			"--depth",
			"1",
			"https://github.com/wbthomason/packer.nvim",
			install_path,
		})
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	-- personal
	use("shortcuts/no-neck-pain.nvim")

	-- why not
	use("lewis6991/impatient.nvim")
	use("ThePrimeagen/vim-be-good")

	-- Telescope dependencies
	use({
		"nvim-telescope/telescope-fzf-native.nvim",
		cmd = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	})
	use("nvim-lua/plenary.nvim")
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-file-browser.nvim")

	-- Tree management
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	use("nvim-treesitter/nvim-treesitter-context")

	-- Go plugin
	use({ "fatih/vim-go", run = ":GoUpdateBinaries" })

	-- Completion plugins
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")
	use("neovim/nvim-lspconfig")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-vsnip")
	use("hrsh7th/vim-vsnip")

	-- Auto closing pairs
	use("windwp/nvim-autopairs")

	-- Theme
	use("kyazdani42/nvim-web-devicons")
	use({ "catppuccin/nvim", as = "catppuccin" })
	use("lewis6991/gitsigns.nvim")
	use("numToStr/Comment.nvim")
	use("nvim-lualine/lualine.nvim")
	use("romgrk/barbar.nvim")

	if packer_bootstrap then
		require("packer").sync()
	end
end)
