#+build windows,linux
package render_backend

import rl "vendor:raylib"

// Converters

convert_color :: #force_inline proc(color: Color) -> rl.Color {
	return rl.Color{color.r, color.g, color.b, color.a}
}

convert_vector2i_f :: #force_inline proc(vec2: Vector2I) -> rl.Vector2 {
	return rl.Vector2{f32(vec2.x), f32(vec2.y)}
}

// WINDOW
init_window :: #force_inline proc(width, height: i32, window_title: cstring) {
	// rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
	rl.InitWindow(width, height, window_title)
}

get_window_width :: #force_inline proc() -> i32 {
	return rl.GetRenderWidth()
}

get_window_height :: #force_inline proc() -> i32 {
	return rl.GetRenderHeight()
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

clear_background :: #force_inline proc(color: Color) {
	rl.ClearBackground(convert_color(color))
}

draw_rectangle :: #force_inline proc(rec: Rectangle, color: Color) {
	rl.DrawRectangle(rec.x, rec.y, rec.width, rec.height, convert_color(color))
}

draw_circle :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	rl.DrawCircle(center.x, center.y, radius, convert_color(color))
}

draw_line :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	rl.DrawLineEx(
		convert_vector2i_f(start),
		convert_vector2i_f(end),
		thickness,
		convert_color(color),
	)
}

