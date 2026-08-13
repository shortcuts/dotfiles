#!/usr/bin/env bash

banners=(kanto johto hoenn sinnoh kalos alola galar paldea)
cookie='remember_web=e%3ANLaO_KcgCTY6J9OW6GF9iUPrIHCIRxgb-l9SkXI5RNQIrfyidApGcg91YQhjyqTqClcwQu2aodqarnllMendWP_oqEWRMJFanp93TFdWTQSLuPf5zDsYGpgdz7LacxSQWw9BO5vXkG9MDE6GgocE5A.MUpwWk1NMFRWejZqT3diVw.iDain2OK-5aBBPIGEf6XUSN1Zo1STUGAVNWspA9gCQI; adonis-session=s%3AeyJtZXNzYWdlIjoicmw1cmNlNmc3dDZxemxsam50czkxYW8xIiwicHVycG9zZSI6ImFkb25pcy1zZXNzaW9uIn0.VwSTS4bxsuoML16iweG8MSLWj1d-zvfjd-7Qel2ok8s; rl5rce6g7t6qzlljnts91ao1=e%3A7SphC7bFp2RX4L1TsJkVwoUwFkrQ7Oz8MT8FO2zz81wou0YeUZ8IqnmA6n5pnAN1tu1_oooYEk6o46MQEx9mToAlOeP8g0DKThJ3_tgA_Sbw-JNKYGoUvZ1RtMaxYaDqmAy_eBzyKDN3UdbFpWF_t3afY-BYOfcjroL0LKE8OKvoL47m0Ny0eEt_hentANTxGx2QAkkLJD49K2Wf2edBYg.ZUhOUUNUWHppSm9LVExqUg.v7eWh6UwNoJ0MeYCq4FWqk2n3iwPqQpJYOBIHkIqxmY'

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
