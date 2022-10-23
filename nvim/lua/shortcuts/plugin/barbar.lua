require'bufferline'.setup({
  animation = false,
  auto_hide = false,
  tabpages = true,
  closable = false,
  clickable = false,
  -- Excludes buffers from the tabline
  exclude_ft = {},
  exclude_name = {},
  icons = true,
  icon_custom_colors = false,
  -- Configure icons on the bufferline.
  icon_separator_active = '▎',
  icon_separator_inactive = '▎',
  icon_close_tab_modified = '●',
  -- Sets the maximum padding width with which to surround each tab
  maximum_padding = 1,
  -- Sets the maximum buffer name length.
  maximum_length = 30,
  semantic_letters = true,
  letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP',
  no_name_title = nil,
})
