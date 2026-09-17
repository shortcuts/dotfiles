# Brew's vendor conf.d auto-activates mise in every fish process (~240ms).
# Disable it here (conf.d sorts before mise-activate.fish); config.fish puts
# the real tool paths on PATH once instead.
set -gx MISE_FISH_AUTO_ACTIVATE 0

# mise's installer prepends its shim dir to the universal fish_user_paths, so
# shims won PATH over the real paths below: 280ms per exec vs 28ms direct.
contains $HOME/.local/share/mise/shims $fish_user_paths
and set -U fish_user_paths (string match -v $HOME/.local/share/mise/shims $fish_user_paths)
