#!/usr/bin/env bash

banners=(kanto johto hoenn sinnoh unys kalos alola galar paldea)
cookie=''

count=${1:-100}
floor=${2:-4000000000}

fetch_gold() {
  curl -s 'https://api.poke-idle.fr/api/game/farm-sync' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -b "$cookie" \
    -H 'Origin: https://poke-idle.fr' \
    -H 'Referer: https://poke-idle.fr/' \
    --data-raw '{"amount":0,"xp":7913692,"level":256,"currentGeneration":9,"currentZone":13,"currentStage":10,"stageKills":0,"teamDpsBonus":0,"badges":117,"totalKills":52865,"combatGeneration":9,"combatZone":13,"adminVersion":130,"snapshotDps":31728,"snapshotZoneDps":1123,"snapshotGoldRate":935852,"snapshotEnemyMaxHp":33705,"snapshotGoldReward":994166,"sessionToken":"6ffb5a075c6b8a1c821d1517f55f965e72d9486a93354a76ae8e3d5ea69c502f","serverBootId":"ccc6051584c832dd1421f4a131abb8b488928e1f"}' |
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

  local shinies
  if ! shinies=$(printf '%s' "$resp" | jq -e -r '[(.results // [])[] | select(.isShiny)] | length' 2>/dev/null); then
    echo "ERROR $1: $resp"
    return
  fi
  if [[ "$shinies" -gt 0 ]]; then
    echo "SHINY x$shinies in $1"
  fi
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
