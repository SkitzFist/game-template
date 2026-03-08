import { create_game_env } from "./game_env.js"
import { create_odin_env } from "./odin_env.js"

const wasmUrl = "./game.wasm"

let wasmMemory = null


function startGame(wasm) {
  const odin = wasm.exports
  odin.web_init();

  let prev;
  const tick = (ts) => {
    if (prev === undefined) {
      prev = ts;
      requestAnimationFrame(tick)
      return
    }

    const dt = (ts - prev ) / 1000.0;
    prev = ts;

    try {
      odin.web_tick(dt);
    } catch (err) {
      console.error("Tick error: ", err)
    }

    requestAnimationFrame(tick)
  }

  requestAnimationFrame(tick)
}

async function loadWasm() {
  const bytes = await (await fetch(wasmUrl)).arrayBuffer()

  console.log("bytes:", bytes)

  const imports = {
    odin_env: create_odin_env(() => wasmMemory),
    env: {},
    game_env: create_game_env(() => wasmMemory),
  };

  console.log("imports:", imports)

  try {
    const { instance } = await WebAssembly.instantiate(bytes, imports);
    console.log("WASM Exports: ", instance.exports)

    wasmMemory = instance.exports.memory

    return instance;
  } catch ( e ) {
    console.error(e)
  }
}


const wasm = await loadWasm()
startGame(wasm)
