#!/usr/bin/env bash

banners=(kanto johto hoenn sinnoh kalos alola galar paldea)
cookie=''

count=${1:-100}
seen_file="$(dirname "$0")/.seen_shinies"
touch "$seen_file"

# Response has no new/dupe flag, so track seen shiny speciesIds locally.
log_new_shinies() {
  local resp="$1" banner="$2" lock="$seen_file.lock"
  local ids
  ids=$(printf '%s' "$resp" | jq -r '(.results // [])[] | select(.isShiny) | "\(.speciesId) \(.nameEn)"')
  [[ -z "$ids" ]] && return

  while ! mkdir "$lock" 2>/dev/null; do sleep 0.05; done
  while IFS=' ' read -r id name; do
    if ! grep -qx "$id" "$seen_file"; then
      echo "$id" >>"$seen_file"
      echo "NEW SHINY: $name in $banner"
    fi
  done <<<"$ids"
  rmdir "$lock"
}

invoke() {
  local banner="$1" resp backoff=1 max_backoff=30

  while true; do
    resp=$(curl -s 'https://api.poke-idle.fr/api/invocations' \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -b "$cookie" \
      -H 'Origin: https://poke-idle.fr' \
      -H 'Referer: https://poke-idle.fr/' \
      --data-raw "{\"bannerId\":\"$banner\",\"count\":100}")

    [[ -n "$VERBOSE" ]] && echo "RESP $banner: $resp"

    if printf '%s' "$resp" | jq -e '.results' >/dev/null 2>&1; then
      log_new_shinies "$resp" "$banner"
      return
    fi

    local retry_after
    retry_after=$(printf '%s' "$resp" | jq -r '.retryAfter // empty' 2>/dev/null)
    if [[ -z "$retry_after" ]]; then
      echo "ERROR $banner: $resp"
      return
    fi

    echo "RATE LIMITED $banner: backing off ${backoff}s"
    sleep "$backoff"
    (( backoff = backoff * 2 > max_backoff ? max_backoff : backoff * 2 ))
  done
}

if [[ -t 0 ]]; then
  read -rp "How many raffle per banner? [$count]: " ans
  [[ -n "$ans" ]] && count=$ans
fi

echo "Summoning $count per banner"

for ((i = 1; i <= count; i++)); do
  for b in "${banners[@]}"; do
    invoke "$b"
    sleep 1
  done
done
