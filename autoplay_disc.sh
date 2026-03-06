#!/bin/bash

sleep 3

disc_present() {
    blkid /dev/sr0 >/dev/null 2>&1
}

play_movie() {
    if ! pgrep -x vlc >/dev/null; then
        vlc --fullscreen --no-video-title-show dvdnav:///dev/sr0 &
    fi
}

stop_movie() {
    if pgrep -x vlc >/dev/null; then
        pkill -x vlc
    fi
}

while true; do
    if disc_present; then
        play_movie
    else
        stop_movie
    fi

    sleep 2
done
  # Disc removed
  if [ "$LAST" -eq 1 ] && [ "$NOW" -eq 0 ]; then
    echo "$(date) Disc removed" >> "$LOG"
    close_vlc
  fi

  LAST="$NOW"
  sleep 1
done      return 0
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
