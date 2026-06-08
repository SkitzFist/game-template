const wasmUrl = "./game.wasm"

function startGame(wasm) {
  const odin = wasm.exports
  odin.web_init()

  if (!odin.web_tick) {
    return
  }

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
  const memory = new window.odin.WasmMemoryInterface()
  const imports = window.odin.setupDefaultImports(memory, null, memory.memory)

  try {
    const { instance } = await WebAssembly.instantiate(bytes, imports)

    memory.setExports(instance.exports)
    if (instance.exports.memory) {
      memory.setMemory(instance.exports.memory)
    }

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
