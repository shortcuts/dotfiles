# Brew's vendor conf.d auto-activates mise in every fish process (~240ms).
# Disable it here (conf.d sorts before mise-activate.fish); config.fish
# activates mise for interactive shells only, scripts use shims.
set -gx MISE_FISH_AUTO_ACTIVATE 0
