return {
    {
      'dmtrKovalenko/fff',
      build = function()
        -- downloads a prebuilt binary or falls back to cargo build
        require("fff.download").download_or_build_binary()
      end,
      opts = {
        debug = {
          enabled = true,
          show_scores = true,
        },
      },
      lazy = false, -- the plugin lazy-initialises itself
      keys = {
        { "ff", function() require('fff').find_files() end, desc = 'FFFind files' },
        { "fg", function() require('fff').live_grep() end, desc = 'LiFFFe grep' },
        { "fz",
          function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end,
          desc = 'Live fffuzy grep',
        },
        { "fw",
          function() require('fff').live_grep_under_cursor() end,
          mode = { 'n', 'x' },
          desc = 'Search current word / selection',
        },
      },
    }
}
