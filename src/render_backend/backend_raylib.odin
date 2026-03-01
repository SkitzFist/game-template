#+build windows,linux
package render_backend

import rl "vendor:raylib"

// WINDOW
init_window :: #force_inline proc(width, height: i32, window_title: cstring) {
	rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
	rl.InitWindow(width, height, window_title)
}

should_close :: #force_inline proc() -> bool {
	return rl.WindowShouldClose()
}

// DRAWING
begin_drawing :: #force_inline proc() {
	rl.BeginDrawing()
}

end_drawing :: #force_inline proc() {
	rl.EndDrawing()
}

clear_background :: #force_inline proc(r, g, b, a: u8) {
	rl.ClearBackground(rl.Color{r, g, b, a})
}

