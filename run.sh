#!/usr/bin/env bash
set -eu

PLATFORM="${1^^}"

if [ $PLATFORM == "WEB" ]; then
    PORT="8000"
    OUT_DIR="build/web"

    if [ ! -d "$OUT_DIR" ]; then
      echo "Missing $OUT_DIR. Run ./build.sh first."
      exit 1
    fi

    python3 -m http.server "$PORT" --directory "$OUT_DIR" &
    SERVER_PID=$!

    cleanup() {
      kill "$SERVER_PID" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    sleep 0.2

    xdg-open "http://localhost:$PORT/game.html" >/dev/null 2>&1 || true

    wait "$SERVER_PID"
elif [ $PLATFORM == "DESKTOP" ]; then
    ./build/desktop/game
fi

