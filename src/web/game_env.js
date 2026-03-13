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
const CMD_DRAW_RECTANGLE_LINE = 6
const CMD_DRAW_RECTANGLE_ROUNDED_LINE = 7
const CMD_DRAW_CIRCLE_LINE = 8
const CMD_DRAW_TRIANGLE = 9
const CMD_DRAW_TRIANGLE_LINE = 10

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

function rotatePoint(x, y, pivotX, pivotY, rotation) {
  if (rotation === 0) return [x, y]

  const s = Math.sin(rotation)
  const c = Math.cos(rotation)
  const dx = x - pivotX
  const dy = y - pivotY
  return [pivotX + dx * c - dy * s, pivotY + dx * s + dy * c]
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

        if (opcode === CMD_DRAW_RECTANGLE && size >= 8) {
          const x = u32BitsToF32(cmdData[dataCursor + 0])
          const y = u32BitsToF32(cmdData[dataCursor + 1])
          const width = u32BitsToF32(cmdData[dataCursor + 2])
          const height = u32BitsToF32(cmdData[dataCursor + 3])
          const rotation = u32BitsToF32(cmdData[dataCursor + 4])
          const originX = u32BitsToF32(cmdData[dataCursor + 5])
          const originY = u32BitsToF32(cmdData[dataCursor + 6])
          const packed = cmdData[dataCursor + 7]

          const pivotX = x + originX
          const pivotY = y + originY

          ctx.fillStyle = packedToCssColor(packed)
          ctx.save()
          ctx.translate(pivotX, pivotY)
          ctx.rotate(rotation)
          ctx.fillRect(-originX, -originY, width, height)
          ctx.restore()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_RECTANGLE_ROUNDED && size >= 9) {
          const x = u32BitsToF32(cmdData[dataCursor + 0])
          const y = u32BitsToF32(cmdData[dataCursor + 1])
          const width = u32BitsToF32(cmdData[dataCursor + 2])
          const height = u32BitsToF32(cmdData[dataCursor + 3])
          const radius = u32BitsToF32(cmdData[dataCursor + 4])
          const rotation = u32BitsToF32(cmdData[dataCursor + 5])
          const originX = u32BitsToF32(cmdData[dataCursor + 6])
          const originY = u32BitsToF32(cmdData[dataCursor + 7])
          const packed = cmdData[dataCursor + 8]

          const w = Math.max(0, width)
          const h = Math.max(0, height)
          const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))

          const left = -originX
          const top = -originY
          const right = left + w
          const bottom = top + h
          const pivotX = x + originX
          const pivotY = y + originY

          ctx.fillStyle = packedToCssColor(packed)
          ctx.save()
          ctx.translate(pivotX, pivotY)
          ctx.rotate(rotation)
          ctx.beginPath()
          ctx.moveTo(left + rr, top)
          ctx.lineTo(right - rr, top)
          ctx.arcTo(right, top, right, top + rr, rr)
          ctx.lineTo(right, bottom - rr)
          ctx.arcTo(right, bottom, right - rr, bottom, rr)
          ctx.lineTo(left + rr, bottom)
          ctx.arcTo(left, bottom, left, bottom - rr, rr)
          ctx.lineTo(left, top + rr)
          ctx.arcTo(left, top, left + rr, top, rr)
          ctx.closePath()
          ctx.fill()
          ctx.restore()

          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_CIRCLE && size >= 7) {
          const centerX = u32BitsToF32(cmdData[dataCursor + 0])
          const centerY = u32BitsToF32(cmdData[dataCursor + 1])
          const radius = u32BitsToF32(cmdData[dataCursor + 2])
          const rotation = u32BitsToF32(cmdData[dataCursor + 3])
          const originX = u32BitsToF32(cmdData[dataCursor + 4])
          const originY = u32BitsToF32(cmdData[dataCursor + 5])
          const packed = cmdData[dataCursor + 6]

          const pivotX = centerX - radius + originX
          const pivotY = centerY - radius + originY
          const [drawX, drawY] = rotatePoint(centerX, centerY, pivotX, pivotY, rotation)

          ctx.fillStyle = packedToCssColor(packed)
          ctx.beginPath()
          ctx.arc(drawX, drawY, radius, 0, Math.PI * 2)
          ctx.fill()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_LINE && size >= 9) {
          const startX = u32BitsToF32(cmdData[dataCursor + 0])
          const startY = u32BitsToF32(cmdData[dataCursor + 1])
          const endX = u32BitsToF32(cmdData[dataCursor + 2])
          const endY = u32BitsToF32(cmdData[dataCursor + 3])
          const thickness = u32BitsToF32(cmdData[dataCursor + 4])
          const rotation = u32BitsToF32(cmdData[dataCursor + 5])
          const originX = u32BitsToF32(cmdData[dataCursor + 6])
          const originY = u32BitsToF32(cmdData[dataCursor + 7])
          const packed = cmdData[dataCursor + 8]

          const minX = Math.min(startX, endX)
          const minY = Math.min(startY, endY)
          const pivotX = minX + originX
          const pivotY = minY + originY
          const [sx, sy] = rotatePoint(startX, startY, pivotX, pivotY, rotation)
          const [ex, ey] = rotatePoint(endX, endY, pivotX, pivotY, rotation)

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.beginPath()
          ctx.moveTo(sx, sy)
          ctx.lineTo(ex, ey)
          ctx.stroke()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_RECTANGLE_LINE && size >= 9) {
          const x = u32BitsToF32(cmdData[dataCursor + 0])
          const y = u32BitsToF32(cmdData[dataCursor + 1])
          const width = u32BitsToF32(cmdData[dataCursor + 2])
          const height = u32BitsToF32(cmdData[dataCursor + 3])
          const thickness = u32BitsToF32(cmdData[dataCursor + 4])
          const rotation = u32BitsToF32(cmdData[dataCursor + 5])
          const originX = u32BitsToF32(cmdData[dataCursor + 6])
          const originY = u32BitsToF32(cmdData[dataCursor + 7])
          const packed = cmdData[dataCursor + 8]
          const pivotX = x + originX
          const pivotY = y + originY

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.save()
          ctx.translate(pivotX, pivotY)
          ctx.rotate(rotation)
          ctx.strokeRect(-originX, -originY, width, height)
          ctx.restore()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_RECTANGLE_ROUNDED_LINE && size >= 10) {
          const x = u32BitsToF32(cmdData[dataCursor + 0])
          const y = u32BitsToF32(cmdData[dataCursor + 1])
          const width = u32BitsToF32(cmdData[dataCursor + 2])
          const height = u32BitsToF32(cmdData[dataCursor + 3])
          const radius = u32BitsToF32(cmdData[dataCursor + 4])
          const thickness = u32BitsToF32(cmdData[dataCursor + 5])
          const rotation = u32BitsToF32(cmdData[dataCursor + 6])
          const originX = u32BitsToF32(cmdData[dataCursor + 7])
          const originY = u32BitsToF32(cmdData[dataCursor + 8])
          const packed = cmdData[dataCursor + 9]

          const w = Math.max(0, width)
          const h = Math.max(0, height)
          const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))

          const left = -originX
          const top = -originY
          const right = left + w
          const bottom = top + h
          const pivotX = x + originX
          const pivotY = y + originY

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.save()
          ctx.translate(pivotX, pivotY)
          ctx.rotate(rotation)
          ctx.beginPath()
          ctx.moveTo(left + rr, top)
          ctx.lineTo(right - rr, top)
          ctx.arcTo(right, top, right, top + rr, rr)
          ctx.lineTo(right, bottom - rr)
          ctx.arcTo(right, bottom, right - rr, bottom, rr)
          ctx.lineTo(left + rr, bottom)
          ctx.arcTo(left, bottom, left, bottom - rr, rr)
          ctx.lineTo(left, top + rr)
          ctx.arcTo(left, top, left + rr, top, rr)
          ctx.closePath()
          ctx.stroke()
          ctx.restore()

          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_CIRCLE_LINE && size >= 8) {
          const centerX = u32BitsToF32(cmdData[dataCursor + 0])
          const centerY = u32BitsToF32(cmdData[dataCursor + 1])
          const radius = u32BitsToF32(cmdData[dataCursor + 2])
          const thickness = u32BitsToF32(cmdData[dataCursor + 3])
          const rotation = u32BitsToF32(cmdData[dataCursor + 4])
          const originX = u32BitsToF32(cmdData[dataCursor + 5])
          const originY = u32BitsToF32(cmdData[dataCursor + 6])
          const packed = cmdData[dataCursor + 7]

          const pivotX = centerX - radius + originX
          const pivotY = centerY - radius + originY
          const [drawX, drawY] = rotatePoint(centerX, centerY, pivotX, pivotY, rotation)

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.beginPath()
          ctx.arc(drawX, drawY, radius, 0, Math.PI * 2)
          ctx.stroke()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_TRIANGLE && size >= 10) {
          const x1 = u32BitsToF32(cmdData[dataCursor + 0])
          const y1 = u32BitsToF32(cmdData[dataCursor + 1])
          const x2 = u32BitsToF32(cmdData[dataCursor + 2])
          const y2 = u32BitsToF32(cmdData[dataCursor + 3])
          const x3 = u32BitsToF32(cmdData[dataCursor + 4])
          const y3 = u32BitsToF32(cmdData[dataCursor + 5])
          const rotation = u32BitsToF32(cmdData[dataCursor + 6])
          const originX = u32BitsToF32(cmdData[dataCursor + 7])
          const originY = u32BitsToF32(cmdData[dataCursor + 8])
          const packed = cmdData[dataCursor + 9]

          const minX = Math.min(x1, x2, x3)
          const minY = Math.min(y1, y2, y3)
          const pivotX = minX + originX
          const pivotY = minY + originY
          const [rx1, ry1] = rotatePoint(x1, y1, pivotX, pivotY, rotation)
          const [rx2, ry2] = rotatePoint(x2, y2, pivotX, pivotY, rotation)
          const [rx3, ry3] = rotatePoint(x3, y3, pivotX, pivotY, rotation)

          ctx.fillStyle = packedToCssColor(packed)
          ctx.beginPath()
          ctx.moveTo(rx1, ry1)
          ctx.lineTo(rx2, ry2)
          ctx.lineTo(rx3, ry3)
          ctx.closePath()
          ctx.fill()
          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_TRIANGLE_LINE && size >= 11) {
          const x1 = u32BitsToF32(cmdData[dataCursor + 0])
          const y1 = u32BitsToF32(cmdData[dataCursor + 1])
          const x2 = u32BitsToF32(cmdData[dataCursor + 2])
          const y2 = u32BitsToF32(cmdData[dataCursor + 3])
          const x3 = u32BitsToF32(cmdData[dataCursor + 4])
          const y3 = u32BitsToF32(cmdData[dataCursor + 5])
          const thickness = u32BitsToF32(cmdData[dataCursor + 6])
          const rotation = u32BitsToF32(cmdData[dataCursor + 7])
          const originX = u32BitsToF32(cmdData[dataCursor + 8])
          const originY = u32BitsToF32(cmdData[dataCursor + 9])
          const packed = cmdData[dataCursor + 10]

          const minX = Math.min(x1, x2, x3)
          const minY = Math.min(y1, y2, y3)
          const pivotX = minX + originX
          const pivotY = minY + originY
          const [rx1, ry1] = rotatePoint(x1, y1, pivotX, pivotY, rotation)
          const [rx2, ry2] = rotatePoint(x2, y2, pivotX, pivotY, rotation)
          const [rx3, ry3] = rotatePoint(x3, y3, pivotX, pivotY, rotation)

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          ctx.beginPath()
          ctx.moveTo(rx1, ry1)
          ctx.lineTo(rx2, ry2)
          ctx.lineTo(rx3, ry3)
          ctx.closePath()
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
