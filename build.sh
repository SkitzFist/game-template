#!/usr/bin/env bash
set -eu

OUT_DIR="build/web"
mkdir -p $OUT_DIR

export EMSDK_QUIET=1

odin build src/ \
    -target:js_wasm32 \
    -build-mode:obj \
    -define:PLATFORM=WEB \
    -out:$OUT_DIR/game.wasm.o \
    -o:speed

ODIN_PATH=$(odin root)

cp ${ODIN_PATH}/core/sys/wasm/js/odin.js $OUT_DIR/odin.js
files="$OUT_DIR/game.wasm.o ${ODIN_PATH}/vendor/raylib/wasm/libraylib.a ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a"
flags="-sUSE_GLFW=3 -sSTACK_SIZE=2097152 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=33554432 -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS=2 -sEXIT_RUNTIME=0 -sNO_EXIT_RUNTIME=1"

emcc -o $OUT_DIR/game.js $files $flags
cp src/web/shell.html $OUT_DIR/game.html
rm $OUT_DIR/game.wasm.o

echo "Web build created in ${OUT_DIR}"

./run.sh
