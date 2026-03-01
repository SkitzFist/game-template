const wasmUrl = "./game.wasm"

let wasmMemory = null

function get_odin_env() {
  return {
      write(fd, ptr, len) {
        const bytes = new Uint8Array(wasmMemory.buffer, ptr, len);
        const text = new TextDecoder("utf-8").decode(bytes)

        if ( fd == 2 ) console.error(text)
        else console.log( text )

        return len
      },
      rand_bytes(ptr, len) {
        const bytes = new Uint8Array(wasmMemory.buffer, ptr, len)

        crypto.getRandomValues(bytes)
        return 1;
      },
      time_now() {
        return BigInt(Date.now()) * 1_000_000n
      },
  }
}


function startGame(wasm) {
  const odin = wasm.exports
  odin.web_init();

  let prev;
  const tick = (ts) => {
    if (prev === undefined) prev = ts;
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
    odin_env: get_odin_env(),
    env: {
      test() {
        console.log("TEST");
      },
    },
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
