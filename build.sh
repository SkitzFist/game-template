#!/usr/bin/env bash
set -eu

PLATFORM="${1^^}"

echo "Building..."
echo "Target platform: ${PLATFORM}"

if [ $PLATFORM == "WEB" ]; then
    OUT_DIR="build/web"
    mkdir -p $OUT_DIR

    odin build src/ \
        -target:js_wasm32 \
        -define:PLATFORM=WEB \
        -out:$OUT_DIR/game \
        -o:speed

    cp src/web/game.html $OUT_DIR/game.html
    cp src/web/game.js $OUT_DIR/game.js
    echo "Build created in ${OUT_DIR}"
elif [ $PLATFORM == "DESKTOP" ]; then
    OUT_DIR="build/desktop"
    mkdir -p $OUT_DIR

    odin build src/ \
        -define:PLATFORM=DESKTOP \
        -out:$OUT_DIR/game \
        -o:speed

    echo "Build created in ${OUT_DIR}"
fi

./run.sh $PLATFORM
