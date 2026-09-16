#!/usr/bin/env bash
set -eu

# TODO: should receive path to asset folder as argument for api users

PLATFORM="${1^^}"

echo "Building..."
echo "Target platform: ${PLATFORM}"

if [ $PLATFORM == "WEB" ]; then
    OUT_DIR="build/web"
    ODIN_ROOT="$(odin root)"
    mkdir -p $OUT_DIR

    odin build src/ \
        -target:js_wasm32 \
        -out:$OUT_DIR/game \
        -o:speed \
        -define:PLATFORM=WEB \
        -define:RENDER_API=WEBGL \
        -collection:stride=skz/stride

    cp src/web/game.html $OUT_DIR/game.html
    cp "${ODIN_ROOT}/core/sys/wasm/js/odin.js" $OUT_DIR/odin.js
    cp src/web/game_env.js $OUT_DIR/game_env.js
    echo "Build created in ${OUT_DIR}"
elif [ $PLATFORM == "DESKTOP" ]; then
    OUT_DIR="build/desktop"
    mkdir -p $OUT_DIR

    odin build src/ \
        -out:$OUT_DIR/game \
        -o:speed \
        -define:PLATFORM=DESKTOP \
        -define:RENDER_API=OPENGL \
        -collection:stride=skz/stride

    echo "Build created in ${OUT_DIR}"
fi


./run.sh $PLATFORM

