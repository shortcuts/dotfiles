#!/usr/bin/env bash
# Usage: fetch-prs.sh <since YYYY-MM-DD> [until YYYY-MM-DD] [author]
# Prints one JSON array of merged PRs to stdout. Caches each month under
# ${XDG_CACHE_HOME:-~/.cache}/self-review; delete that directory to force a refetch.
set -euo pipefail

since=${1:?usage: fetch-prs.sh <since YYYY-MM-DD> [until YYYY-MM-DD] [author]}
until=${2:-$(date +%F)}
author=${3:-$(gh api user --jq .login)}

cache="${XDG_CACHE_HOME:-$HOME/.cache}/self-review/$author"
mkdir -p "$cache"
this_month=$(date +%Y-%m)

# GitHub search returns at most 1000 results per query, so query one month at a
# time and let --paginate walk the pages inside each month.
cursor=$(date -j -f %Y-%m-%d "${since:0:7}-01" +%Y-%m-%d)
out=$(mktemp)
while [[ "$cursor" < "$until" ]]; do
  next=$(date -j -v+1m -f %Y-%m-%d "$cursor" +%Y-%m-%d)
  month=${cursor:0:7}
  file="$cache/$month.json"
  # A past month can no longer gain merged PRs, so its cache never expires.
  if [[ ! -s "$file" || "$month" == "$this_month" ]]; then
    gh api --paginate -X GET search/issues \
      -f q="author:$author is:pr is:merged merged:$cursor..$next" \
      -f per_page=100 \
      --jq '.items[] | {repo: (.repository_url | sub(".*/repos/"; "")), number, title, url: .html_url, mergedAt: .pull_request.merged_at, labels: [.labels[].name]}' \
      > "$file.part"
    mv "$file.part" "$file"
  fi
  cat "$file" >> "$out"
  cursor=$next
done

# Month windows share an endpoint date, so drop the duplicates.
jq -s "unique_by(.url) | map(select(.mergedAt >= \"$since\" and .mergedAt <= \"${until}T23:59:59Z\"))" "$out"
rm -f "$out"
