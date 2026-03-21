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
        -out:$OUT_DIR/game \
        -o:speed

    cp src/web/game.html $OUT_DIR/game.html
    cp src/web/canvas_2d.js $OUT_DIR/canvas_2d.js
    cp src/web/game_env.js $OUT_DIR/game_env.js
    cp src/web/odin_env.js $OUT_DIR/odin_env.js
    echo "Build created in ${OUT_DIR}"
elif [ $PLATFORM == "DESKTOP" ]; then
    OUT_DIR="build/desktop"
    mkdir -p $OUT_DIR

    odin build src/ \
        -out:$OUT_DIR/game \
        -o:speed

    echo "Build created in ${OUT_DIR}"
fi

./run.sh $PLATFORM
