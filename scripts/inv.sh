#!/usr/bin/env bash

banners=(kanto johto hoenn)
cookie=''

count=${1:-100}
floor=${2:-4000000000}
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

fetch_gold() {
  curl -s 'https://api.poke-idle.fr/api/game/farm-sync' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -b "$cookie" \
    -H 'Origin: https://poke-idle.fr' \
    -H 'Referer: https://poke-idle.fr/' \
    --data-raw '{"amount":0,"xp":7913692,"level":256,"currentGeneration":9,"currentZone":13,"currentStage":10,"stageKills":0,"teamDpsBonus":0,"badges":117,"totalKills":52865,"combatGeneration":9,"combatZone":13,"adminVersion":149,"snapshotDps":31728,"snapshotZoneDps":1123,"snapshotGoldRate":935852,"snapshotEnemyMaxHp":33705,"snapshotGoldReward":994166,"sessionToken":"549a8bd99f5e927600e47ecf99967a7d5376b4623ceb38ef030aca353ce40ee0","serverBootId":"7f6d2430cafb7fec8d1f237808181e63da3d65f6"}' |
    jq -r '.gold // empty'
}

invoke() {
  local resp
  resp=$(curl -s 'https://api.poke-idle.fr/api/invocations' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -b "$cookie" \
    -H 'Origin: https://poke-idle.fr' \
    -H 'Referer: https://poke-idle.fr/' \
    --data-raw "{\"bannerId\":\"$1\",\"count\":100}")

  [[ -n "$VERBOSE" ]] && echo "RESP $1: $resp"

  if ! printf '%s' "$resp" | jq -e '.results' >/dev/null 2>&1; then
    echo "ERROR $1: $resp"
    return
  fi
  log_new_shinies "$resp" "$1"
}

if [[ -t 0 ]]; then
  read -rp "How many raffle per banner? [$count]: " ans
  [[ -n "$ans" ]] && count=$ans
fi

echo "Summoning $count per banner, stopping when gold < $floor"

for ((i = 1; i <= count; i++)); do
  if (( (i - 1) % 10 == 0 )); then
    gold=$(fetch_gold)
    if [[ -z "$gold" ]]; then
      echo "WARN: could not fetch gold, retrying"
    elif [[ "$gold" -lt "$floor" ]]; then
      echo "STOP: gold $gold < $floor"
      break
    else
      echo "gold: $gold"
    fi
  fi

  for b in "${banners[@]}"; do
    invoke "$b" &
  done
  wait
  sleep 1
done
