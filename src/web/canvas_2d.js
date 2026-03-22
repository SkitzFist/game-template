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

let canvas = null
let ctx = null
let shouldClose = 0
let targetWidth = 1
let targetHeight = 1
let canvasDisplayScale = 1
let resizeHookInstalled = false
let lastFillStyle = ""
let lastStrokeStyle = ""
let lastLineWidth = -1
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

function readF32(data, base, index) {
  return u32BitsToF32(data[base + index])
}

function clampPivot(value) {
  return Math.min(1, Math.max(0, value))
}

function resolvePivotInBounds(x, y, width, height, pivotX, pivotY) {
  return [
    x + Math.max(0, width) * clampPivot(pivotX),
    y + Math.max(0, height) * clampPivot(pivotY),
  ]
}

function withPivotTransform(x, y, width, height, pivotX, pivotY, rotation, draw) {
  if (rotation === 0) {
    draw(0, 0)
    return
  }

  const [worldPivotX, worldPivotY] = resolvePivotInBounds(x, y, width, height, pivotX, pivotY)
  ctx.save()
  ctx.translate(worldPivotX, worldPivotY)
  ctx.rotate(rotation)
  draw(worldPivotX, worldPivotY)
  ctx.restore()
}

function setFillFromPacked(packed) {
  const css = packedToCssColor(packed)
  if (css !== lastFillStyle) {
    ctx.fillStyle = css
    lastFillStyle = css
  }
}

function setStrokeFromPacked(packed, thickness) {
  const css = packedToCssColor(packed)
  if (css !== lastStrokeStyle) {
    ctx.strokeStyle = css
    lastStrokeStyle = css
  }

  const lineWidth = thickness / canvasDisplayScale
  if (lineWidth !== lastLineWidth) {
    ctx.lineWidth = lineWidth
    lastLineWidth = lineWidth
  }
}

function resetDrawState() {
  lastFillStyle = ""
  lastStrokeStyle = ""
  lastLineWidth = -1
}

function resolveRoundedRect(x, y, width, height, radius) {
  const w = Math.max(0, width)
  const h = Math.max(0, height)
  const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))
  return { x, y, w, h, rr }
}

function traceRoundedRectPath(x, y, width, height, radius) {
  const right = x + width
  const bottom = y + height
  ctx.beginPath()
  ctx.moveTo(x + radius, y)
  ctx.lineTo(right - radius, y)
  ctx.arcTo(right, y, right, y + radius, radius)
  ctx.lineTo(right, bottom - radius)
  ctx.arcTo(right, bottom, right - radius, bottom, radius)
  ctx.lineTo(x + radius, bottom)
  ctx.arcTo(x, bottom, x, bottom - radius, radius)
  ctx.lineTo(x, y + radius)
  ctx.arcTo(x, y, x + radius, y, radius)
  ctx.closePath()
}

function traceTrianglePath(x1, y1, x2, y2, x3, y3) {
  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.lineTo(x3, y3)
  ctx.closePath()
}

function traceLinePath(startX, startY, endX, endY) {
  ctx.beginPath()
  ctx.moveTo(startX, startY)
  ctx.lineTo(endX, endY)
}

function fillRectangleCommand(data, base) {
  const x = readF32(data, base, 0)
  const y = readF32(data, base, 1)
  const width = readF32(data, base, 2)
  const height = readF32(data, base, 3)
  const rotation = readF32(data, base, 4)
  const pivotX = readF32(data, base, 5)
  const pivotY = readF32(data, base, 6)
  const packed = data[base + 7]

  setFillFromPacked(packed)
  withPivotTransform(x, y, width, height, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    ctx.fillRect(x - worldPivotX, y - worldPivotY, width, height)
  })
}

function fillRoundedRectCommand(data, base) {
  const shape = resolveRoundedRect(
    readF32(data, base, 0),
    readF32(data, base, 1),
    readF32(data, base, 2),
    readF32(data, base, 3),
    readF32(data, base, 4),
  )
  const rotation = readF32(data, base, 5)
  const pivotX = readF32(data, base, 6)
  const pivotY = readF32(data, base, 7)
  const packed = data[base + 8]

  setFillFromPacked(packed)
  withPivotTransform(shape.x, shape.y, shape.w, shape.h, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    traceRoundedRectPath(shape.x - worldPivotX, shape.y - worldPivotY, shape.w, shape.h, shape.rr)
    ctx.fill()
  })
}

function fillCircleCommand(data, base) {
  const centerX = readF32(data, base, 0)
  const centerY = readF32(data, base, 1)
  const radius = readF32(data, base, 2)
  const rotation = readF32(data, base, 3)
  const pivotX = readF32(data, base, 4)
  const pivotY = readF32(data, base, 5)
  const packed = data[base + 6]

  setFillFromPacked(packed)
  withPivotTransform(centerX - radius, centerY - radius, radius * 2, radius * 2, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    ctx.beginPath()
    ctx.arc(centerX - worldPivotX, centerY - worldPivotY, radius, 0, Math.PI * 2)
    ctx.fill()
  })
}

function strokeLineCommand(data, base) {
  const startX = readF32(data, base, 0)
  const startY = readF32(data, base, 1)
  const endX = readF32(data, base, 2)
  const endY = readF32(data, base, 3)
  const thickness = readF32(data, base, 4)
  const rotation = readF32(data, base, 5)
  const pivotX = readF32(data, base, 6)
  const pivotY = readF32(data, base, 7)
  const packed = data[base + 8]
  const minX = Math.min(startX, endX)
  const minY = Math.min(startY, endY)
  const width = Math.max(startX, endX) - minX
  const height = Math.max(startY, endY) - minY

  setStrokeFromPacked(packed, thickness)
  withPivotTransform(minX, minY, width, height, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    traceLinePath(startX - worldPivotX, startY - worldPivotY, endX - worldPivotX, endY - worldPivotY)
    ctx.stroke()
  })
}

function strokeRectangleCommand(data, base) {
  const x = readF32(data, base, 0)
  const y = readF32(data, base, 1)
  const width = readF32(data, base, 2)
  const height = readF32(data, base, 3)
  const thickness = readF32(data, base, 4)
  const rotation = readF32(data, base, 5)
  const pivotX = readF32(data, base, 6)
  const pivotY = readF32(data, base, 7)
  const packed = data[base + 8]

  setStrokeFromPacked(packed, thickness)
  withPivotTransform(x, y, width, height, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    ctx.strokeRect(x - worldPivotX, y - worldPivotY, width, height)
  })
}

function strokeRoundedRectCommand(data, base) {
  const shape = resolveRoundedRect(
    readF32(data, base, 0),
    readF32(data, base, 1),
    readF32(data, base, 2),
    readF32(data, base, 3),
    readF32(data, base, 4),
  )
  const thickness = readF32(data, base, 5)
  const rotation = readF32(data, base, 6)
  const pivotX = readF32(data, base, 7)
  const pivotY = readF32(data, base, 8)
  const packed = data[base + 9]

  setStrokeFromPacked(packed, thickness)
  withPivotTransform(shape.x, shape.y, shape.w, shape.h, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    traceRoundedRectPath(shape.x - worldPivotX, shape.y - worldPivotY, shape.w, shape.h, shape.rr)
    ctx.stroke()
  })
}

function strokeCircleCommand(data, base) {
  const centerX = readF32(data, base, 0)
  const centerY = readF32(data, base, 1)
  const radius = readF32(data, base, 2)
  const thickness = readF32(data, base, 3)
  const rotation = readF32(data, base, 4)
  const pivotX = readF32(data, base, 5)
  const pivotY = readF32(data, base, 6)
  const packed = data[base + 7]

  setStrokeFromPacked(packed, thickness)
  withPivotTransform(centerX - radius, centerY - radius, radius * 2, radius * 2, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    ctx.beginPath()
    ctx.arc(centerX - worldPivotX, centerY - worldPivotY, radius, 0, Math.PI * 2)
    ctx.stroke()
  })
}

function fillTriangleCommand(data, base) {
  const x1 = readF32(data, base, 0)
  const y1 = readF32(data, base, 1)
  const x2 = readF32(data, base, 2)
  const y2 = readF32(data, base, 3)
  const x3 = readF32(data, base, 4)
  const y3 = readF32(data, base, 5)
  const rotation = readF32(data, base, 6)
  const pivotX = readF32(data, base, 7)
  const pivotY = readF32(data, base, 8)
  const packed = data[base + 9]
  const minX = Math.min(x1, x2, x3)
  const minY = Math.min(y1, y2, y3)
  const width = Math.max(x1, x2, x3) - minX
  const height = Math.max(y1, y2, y3) - minY

  setFillFromPacked(packed)
  withPivotTransform(minX, minY, width, height, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    traceTrianglePath(x1 - worldPivotX, y1 - worldPivotY, x2 - worldPivotX, y2 - worldPivotY, x3 - worldPivotX, y3 - worldPivotY)
    ctx.fill()
  })
}

function strokeTriangleCommand(data, base) {
  const x1 = readF32(data, base, 0)
  const y1 = readF32(data, base, 1)
  const x2 = readF32(data, base, 2)
  const y2 = readF32(data, base, 3)
  const x3 = readF32(data, base, 4)
  const y3 = readF32(data, base, 5)
  const thickness = readF32(data, base, 6)
  const rotation = readF32(data, base, 7)
  const pivotX = readF32(data, base, 8)
  const pivotY = readF32(data, base, 9)
  const packed = data[base + 10]
  const minX = Math.min(x1, x2, x3)
  const minY = Math.min(y1, y2, y3)
  const width = Math.max(x1, x2, x3) - minX
  const height = Math.max(y1, y2, y3) - minY

  setStrokeFromPacked(packed, thickness)
  withPivotTransform(minX, minY, width, height, pivotX, pivotY, rotation, (worldPivotX, worldPivotY) => {
    traceTrianglePath(x1 - worldPivotX, y1 - worldPivotY, x2 - worldPivotX, y2 - worldPivotY, x3 - worldPivotX, y3 - worldPivotY)
    ctx.stroke()
  })
}

const COMMAND_HANDLERS = []

COMMAND_HANDLERS[CMD_CLEAR_BACKGROUND] = {
  words: 1,
  draw(data, base) {
    setFillFromPacked(data[base])
    ctx.fillRect(0, 0, canvas.width, canvas.height)
  },
}

COMMAND_HANDLERS[CMD_DRAW_RECTANGLE] = { words: 8, draw: fillRectangleCommand }
COMMAND_HANDLERS[CMD_DRAW_RECTANGLE_ROUNDED] = { words: 9, draw: fillRoundedRectCommand }
COMMAND_HANDLERS[CMD_DRAW_CIRCLE] = { words: 7, draw: fillCircleCommand }
COMMAND_HANDLERS[CMD_DRAW_LINE] = { words: 9, draw: strokeLineCommand }
COMMAND_HANDLERS[CMD_DRAW_RECTANGLE_LINE] = { words: 9, draw: strokeRectangleCommand }
COMMAND_HANDLERS[CMD_DRAW_RECTANGLE_ROUNDED_LINE] = { words: 10, draw: strokeRoundedRectCommand }
COMMAND_HANDLERS[CMD_DRAW_CIRCLE_LINE] = { words: 8, draw: strokeCircleCommand }
COMMAND_HANDLERS[CMD_DRAW_TRIANGLE] = { words: 10, draw: fillTriangleCommand }
COMMAND_HANDLERS[CMD_DRAW_TRIANGLE_LINE] = { words: 11, draw: strokeTriangleCommand }

function ensureCanvas() {
  if (canvas && ctx) return true

  canvas = document.getElementById("canvas")
  if (!canvas) {
    console.error("[canvas_2d] Missing #canvas element")
    return false
  }

  ctx = canvas.getContext("2d")
  if (!ctx) {
    console.error("[canvas_2d] Failed to get 2D context")
    return false
  }

  return true
}

function updateCanvasLayout() {
  if (!canvas) return

  const viewportWidth = Math.max(1, window.innerWidth | 0)
  const viewportHeight = Math.max(1, window.innerHeight | 0)
  canvas.width = viewportWidth
  canvas.height = viewportHeight
  canvasDisplayScale = 1
  targetWidth = viewportWidth
  targetHeight = viewportHeight
}

export function create_canvas_2d_env(getMemory) {
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

      resetDrawState()

      let dataCursor = 0
      for (let cmdIndex = 0; cmdIndex < cmdCount; cmdIndex += 1) {
        const opcode = cmdType[cmdIndex]
        const handler = COMMAND_HANDLERS[opcode]
        if (!handler) {
          console.warn("[canvas_2d] Unknown command", opcode, cmdDataSize[cmdIndex])
          dataCursor += cmdDataSize[cmdIndex]
          continue
        }

        handler.draw(cmdData, dataCursor)
        dataCursor += handler.words
      }
    },
  }
}
