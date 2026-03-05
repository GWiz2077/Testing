#!/usr/bin/env bash
set -euo pipefail

LOCK="/tmp/discplay.lock"
LOG="$HOME/logs/discplay.log"

mkdir -p "$HOME/logs"

play_disc() {
  # Prevent multiple VLC windows
  if pgrep -x vlc >/dev/null; then
    echo "$(date) VLC already running" >> "$LOG"
    return
  fi

  echo "$(date) Launching disc playback" >> "$LOG"
  nohup vlc --fullscreen dvdnav:///dev/sr0 >/dev/null 2>&1 &
}

disc_present() {
  udevadm info --query=property --name=/dev/sr0 2>/dev/null | grep -q "ID_CDROM_MEDIA=1"
}

# At boot: if disc already in drive, play it
if disc_present; then
  play_disc
fi

LAST_STATE="0"

while true; do
  if disc_present; then
    NOW_STATE="1"
  else
    NOW_STATE="0"
  fi

  # Trigger only when changing from no-disc to disc-present
  if [ "$LAST_STATE" = "0" ] && [ "$NOW_STATE" = "1" ]; then
    sleep 2
    play_disc
  fi

  LAST_STATE="$NOW_STATE"
  sleep 2
done
