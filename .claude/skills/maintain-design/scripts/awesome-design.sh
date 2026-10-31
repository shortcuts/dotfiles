#!/usr/bin/env bash
# List, summarise or fetch DESIGN.md files from VoltAgent/awesome-design-md.
# Why gh with a raw-URL fallback: gh is authenticated (no rate limit); curl works without it.
set -euo pipefail
repo="VoltAgent/awesome-design-md"
raw="https://raw.githubusercontent.com/$repo/main/design-md"

fetch() { # $1 = brand
  gh api "repos/$repo/contents/design-md/$1/DESIGN.md" --jq .content 2>/dev/null | base64 -d 2>/dev/null \
    || curl -fsSL "$raw/$1/DESIGN.md"
}

case "${1:-}" in
  list)
    gh api "repos/$repo/contents/design-md" --jq '.[].name' 2>/dev/null \
      || { echo "gh failed; open https://github.com/$repo/tree/main/design-md" >&2; exit 1; } ;;
  summary) # front matter only: name, description, colors, typography keys
    fetch "${2:?brand}" | awk '/^---$/{n++; next} n==1{print} n>=2{exit}' ;;
  fetch)
    fetch "${2:?brand}" ;;
  *)
    echo "usage: awesome-design.sh list | summary <brand> | fetch <brand>" >&2; exit 2 ;;
esac
