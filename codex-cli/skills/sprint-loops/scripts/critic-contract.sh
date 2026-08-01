#!/usr/bin/env bash
# Parse the exact shared plan/test critic verdict contract.

critic_verdict() {
  local critique_file=$1
  [ -s "$critique_file" ] || return 1

  awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function record_verdict(value) {
      value=trim(value)
      if (value ~ /^`[^`]+`$/) {
        sub(/^`/, "", value)
        sub(/`$/, "", value)
      }
      if (verdict_seen || (value != "clean" && value != "proceed-with-caveats" && value != "block")) {
        invalid=1
      }
      verdict=value
      verdict_seen=1
    }
    {
      line=$0
      sub(/\r$/, "", line)

      if (line ~ /^[[:space:]]*(```|~~~)/) {
        in_fence=!in_fence
        next
      }
      if (in_fence) next

      if (awaiting_verdict && line ~ /[^[:space:]]/) {
        if (line ~ /^## /) invalid=1
        else record_verdict(line)
        awaiting_verdict=0
      }

      if (line ~ /^## ([0-9]+[.] *)?Concerns[[:space:]]*$/) {
        concerns_count++
      }
      if (line ~ /^## ([0-9]+[.] *)?Confidence:[[:space:]]*/) {
        confidence_count++
        value=line
        sub(/^## ([0-9]+[.] *)?Confidence:[[:space:]]*/, "", value)
        if (value !~ /[^[:space:]]/) invalid=1
        else record_verdict(value)
      } else if (line ~ /^## ([0-9]+[.] *)?Confidence[[:space:]]*$/) {
        confidence_count++
        awaiting_verdict=1
      }
    }
    END {
      if (in_fence || awaiting_verdict || concerns_count != 1 ||
          confidence_count != 1 || !verdict_seen || invalid) exit 1
      print verdict
    }
  ' "$critique_file"
}
