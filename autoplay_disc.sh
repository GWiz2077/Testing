#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/logs/startmovie.log"
mkdir -p "$HOME/logs"

disc_present() {
  udevadm info --query=property --name=/dev/sr0 2>/dev/null | grep -q '^ID_CDROM_MEDIA=1$'
}

disc_ready() {
  blkid /dev/sr0 >/dev/null 2>&1
}

play_disc_with_retries() {
  pgrep -x vlc >/dev/null && return 0

  for i in {1..25}; do
    disc_present || return 0
    if disc_ready; then
      break
    fi
    sleep 1
  done

  for attempt in {1..6}; do
    disc_present || return 0
    echo "$(date) Starting VLC attempt $attempt" >> "$LOG"

    start_ts=$(date +%s)
    vlc --fullscreen --no-video-title-show dvdnav:///dev/sr0 >>"$LOG" 2>&1 || true
    end_ts=$(date +%s)
    runtime=$(( end_ts - start_ts ))

    if [ "$runtime" -ge 8 ]; then
      echo "$(date) VLC ran ${runtime}s (OK)" >> "$LOG"
      return 0
    fi

    echo "$(date) VLC exited after ${runtime}s (retrying)" >> "$LOG"
    sleep 3
  done
}

# --- NEW: check immediately at startup ---
if disc_present; then
  echo "$(date) Disc already present at boot" >> "$LOG"
  play_disc_with_retries
fi

LAST=0
if disc_present; then
  LAST=1
fi

while true; do
  if disc_present; then NOW=1; else NOW=0; fi

  if [ "$LAST" -eq 0 ] && [ "$NOW" -eq 1 ]; then
    play_disc_with_retries
  fi

  if [ "$LAST" -eq 1 ] && [ "$NOW" -eq 0 ]; then
    echo "$(date) Disc removed" >> "$LOG"
  fi

  LAST="$NOW"
  sleep 1
done    runtime=$(( end_ts - start_ts ))

    # If VLC stayed up longer than ~8s, treat it as “worked” (user may have closed it later)
    if [ "$runtime" -ge 8 ]; then
      echo "$(date) VLC ran ${runtime}s (OK)" >> "$LOG"
      return 0
    fi

    # If it died fast, it likely failed to open the disc. Wait and retry.
    echo "$(date) VLC exited after ${runtime}s (retrying)" >> "$LOG"
    sleep 3
  done
}

# Main loop: wait for disc insertion, then play, then wait for removal before re-arming
LAST=0
while true; do
  if disc_present; then NOW=1; else NOW=0; fi

  if [ "$LAST" -eq 0 ] && [ "$NOW" -eq 1 ]; then
    play_disc_with_retries
  fi

  # Once disc is present, don’t retrigger until it’s removed
  if [ "$LAST" -eq 1 ] && [ "$NOW" -eq 0 ]; then
    echo "$(date) Disc removed" >> "$LOG"
  fi

  LAST="$NOW"
  sleep 1
done
