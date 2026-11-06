#!/usr/bin/env bash
# Written for plain bash: scan and find errors (permission denied etc.) are
# expected and must not abort the run. writeShellApplication prepends
# `set -euo pipefail`, so turn errexit and pipefail back off here.
set -u +e +o pipefail

# Signatures come from the system database, kept current by
# clamav-freshclam.service (root-owned /var/lib/clamav, updated as clamupdate).
# The script no longer downloads its own copy.
DB_DIR=/var/lib/clamav

# For full root-covering coverage, run the whole script under sudo
# (clamscan-host-full). Under sudo it still scans and excludes the invoking
# user's home, not /root, and logs to /var/log/clamscan-host.

# Exit status: 0 = no infections found, 1 = infections found,
# 2 = no usable signature database.
# Scan errors (permission denied etc.) are reported in the log but do not
# affect the exit status, since a non-root run always hits some.

# Set CLAMSCAN_DEBUG=1 to also get: a raw unfiltered log (every per-unit
# SCAN SUMMARY block, in full) and a per-checkpoint rate .tsv for plotting
# throughput over time. Off by default for a lean run.
DEBUG="${CLAMSCAN_DEBUG:-0}"

# The user whose home to scan: the sudo caller under sudo, else ourselves.
REAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[ -n "$USER_HOME" ] || { echo "Cannot resolve home for $REAL_USER" >&2; exit 2; }

# --- Signature database check ---
# Plain file tests, not compgen: writeShellApplication's bash is built
# without programmable completion, so compgen doesn't exist there.
has_db() { [ -f "$DB_DIR/$1.cvd" ] || [ -f "$DB_DIR/$1.cld" ]; }
if ! has_db main || ! has_db daily; then
  echo "No ClamAV signatures in $DB_DIR — check: systemctl status clamav-freshclam.service" >&2
  exit 2
fi
if [ -z "$(find "$DB_DIR" -maxdepth 1 -name 'daily.c[lv]d' -mmin -2880 2>/dev/null)" ]; then
  echo "WARNING: daily signatures in $DB_DIR are over 2 days old — check: journalctl -u clamav-freshclam" >&2
fi

HOST_EXCLUDES=(
  "/proc" "/sys" "/dev" "/run" "/tmp"
  "/usr" "/etc"
  "/nix/store"
  "/ostree"
  "/sysroot/ostree"
  "/var/lib/containers"
  "/var/lib/flatpak"
  "/var/lib/nix/store"
  "$USER_HOME/.local/share/containers/storage"
  "$USER_HOME/.local/share/Steam"
  "$USER_HOME/.cache/huggingface/hub"
  "$USER_HOME/Projects/tkube/.state/llama-cache"
  "$USER_HOME/.var/app/org.mozilla.firefox/cache"
  # rclone FUSE mount: root can't read it (no allow_other, by design), and
  # scanning through it would download the whole remote.
  "$USER_HOME/Dropbox"
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
  # /root, /opt, /srv, /mnt are symlinks into /var: clamscan follows a
  # symlink given as an argument, so they would be scanned twice.
  [ -L "$entry" ] && continue
  SCAN_UNITS+=("$entry")
done < <(find / -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

while IFS= read -r -d '' entry; do
  base="$(basename "$entry")"
  [ "$base" = "home" ] && continue
  is_excluded "$entry" && continue
  # /root, /opt, /srv, /mnt are symlinks into /var: clamscan follows a
  # symlink given as an argument, so they would be scanned twice.
  [ -L "$entry" ] && continue
  SCAN_UNITS+=("$entry")
done < <(find /var -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

while IFS= read -r -d '' entry; do
  is_excluded "$entry" && continue
  # /root, /opt, /srv, /mnt are symlinks into /var: clamscan follows a
  # symlink given as an argument, so they would be scanned twice.
  [ -L "$entry" ] && continue
  SCAN_UNITS+=("$entry")
done < <(find "$USER_HOME" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

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

# --- Parallel scan ---
# Root runs log to a root-owned directory rather than writing into a
# user-writable one.
if [ "$(id -u)" -eq 0 ]; then
  LOG_DIR=/var/log/clamscan-host
  install -d -m 0700 "$LOG_DIR"
else
  LOG_DIR="$USER_HOME/.local/state/clamscan-logs"
  mkdir -p "$LOG_DIR"
fi
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
  xargs -0 -P "$JOBS" -I{} clamscan -r -i -v --database="$DB_DIR" "${CLAMSCAN_EXCLUDES[@]}" {} 2>&1 |
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
