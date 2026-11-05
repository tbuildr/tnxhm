#!/usr/bin/env bash
# Podman image disk usage, sorted by UNIQUE size (space freed if that image is removed).
# The total is deduplicated: shared layers are counted once, matching real disk use.
#
# Usage: podman-image-sizes.sh [-t]
#   -t   list tagged images only (hide <none> intermediates); totals still cover all images
set -euo pipefail

tagged_only=0
[[ "${1:-}" == "-t" ]] && tagged_only=1

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }

# Deduplicated size of all images, in bytes
dedup_total=$(podman system df --format json | jq -r '.[] | select(.Type == "Images") | .RawSize')

# Images section of the verbose report. Fields are parsed from the right:
# the last four are SIZE SHARED UNIQUE CONTAINERS (CREATED can contain spaces).
podman system df -v | awk '
function bytes(s,   n, u) {
  n = s; u = s
  sub(/[A-Za-z]+$/, "", n); sub(/^[0-9.]+/, "", u)
  if (u == "kB") return n * 1e3
  if (u == "MB") return n * 1e6
  if (u == "GB") return n * 1e9
  if (u == "TB") return n * 1e12
  return n
}
/^Images space usage:/   { in_images = 1; next }
in_images && /^REPOSITORY/ { header = 1; next }
in_images && header && NF == 0 { exit }
in_images && header {
  name = ($1 == "<none>") ? "<none>:<none>" : $1 ":" $2
  printf "%.0f\t%s\t%s\t%.0f\t%.0f\t%s\n", bytes($(NF-1)), name, $3, bytes($(NF-3)), bytes($(NF-2)), $NF
}' | sort -t $'\t' -k1,1nr | awk -F'\t' -v tagged_only="$tagged_only" -v dedup="$dedup_total" '
function human(b,   u, i) {
  split("B kB MB GB TB", u, " "); i = 1
  while (b >= 1000 && i < 5) { b /= 1000; i++ }
  return sprintf("%.1f %s", b, u[i])
}
BEGIN {
  fmt = "%-60s  %-12s  %10s  %10s  %10s  %4s\n"
  printf fmt, "IMAGE", "ID", "UNIQUE", "SHARED", "SIZE", "CTRS"
}
{
  uniq_total += $1; n++
  if ($2 == "<none>:<none>") n_none++
  if (tagged_only && $2 == "<none>:<none>") next
  printf fmt, $2, $3, human($1), human($5), human($4), $6
}
END {
  line = "--------------------------------------------------------------------------------------------------------------"
  print line
  printf "%-40s %s\n", "Images:", n " (" n_none " untagged)"
  printf "%-40s %s\n", "Unique to single images:", human(uniq_total)
  printf "%-40s %s\n", "Shared between images (counted once):", human(dedup - uniq_total)
  printf "%-40s %s\n", "TOTAL on disk:", human(dedup)
}'
