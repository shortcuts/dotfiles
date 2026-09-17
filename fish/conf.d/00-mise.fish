# Brew's vendor conf.d auto-activates mise in every fish process (~240ms).
# Disable it here (conf.d sorts before mise-activate.fish); config.fish puts
# the real tool paths on PATH once instead.
set -gx MISE_FISH_AUTO_ACTIVATE 0
