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

function clampPivot(value) {
  return Math.min(1, Math.max(0, value))
}

function resolvePivotInBounds(x, y, width, height, pivotX, pivotY) {
  return [
    x + Math.max(0, width) * clampPivot(pivotX),
    y + Math.max(0, height) * clampPivot(pivotY),
  ]
}

function withPivotTransform(ctx, x, y, width, height, pivotX, pivotY, rotation, draw) {
  const [worldPivotX, worldPivotY] = resolvePivotInBounds(x, y, width, height, pivotX, pivotY)
  ctx.save()
  ctx.translate(worldPivotX, worldPivotY)
  ctx.rotate(rotation)
  draw(worldPivotX, worldPivotY)
  ctx.restore()
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
  canvas.width = viewportWidth
  canvas.height = viewportHeight
  canvasDisplayScale = 1
  targetWidth = viewportWidth
  targetHeight = viewportHeight

  // canvas.style.width = `${viewportWidth}px`
  // canvas.style.height = `${viewportHeight}px`
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
          const packed = cmdData[dataCursor + 7]

          ctx.fillStyle = packedToCssColor(packed)
          if (rotation === 0) {
            ctx.fillRect(x, y, width, height)
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 5])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 6])
          withPivotTransform(ctx, x, y, width, height, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.fillRect(x - pivotX, y - pivotY, width, height)
          })
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
          const packed = cmdData[dataCursor + 8]

          const w = Math.max(0, width)
          const h = Math.max(0, height)
          const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))

          ctx.fillStyle = packedToCssColor(packed)
          if (rotation === 0) {
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

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 6])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 7])
          withPivotTransform(ctx, x, y, w, h, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            const left = x - pivotX
            const top = y - pivotY
            const right = left + w
            const bottom = top + h
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
          })

          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_CIRCLE && size >= 7) {
          const centerX = u32BitsToF32(cmdData[dataCursor + 0])
          const centerY = u32BitsToF32(cmdData[dataCursor + 1])
          const radius = u32BitsToF32(cmdData[dataCursor + 2])
          const rotation = u32BitsToF32(cmdData[dataCursor + 3])
          const packed = cmdData[dataCursor + 6]

          ctx.fillStyle = packedToCssColor(packed)
          if (rotation === 0) {
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.fill()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 4])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 5])
          withPivotTransform(ctx, centerX - radius, centerY - radius, radius * 2, radius * 2, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.beginPath()
            ctx.arc(centerX - pivotX, centerY - pivotY, radius, 0, Math.PI * 2)
            ctx.fill()
          })
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
          const packed = cmdData[dataCursor + 8]

          const minX = Math.min(startX, endX)
          const minY = Math.min(startY, endY)
          const width = Math.max(startX, endX) - minX
          const height = Math.max(startY, endY) - minY
          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          if (rotation === 0) {
            ctx.beginPath()
            ctx.moveTo(startX, startY)
            ctx.lineTo(endX, endY)
            ctx.stroke()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 6])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 7])
          withPivotTransform(ctx, minX, minY, width, height, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.beginPath()
            ctx.moveTo(startX - pivotX, startY - pivotY)
            ctx.lineTo(endX - pivotX, endY - pivotY)
            ctx.stroke()
          })
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
          const packed = cmdData[dataCursor + 8]
          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          if (rotation === 0) {
            ctx.strokeRect(x, y, width, height)
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 6])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 7])
          withPivotTransform(ctx, x, y, width, height, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.strokeRect(x - pivotX, y - pivotY, width, height)
          })
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
          const packed = cmdData[dataCursor + 9]

          const w = Math.max(0, width)
          const h = Math.max(0, height)
          const rr = Math.max(0, Math.min(radius, Math.min(w, h) * 0.5))

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          if (rotation === 0) {
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
            ctx.stroke()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 7])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 8])
          withPivotTransform(ctx, x, y, w, h, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            const left = x - pivotX
            const top = y - pivotY
            const right = left + w
            const bottom = top + h
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
          })

          dataCursor += size
          continue
        }

        if (opcode === CMD_DRAW_CIRCLE_LINE && size >= 8) {
          const centerX = u32BitsToF32(cmdData[dataCursor + 0])
          const centerY = u32BitsToF32(cmdData[dataCursor + 1])
          const radius = u32BitsToF32(cmdData[dataCursor + 2])
          const thickness = u32BitsToF32(cmdData[dataCursor + 3])
          const rotation = u32BitsToF32(cmdData[dataCursor + 4])
          const packed = cmdData[dataCursor + 7]

          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          if (rotation === 0) {
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.stroke()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 5])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 6])
          withPivotTransform(ctx, centerX - radius, centerY - radius, radius * 2, radius * 2, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.beginPath()
            ctx.arc(centerX - pivotX, centerY - pivotY, radius, 0, Math.PI * 2)
            ctx.stroke()
          })
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
          const packed = cmdData[dataCursor + 9]

          const minX = Math.min(x1, x2, x3)
          const minY = Math.min(y1, y2, y3)
          const width = Math.max(x1, x2, x3) - minX
          const height = Math.max(y1, y2, y3) - minY
          ctx.fillStyle = packedToCssColor(packed)
          if (rotation === 0) {
            ctx.beginPath()
            ctx.moveTo(x1, y1)
            ctx.lineTo(x2, y2)
            ctx.lineTo(x3, y3)
            ctx.closePath()
            ctx.fill()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 7])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 8])
          withPivotTransform(ctx, minX, minY, width, height, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.beginPath()
            ctx.moveTo(x1 - pivotX, y1 - pivotY)
            ctx.lineTo(x2 - pivotX, y2 - pivotY)
            ctx.lineTo(x3 - pivotX, y3 - pivotY)
            ctx.closePath()
            ctx.fill()
          })
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
          const packed = cmdData[dataCursor + 10]

          const minX = Math.min(x1, x2, x3)
          const minY = Math.min(y1, y2, y3)
          const width = Math.max(x1, x2, x3) - minX
          const height = Math.max(y1, y2, y3) - minY
          ctx.strokeStyle = packedToCssColor(packed)
          ctx.lineWidth = Math.max(0.5, thickness / canvasDisplayScale)
          if (rotation === 0) {
            ctx.beginPath()
            ctx.moveTo(x1, y1)
            ctx.lineTo(x2, y2)
            ctx.lineTo(x3, y3)
            ctx.closePath()
            ctx.stroke()
            dataCursor += size
            continue
          }

          const pivotXNorm = u32BitsToF32(cmdData[dataCursor + 8])
          const pivotYNorm = u32BitsToF32(cmdData[dataCursor + 9])
          withPivotTransform(ctx, minX, minY, width, height, pivotXNorm, pivotYNorm, rotation, (pivotX, pivotY) => {
            ctx.beginPath()
            ctx.moveTo(x1 - pivotX, y1 - pivotY)
            ctx.lineTo(x2 - pivotX, y2 - pivotY)
            ctx.lineTo(x3 - pivotX, y3 - pivotY)
            ctx.closePath()
            ctx.stroke()
          })
          dataCursor += size
          continue
        }

        console.warn("[game_env] Unknown or malformed command", opcode, size)
        dataCursor += size
      }
    },
  }
}
