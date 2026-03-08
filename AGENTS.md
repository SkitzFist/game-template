# Rendering Backend Development Guide

This document describes how to work in this repository's rendering layer and how to add new drawing functions safely across platforms.

## Architecture

- The shared rendering package is `src/render_backend`.
- Common API types and colors live in `src/render_backend/api.odin`.
- Game code calls the backend through `import be "render_backend"` (see `src/main.odin`).
- Backend implementations live behind one shared API surface:
  - `src/render_backend/backend_raylib.odin` for native targets.
  - `src/render_backend/backend_web.odin` for wasm/web targets.
- Web rendering is command-buffer driven and decoded in `src/web/game_env.js`.

As new backends are added, keep this pattern: one shared public API, with backend-specific implementation details isolated per backend file/module.

## Main Rendering Flow (Backend-Agnostic)

1. `begin_drawing()` starts a frame.
2. Game code issues draw procedures (`draw_rectangle`, `draw_circle`, etc.).
3. `end_drawing()` presents the frame.

This high-level flow should stay the same for every backend.

## Backend-Specific Flow Details

### Raylib Backend (Native)

- File: `src/render_backend/backend_raylib.odin`
- Draw procedures execute immediately against raylib.
- No command buffering layer is required.

### Web Backend (WASM)

- File: `src/render_backend/backend_web.odin`
- Draw procedures append packed commands to buffers.
- `end_drawing()` submits command buffers to JS.
- `src/web/game_env.js` decodes and executes canvas draw operations.

### Future Backends

- Preserve the same public Odin API used by game code.
- Implement backend-specific execution in that backend's module.
- If a backend needs translation/transport (like command buffers), keep that logic local to that backend.
- Keep visual behavior and argument semantics aligned with existing backends.

## Required API Rules For New Drawing Procedures

1. Every new drawing procedure must provide both variants:
   - `*_i32`
   - `*_f32`
2. Expose a single overloaded public name:
   - `draw_foo :: proc { draw_foo_f32, draw_foo_i32 }`
3. Prefer shared API structs from `src/render_backend/api.odin` in public signatures:
   - Positions: `Vector2I` / `Vector2F`
   - Rectangles: `RectangleI` / `RectangleF`
   - Colors: `Color`
4. Do not introduce public tuple scalar coordinates like `(x, y: i32)` when a vector/rectangle type fits.
   - Use `pos: Vector2I` instead of `(x, y: i32)`.

## Function Naming And Signature Conventions

- Concrete implementations use suffixes `_i32` and `_f32`.
- The unsuffixed name is the overload group exposed to callers.
- Keep parameter order and semantics identical between i32/f32 variants.
- Keep signatures aligned across native and web backends.

## How To Implement A New Drawing Procedure

1. **Define shared public API shape first**
   - Add `draw_foo_f32` and `draw_foo_i32`.
   - Add the overload group `draw_foo :: proc { draw_foo_f32, draw_foo_i32 }`.
   - Use `Vector2*`, `Rectangle*`, and `Color` from `src/render_backend/api.odin` where applicable.

2. **Implement per backend**

   **Raylib backend (`backend_raylib.odin`)**
   - Call raylib directly or reuse existing helpers.
   - i32 variant may convert to f32 and forward if appropriate.

   **Web backend (`backend_web.odin`)**
   - Add a new command type entry.
   - Pack all required arguments into command buffers.
   - Ensure `end_drawing()` submits these values.

3. **Implement any backend-side decoder/bridge if needed**
   - Add the matching command handler in `src/web/game_env.js`.
   - Decode arguments in the exact order they were packed.
   - Execute equivalent canvas drawing behavior.

4. **Verify parity across all backends**
   - Outputs should match as closely as possible.
   - Both variants (`_i32`, `_f32`) should compile and be callable from `be.draw_foo` on every supported backend.

## New Backend Bootstrap Checklist

When adding backend #3 (or later), use this quick start checklist.

1. **Create backend module and target config**
   - Add a new backend file under `src/render_backend` (for example, `backend_<name>.odin`).
   - Ensure build tags/platform selection include the new backend for the intended target.
   - Keep exported procedure names and signatures identical to existing backends.

2. **Implement required lifecycle procedures first**
   - `init_window`
   - `get_window_width`
   - `get_window_height`
   - `should_close`
   - `begin_drawing`
   - `end_drawing`
   - `clear_background`

3. **Implement all current draw procedures with parity**
   - Implement every existing public draw procedure in the new backend.
   - Preserve i32/f32 pair pattern (`*_i32`, `*_f32`, unsuffixed overload group).
   - Reuse `Vector2*`, `Rectangle*`, and `Color` from `src/render_backend/api.odin`.

4. **Add transport/bridge layer only if needed**
   - If the backend is immediate mode, keep calls direct in Odin.
   - If it requires command/IPC/event transport, isolate that packing/decoding to backend-specific files.
   - Keep wire formats stable and argument order explicit.

5. **Verify backend parity before merging**
   - Build succeeds for native and all web/other targets.
   - Visual output and semantics match existing backends for representative scenes.
   - No backend-specific API drift leaks into game code (`src/main.odin` remains backend-agnostic).

## Checklist Before Finishing

- [ ] Added both i32 and f32 variants.
- [ ] Added overload group with unsuffixed name.
- [ ] Used `Vector2*` / `Rectangle*` / `Color` where applicable.
- [ ] Updated every currently supported backend implementation.
- [ ] Updated any required backend bridge/decoder layer (for web: `src/web/game_env.js`).
- [ ] Verified build/run on each supported target.

## Commit Message Style

Use a hybrid format: category prefix + Conventional Commits.

Format:

- `[CATEGORY] <type>: <subject>`

Guidelines:

- `CATEGORY` is uppercase and scoped to the area changed (for example: `AI`, `WEB`, `RENDER`, `CORE`).
- `<type>` follows Conventional Commits (for example: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`).
- Keep `<subject>` short and imperative.
- For multi-part changes, include a body with concise bullet points describing key deltas.
- For breaking changes, mark them explicitly using Conventional Commits:
  - Add `!` after type/scope in the header (example: `[RENDER] feat!: change draw API signatures`).
  - Add a footer line: `BREAKING CHANGE: <what changed and required migration>`.
- If an AI agent creates the commit, add an AI co-author trailer to the commit message.

AI co-author trailer:

- `Co-authored-by: OpenCode <opencode@local.agent>`

Examples:

- `[AI] feat: add agentic instructions`

```text
[WEB] chore: refactor odin_env

* break out into separate file
* extend with math instruction
```
