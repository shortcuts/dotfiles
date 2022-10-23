function gvm
  if set -q GVM_DIR
    set GVM_SCRIPT "$GVM_DIR/scripts/gvm"
  else
    set GVM_SCRIPT "$HOME/.gvm/scripts/gvm"
  end

  if not test -e $GVM_SCRIPT
    echo "You need to install `gvm` (https://github.com/moovweb/gvm), run:"
    echo "bash (curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | psub)"
    return 1
  end

  if not functions -q bass
    echo "You need to install the `edc/bass` fish plugin (https://github.com/edc/bass) to run the GVM bash script"
    return 1
  end

  bass source $GVM_SCRIPT\; gvm $argv
end
