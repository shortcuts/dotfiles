---
name: radin-uninstall
description: |
  Remove everything install.sh copied into ~/.claude -- radin's skills
  and lib scripts. Use for /radin-uninstall or any request to remove radin
  from this machine.
---
# Uninstall

Removes every file `install.sh` copied into `~/.claude`, and only those.

```bash
radin uninstall
```

Print the full output to the user as-is. It already lists what was removed and
what was left untouched, with manual removal commands for the advisory
companion tools.
