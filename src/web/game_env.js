import { create_canvas_2d_env } from "./canvas_2d.js"
import { create_odin_env } from "./odin_env.js"

const wasmUrl = "./game.wasm"

let wasmMemory = null

export function create_game_env(getMemory) {
  return create_canvas_2d_env(getMemory)
}

function startGame(wasm) {
  const odin = wasm.exports
  odin.web_init()

  let prev
  const tick = (ts) => {
    if (prev === undefined) {
      prev = ts
      requestAnimationFrame(tick)
      return
    }

    const dt = (ts - prev) / 1000.0
    prev = ts

    try {
      odin.web_tick(dt)
    } catch (err) {
      console.error("Tick error:", err)
    }

    requestAnimationFrame(tick)
  }

  requestAnimationFrame(tick)
}

async function loadWasm() {
  const bytes = await (await fetch(wasmUrl)).arrayBuffer()

  const imports = {
    odin_env: create_odin_env(() => wasmMemory),
    env: {},
    game_env: create_game_env(() => wasmMemory),
  }

  try {
    const { instance } = await WebAssembly.instantiate(bytes, imports)
    wasmMemory = instance.exports.memory
    return instance
  } catch (err) {
    console.error(err)
    return null
  }
}

const wasm = await loadWasm()
if (wasm) {
  startGame(wasm)
}
