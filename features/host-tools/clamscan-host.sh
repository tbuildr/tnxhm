#!/usr/bin/env bash
set -u

CACHE_DIR="$HOME/.cache/clamav-db"
mkdir -p "$CACHE_DIR"

# For full root-covering coverage, run the whole script under sudo instead
# of passing an arg — unlike the old podman version, native scanning has no
# privilege boundary between counting and scanning, so there's nothing to
# split: `sudo ./clamscan-host.sh` vs `./clamscan-host.sh`.

# Exit status: 0 = no infections found, 1 = infections found.
# Scan errors (permission denied etc.) are reported in the log but do not
# affect the exit status, since a non-root run always hits some.

# Set CLAMSCAN_DEBUG=1 to also get: a raw unfiltered log (every per-unit
# SCAN SUMMARY block, in full) and a per-checkpoint rate .tsv for plotting
# throughput over time. Off by default for a lean run.
DEBUG="${CLAMSCAN_DEBUG:-0}"

HOST_EXCLUDES=(
  "/proc" "/sys" "/dev" "/run" "/tmp"
  "/usr" "/etc"
  "/nix/store"
  "/ostree"
  "/sysroot/ostree"
  "/var/lib/containers"
  "/var/lib/flatpak"
  "/var/lib/nix/store"
  "$HOME/.local/share/containers/storage"
  "$HOME/.local/share/Steam"
  "$HOME/.cache/huggingface/hub"
  "$HOME/Projects/tkube/.state/llama-cache"
  "$HOME/.var/app/org.mozilla.firefox/cache"
)

is_excluded() {
  local target="$1" p
  for p in "${HOST_EXCLUDES[@]}"; do
    [ "$target" = "$p" ] && return 0
  done
  return 1
}

CLAMSCAN_EXCLUDES=()
for p in "${HOST_EXCLUDES[@]}"; do
  esc=$(printf '%s' "$p" | sed 's/[.[\*^$/]/\\&/g')
  CLAMSCAN_EXCLUDES+=(--exclude-dir="^${esc}$")
done
CLAMSCAN_EXCLUDES+=(
  --exclude-dir='.*/Cache$'
  --exclude-dir='.*/Code Cache$'
  --exclude-dir='.*/GPUCache$'
  --exclude-dir='.*/CacheStorage$'
  --exclude-dir='.*/Service Worker$'
)

# --- Build the parallel scan-unit list ---
SCAN_UNITS=()

while IFS= read -r -d '' entry; do
  base="$(basename "$entry")"
  [ "$base" = "home" ] && continue
  [ "$base" = "var" ] && continue
  is_excluded "$entry" && continue
  SCAN_UNITS+=("$entry")
done < <(find / -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

while IFS= read -r -d '' entry; do
  base="$(basename "$entry")"
  [ "$base" = "home" ] && continue
  is_excluded "$entry" && continue
  SCAN_UNITS+=("$entry")
done < <(find /var -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

while IFS= read -r -d '' entry; do
  is_excluded "$entry" && continue
  SCAN_UNITS+=("$entry")
done < <(find "$HOME" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

echo "Scan units (${#SCAN_UNITS[@]}):"
printf '  %s\n' "${SCAN_UNITS[@]}"
echo

echo "Counting files to scan (native, fast pass)..."
PRUNE_ARGS=()
for p in "${HOST_EXCLUDES[@]}"; do
  PRUNE_ARGS+=(-path "$p" -o)
done
PRUNE_ARGS+=(
  -name "Cache" -o
  -name "Code Cache" -o
  -name "GPUCache" -o
  -name "CacheStorage" -o
  -name "Service Worker" -o
)
PRUNE_EXPR=("${PRUNE_ARGS[@]::${#PRUNE_ARGS[@]}-1}")

TOTAL=0
for unit in "${SCAN_UNITS[@]}"; do
  n=$(find "$unit" \( "${PRUNE_EXPR[@]}" \) -prune -o -type f -print 2>/dev/null | wc -l)
  TOTAL=$((TOTAL + n))
done
echo "Files to scan: $TOTAL"

# --- freshclam, once, against a config we generate ourselves ---
FRESHCLAM_CONF_DIR="$(mktemp -d)"
FRESHCLAM_CONF="$FRESHCLAM_CONF_DIR/freshclam.conf"
{
  echo "DatabaseDirectory $CACHE_DIR"
  echo "DatabaseMirror database.clamav.net"
} >"$FRESHCLAM_CONF"
trap 'rm -rf "$FRESHCLAM_CONF_DIR"' EXIT

echo "Updating virus definitions..."
freshclam --config-file="$FRESHCLAM_CONF"

# --- Parallel scan ---
LOG_DIR="$HOME/.local/state/clamscan-logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/scan-$STAMP.log"
RAW_LOG_FILE="$LOG_DIR/scan-$STAMP-raw.log"
PROGRESS_LOG="$LOG_DIR/scan-$STAMP-progress.tsv"

echo "Log: $LOG_FILE"
if [ "$DEBUG" = "1" ]; then
  echo "Debug raw log: $RAW_LOG_FILE"
  echo "Debug progress/rate log: $PROGRESS_LOG"
  printf "elapsed_sec\tfiles_scanned\tpct\tinst_rate\tavg_rate\tactive_workers\n" >"$PROGRESS_LOG"
fi

JOBS="${CLAMSCAN_JOBS:-$(nproc)}"
echo "Starting scan across ${#SCAN_UNITS[@]} units with $JOBS parallel workers..."
echo

printf '%s\0' "${SCAN_UNITS[@]}" |
  xargs -0 -P "$JOBS" -I{} clamscan -r -i -v --database="$CACHE_DIR" "${CLAMSCAN_EXCLUDES[@]}" {} 2>&1 |
  tr -d '\r' |
  { if [ "$DEBUG" = "1" ]; then tee "$RAW_LOG_FILE"; else cat; fi; } |
  awk -v total="$TOTAL" -v progress_log="$PROGRESS_LOG" -v debug="$DEBUG" -v jobs="$JOBS" '
      BEGIN { start = systime(); last_t = start; last_c = 0 }
      /^-+ SCAN SUMMARY -+$/ { in_summary = 1; next }
      in_summary {
        if ($0 ~ /^Scanned files:/)  { split($0, a, ": "); total_scanned  += a[2] }
        if ($0 ~ /^Infected files:/) { split($0, a, ": "); total_infected += a[2] }
        if ($0 ~ /^Total errors:/)   { split($0, a, ": "); total_errors   += a[2] }
        if ($0 ~ /^End Date:/) in_summary = 0
        next
      }
      /^Scanning / {
        c++
        if (c % 100 == 0 || c == total) {
          now = systime()
          elapsed = now - start
          interval = now - last_t
          interval_files = c - last_c
          rate_inst = (interval > 0) ? interval_files / interval : 0
          rate_avg  = (elapsed  > 0) ? c / elapsed : 0
          pct = (total > 0) ? (c / total) * 100 : 0

          cmd = "pgrep -c -x clamscan 2>/dev/null"
          cmd | getline active
          close(cmd)
          active = active + 0

          if (rate_avg > 0) {
            eta_sec = (total - c) / rate_avg
            eta_h = int(eta_sec / 3600)
            eta_m = int((eta_sec % 3600) / 60)
            eta_s = int(eta_sec % 60)
            eta_str = (eta_h > 0) ? sprintf("%dh%02dm", eta_h, eta_m) : sprintf("%dm%02ds", eta_m, eta_s)
          } else {
            eta_str = "unknown"
          }

          printf("\r[%s] Scanned %d / %d (%.0f%%) | %.1f files/s avg | %d/%d workers | elapsed %dm%02ds | ETA %s   ",
                 strftime("%H:%M:%S", now), c, total, pct, rate_avg, active, jobs, int(elapsed/60), elapsed%60, eta_str) > "/dev/stderr"
          if (debug == "1") {
            printf("%d\t%d\t%.1f\t%.2f\t%.2f\t%d\n", elapsed, c, pct, rate_inst, rate_avg, active) >> progress_log
            fflush(progress_log)
          }
          last_t = now
          last_c = c
        }
        next
      }
      /^WARNING:/ { next }
      /^LibClamAV Warning:/ { next }
      NF { print }
      END {
        printf("\n") > "/dev/stderr"
        print "=== Aggregate results ==="
        printf("Total files scanned: %d\n", total_scanned + 0)
        printf("Total infected: %d\n", total_infected + 0)
        printf("Total errors: %d\n", total_errors + 0)
        # Only infections set a failing exit status; errors are expected
        # on a non-root run (unreadable files under /var etc.).
        exit (total_infected > 0) ? 1 : 0
      }
    ' |
  tee "$LOG_FILE"
# Must be captured immediately — any command in between overwrites PIPESTATUS.
# Stages: printf=0 xargs=1 tr=2 {tee|cat}=3 awk=4 tee=5
RC=${PIPESTATUS[4]}

echo
echo "Log saved: $LOG_FILE"
if [ "$DEBUG" = "1" ]; then
  echo "Debug raw log saved: $RAW_LOG_FILE"
  echo "Debug progress/rate log saved: $PROGRESS_LOG"
fi

if [ "$RC" -ne 0 ]; then
  echo "INFECTIONS FOUND — see $LOG_FILE" >&2
fi
exit "$RC"
