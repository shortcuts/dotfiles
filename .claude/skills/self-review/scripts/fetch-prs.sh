#!/usr/bin/env bash
# Usage: fetch-prs.sh <since YYYY-MM-DD> [until YYYY-MM-DD] [author]
# Prints one JSON array of merged PRs to stdout.
set -euo pipefail

since=${1:?usage: fetch-prs.sh <since YYYY-MM-DD> [until YYYY-MM-DD] [author]}
until=${2:-$(date +%F)}
author=${3:-$(gh api user --jq .login)}

# GitHub search returns at most 1000 results per query, so query one month at a
# time and let --paginate walk the pages inside each month.
cursor=$(date -j -f %Y-%m-%d "${since:0:7}-01" +%Y-%m-%d)
out=$(mktemp)
while [[ "$cursor" < "$until" ]]; do
  next=$(date -j -v+1m -f %Y-%m-%d "$cursor" +%Y-%m-%d)
  gh api --paginate -X GET search/issues \
    -f q="author:$author is:pr is:merged merged:$cursor..$next" \
    -f per_page=100 \
    --jq '.items[] | {repo: (.repository_url | sub(".*/repos/"; "")), number, title, url: .html_url, mergedAt: .pull_request.merged_at, labels: [.labels[].name]}' \
    >> "$out"
  cursor=$next
done

# Month windows share an endpoint date, so drop the duplicates.
jq -s "unique_by(.url) | map(select(.mergedAt >= \"$since\" and .mergedAt <= \"${until}T23:59:59Z\"))" "$out"
rm -f "$out"
