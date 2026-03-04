let canvas = null
let ctx = null
let shouldClose = 0
let targetWidth = 1
let targetHeight = 1
let canvasDisplayScale = 1
let resizeHookInstalled = false

const CMD_CLEAR_BACKGROUND = 1
const CMD_DRAW_RECTANGLE = 2
const CMD_DRAW_RECTANGLE_ROUNDED = 3
const CMD_DRAW_CIRCLE = 4
const CMD_DRAW_LINE = 5

const floatViewU32 = new Uint32Array(1)
const floatViewF32 = new Float32Array(floatViewU32.buffer)

function u32BitsToF32(value) {
  floatViewU32[0] = value >>> 0
  return floatViewF32[0]
}

function packedToCssColor(packed) {
  const r = packed & 0xff
  const g = (packed >>> 8) & 0xff
  const b = (packed >>> 16) & 0xff
  const a = ((packed >>> 24) & 0xff) / 255
  return `rgba(${r}, ${g}, ${b}, ${a})`
}

function ensureCanvas() {
  if (canvas && ctx) return true

  canvas = document.getElementById("canvas")
  if (!canvas) {
    console.error("[game_env] Missing #canvas element")
    return false
  }

  ctx = canvas.getContext("2d")
  if (!ctx) {
    console.error("[game_env] Failed to get 2D context")
    return false
  }

  return true
}

function updateCanvasLayout() {
  if (!canvas) return

  const viewportWidth = Math.max(1, window.innerWidth | 0)
  const viewportHeight = Math.max(1, window.innerHeight | 0)
  const scale = Math.min(viewportWidth / targetWidth, viewportHeight / targetHeight)
  canvasDisplayScale = scale > 0 ? scale : 1

  const displayWidth = Math.max(1, Math.floor(targetWidth * scale))
  const displayHeight = Math.max(1, Math.floor(targetHeight * scale))

  canvas.style.width = `${displayWidth}px`
  canvas.style.height = `${displayHeight}px`
}

export function create_game_env(getMemory) {
  return {
    init_window_js(width, height, windowTitle) {
      if (!ensureCanvas()) return

      targetWidth = Math.max(1, width | 0)
      targetHeight = Math.max(1, height | 0)

      canvas.width = targetWidth
      canvas.height = targetHeight
      updateCanvasLayout()

      if (!resizeHookInstalled) {
        window.addEventListener("resize", updateCanvasLayout)
        resizeHookInstalled = true
      }

      if (typeof windowTitle === "string" && windowTitle.length > 0) {
        document.title = windowTitle
      }

      shouldClose = 0
      window.addEventListener("beforeunload", () => {
        shouldClose = 1
      }, { once: true })
    },

    get_render_width() {
      return canvas.width
    },
    
    get_render_height() {
      return canvas.height
    },
  
    should_close_js() {
      return shouldClose !== 0
    },

    submit_commands_js(cmdTypePtr, cmdDataPtr, cmdDataSizePtr, cmdCount, cmdDataCount) {
      if (!ensureCanvas()) return

      const memory = getMemory()
      if (!memory) return

      const cmdType = new Uint32Array(memory.buffer, cmdTypePtr, cmdCount)
      const cmdData = new Uint32Array(memory.buffer, cmdDataPtr, cmdDataCount)
      const cmdDataSize = new Uint32Array(memory.buffer, cmdDataSizePtr, cmdCount)

      let dataCursor = 0

      // TODO refactor 
      for (let cmdIndex = 0; cmdIndex < cmdCount; cmdIndex += 1) {
        const opcode = cmdType[cmdIndex]
        const size = cmdDataSize[cmdIndex]

        if (dataCursor + size > cmdData.length) {
          console.warn("[game_env] Command buffer overflow")
          break
        }

        if (opcode === CMD_CLEAR_BACKGROUND && size >= 1) {
          const packed = cmdData[dataCursor]
          ctx.fillStyle = packedToCssColor(packed)
          ctx.fillRect(0, 0, canvas.width, canvas.height)
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_RECTANGLE && size >= 5) {
          const x = cmdData[dataCursor + 0] | 0
          const y = cmdData[dataCursor + 1] | 0
          const width = cmdData[dataCursor + 2] | 0
          const height = cmdData[dataCursor + 3] | 0
          const packed = cmdData[dataCursor + 4]

          ctx.fillStyle = packedToCssColor(packed)
          ctx.fillRect(x, y, width, height)
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_RECTANGLE_ROUNDED && size >= 6) {
          const x = cmdData[dataCursor + 0] | 0
          const y = cmdData[dataCursor + 1] | 0
          const width = cmdData[dataCursor + 2] | 0
          const height = cmdData[dataCursor + 3] | 0
          const radius = u32BitsToF32(cmdData[dataCursor + 4])
          const packed = cmdData[dataCursor + 5]

          const w = Math.max(0, width)
          const h = Math.max(0, height)
          const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))

          ctx.fillStyle = packedToCssColor(packed)
          ctx.beginPath()
          ctx.moveTo(x + rr, y)
          ctx.lineTo(x + w - rr, y)
          ctx.arcTo(x + w, y, x + w, y + rr, rr)
          ctx.lineTo(x + w, y + h - rr)
          ctx.arcTo(x + w, y + h, x + w - rr, y + h, rr)
          ctx.lineTo(x + rr, y + h)
          ctx.arcTo(x, y + h, x, y + h - rr, rr)
          ctx.lineTo(x, y + rr)
          ctx.arcTo(x, y, x + rr, y, rr)
          ctx.closePath()
          ctx.fill()

          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_CIRCLE && size >= 4) {
          const centerX = cmdData[dataCursor + 0] | 0
          const centerY = cmdData[dataCursor + 1] | 0
          const radius = u32BitsToF32(cmdData[dataCursor + 2])
          const packed = cmdData[dataCursor + 3]

          ctx.fillStyle = packedToCssColor(packed)
          ctx.beginPath()
          ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
          ctx.fill()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_LINE && size >= 6) {
          const startX = cmdData[dataCursor + 0] | 0
          const startY = cmdData[dataCursor + 1] | 0
          const endX = cmdData[dataCursor + 2] | 0
          const endY = cmdData[dataCursor + 3] | 0
          const thickness = u32BitsToF32(cmdData[dataCursor + 4])
          const packed = cmdData[dataCursor + 5]

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.beginPath()
          ctx.moveTo(startX, startY)
          ctx.lineTo(endX, endY)
          ctx.stroke()
          dataCursor += size
          continue
        }

        console.warn("[game_env] Unknown or malformed command", opcode, size)
        dataCursor += size
      }
    },
  }
}
