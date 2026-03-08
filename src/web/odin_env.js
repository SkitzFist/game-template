export function create_odin_env(getWasmMemory) {
  return {
    write(fd, ptr, len) {
      const wasmMemory = getWasmMemory()
      const bytes = new Uint8Array(wasmMemory.buffer, ptr, len)
      const text = new TextDecoder("utf-8").decode(bytes)

      if (fd == 2) console.error(text)
      else console.log(text)

      return len
    },
    rand_bytes(ptr, len) {
      const wasmMemory = getWasmMemory()
      const bytes = new Uint8Array(wasmMemory.buffer, ptr, len)

      crypto.getRandomValues(bytes)
      return 1
    },
    time_now() {
      return BigInt(Date.now()) * 1_000_000n
    },
    sin(x) {
      return Math.sin(x)
    },
    cos(x) {
      return Math.cos(x)
    },
    tan(x) {
      return Math.tan(x)
    },
    asin(x) {
      return Math.asin(x)
    },
    acos(x) {
      return Math.acos(x)
    },
    atan(x) {
      return Math.atan(x)
    },
    atan2(y, x) {
      return Math.atan2(y, x)
    },
    sinh(x) {
      return Math.sinh(x)
    },
    cosh(x) {
      return Math.cosh(x)
    },
    tanh(x) {
      return Math.tanh(x)
    },
    exp(x) {
      return Math.exp(x)
    },
    exp2(x) {
      return 2 ** x
    },
    log(x) {
      return Math.log(x)
    },
    log2(x) {
      return Math.log2(x)
    },
    log10(x) {
      return Math.log10(x)
    },
    pow(x, y) {
      return Math.pow(x, y)
    },
    sqrt(x) {
      return Math.sqrt(x)
    },
    cbrt(x) {
      return Math.cbrt(x)
    },
    floor(x) {
      return Math.floor(x)
    },
    ceil(x) {
      return Math.ceil(x)
    },
    round(x) {
      return Math.round(x)
    },
    trunc(x) {
      return Math.trunc(x)
    },
    abs(x) {
      return Math.abs(x)
    },
    fabs(x) {
      return Math.abs(x)
    },
    fmod(x, y) {
      return x % y
    },
    min(x, y) {
      return Math.min(x, y)
    },
    max(x, y) {
      return Math.max(x, y)
    },
    hypot(x, y) {
      return Math.hypot(x, y)
    },
  }
}
