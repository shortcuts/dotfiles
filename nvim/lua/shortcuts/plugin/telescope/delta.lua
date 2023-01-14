local PREVIEWERS = require("telescope.previewers")
local BUILTIN = require("telescope.BUILTIN")

local T = {}

local delta = PREVIEWERS.new_termopen_previewer({
    title = "Git diff",
    get_command = function(entry)
        return { "git", "diff", entry.path }
    end,
})

T.gd = function(opts)
    opts = opts or {}
    opts.previewer = {
        delta,
        PREVIEWERS.git_commit_message.new(opts),
        PREVIEWERS.git_commit_diff_as_was.new(opts),
    }

    BUILTIN.git_status(opts)
end

return T
