#!/bin/sh
# Claude Code feeds session JSON on stdin. rate_limits is absent for enterprise accounts and before the first API reply, so those segments are skipped.
# Context tokens come from current_usage: used_percentage is a rounded integer and moves in coarse steps.
jq -r '
  def pct: if . == null then "-" else "\(. * 10 | round / 10 | tostring | if test("\\.") then . else . + ".0" end)%" end;
  def left: if . == null then "-" else
    (. - now | floor | if . < 0 then 0 else . end) as $s
    | if $s >= 86400 then "\($s / 86400 | floor)d\($s % 86400 / 3600 | floor)h"
      elif $s >= 3600 then "\($s / 3600 | floor)h\($s % 3600 / 60 | floor)m"
      else "\($s / 60 | floor)m" end end;
  [ (.context_window | (.current_usage // {}) as $u
      | ($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0) as $t
      | if $t == 0 then "ctx: -" else "ctx: \($t / 1000 | round)k" end),
    (.rate_limits.five_hour | select(. != null) | "5h: \(.used_percentage | pct) Reset: \(.resets_at | left)"),
    (.rate_limits.seven_day | select(. != null) | "Weekly: \(.used_percentage | pct) Weekly Reset: \(.resets_at | left)")
  ] | join(" | ")'
