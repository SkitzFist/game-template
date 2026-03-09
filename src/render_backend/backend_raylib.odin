#+build windows,linux
package render_backend

import "core:math"
import rl "vendor:raylib"

// Converters

convert_color :: #force_inline proc(color: Color) -> rl.Color {
	return rl.Color{color.r, color.g, color.b, color.a}
}

convert_vector2i_f :: #force_inline proc(vec2: Vector2I) -> rl.Vector2 {
	return rl.Vector2{f32(vec2.x), f32(vec2.y)}
}

convert_vector2f :: #force_inline proc(vec2: Vector2F) -> rl.Vector2 {
	return rl.Vector2{vec2.x, vec2.y}
}

// WINDOW
init_window :: #force_inline proc(width, height: i32, window_title: cstring) {
	// rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
	rl.InitWindow(width, height, window_title)
	rl.SetTargetFPS(60)
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

@(private = "file")
draw_rectangle_i32 :: #force_inline proc(rect: RectangleI, color: Color) {
	rl.DrawRectangle(rect.x, rect.y, rect.width, rect.height, convert_color(color))
}

@(private = "file")
draw_rectangle_f32 :: #force_inline proc(rect: RectangleF, color: Color) {
	rl.DrawRectangleRec(
		rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
		convert_color(color),
	)
}

draw_rectangle :: proc {
	draw_rectangle_f32,
	draw_rectangle_i32,
}

@(private = "file")
draw_rectangle_rounded_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	color: Color,
) {
	if rect.width <= 0 || rect.height <= 0 {
		return
	}

	min_side := rect.width
	if rect.height < min_side {
		min_side = rect.height
	}

	max_radius := 0.5 * f32(min_side)
	radius := corner_radius
	if radius < 0 {
		radius = 0
	}
	if radius > max_radius {
		radius = max_radius
	}

	if radius == 0 {
		draw_rectangle(rect, color)
		return
	}

	roundness := radius / max_radius
	segments := i32(8)

	rl.DrawRectangleRounded(
		rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
		roundness,
		segments,
		convert_color(color),
	)
}

draw_rectangle_rounded :: proc {
	draw_rectangle_rounded_f32,
	draw_rectangle_rounded_i32,
}

@(private = "file")
draw_circle_i32 :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	rl.DrawCircle(center.x, center.y, radius, convert_color(color))
}

@(private = "file")
draw_circle_f32 :: #force_inline proc(center: Vector2F, radius: f32, color: Color) {
	rl.DrawCircleV(convert_vector2f(center), radius, convert_color(color))
}

draw_circle :: proc {
	draw_circle_f32,
	draw_circle_i32,
}

@(private = "file")
draw_triangle_i32 :: #force_inline proc(v1, v2, v3: Vector2I, color: Color) {
	draw_triangle_f32(convert_vector(v1), convert_vector(v2), convert_vector(v3), color)
}

@(private = "file")
draw_triangle_f32 :: #force_inline proc(v1, v2, v3: Vector2F, color: Color) {
	area2 := (v2.x-v1.x)*(v3.y-v1.y) - (v2.y-v1.y)*(v3.x-v1.x)
	if area2 > 0 {
		rl.DrawTriangle(convert_vector2f(v1), convert_vector2f(v3), convert_vector2f(v2), convert_color(color))
		return
	}

	rl.DrawTriangle(convert_vector2f(v1), convert_vector2f(v2), convert_vector2f(v3), convert_color(color))
}

draw_triangle :: proc {
	draw_triangle_f32,
	draw_triangle_i32,
}

@(private = "file")
draw_line_i32 :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	rl.DrawLineEx(
		convert_vector2i_f(start),
		convert_vector2i_f(end),
		thickness,
		convert_color(color),
	)
}

@(private = "file")
draw_line_f32 :: #force_inline proc(start, end: Vector2F, thickness: f32, color: Color) {
	rl.DrawLineEx(convert_vector2f(start), convert_vector2f(end), thickness, convert_color(color))
}

draw_line :: proc {
	draw_line_f32,
	draw_line_i32,
}

draw_arc_line :: #force_inline proc(
	center_x, center_y, radius, start_angle, end_angle: f32,
	segments: i32,
	thickness: f32,
	color: Color,
) {
	if segments <= 0 || radius <= 0 {
		return
	}

	step := (end_angle - start_angle) / f32(segments)
	prev_angle := start_angle
	prev_x := center_x + radius * f32(math.cos(f64(prev_angle)))
	prev_y := center_y + radius * f32(math.sin(f64(prev_angle)))

	for i: i32 = 1; i <= segments; i += 1 {
		angle := start_angle + step * f32(i)
		next_x := center_x + radius * f32(math.cos(f64(angle)))
		next_y := center_y + radius * f32(math.sin(f64(angle)))

		draw_line(Vector2F{prev_x, prev_y}, Vector2F{next_x, next_y}, thickness, color)

		prev_x = next_x
		prev_y = next_y
	}
}

@(private = "file")
draw_rectangle_line_i32 :: #force_inline proc(rect: RectangleI, thickness: f32, color: Color) {
	draw_rectangle_line_f32(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		thickness,
		color,
	)
}

@(private = "file")
draw_rectangle_line_f32 :: #force_inline proc(rect: RectangleF, thickness: f32, color: Color) {
	if rect.width <= 0 || rect.height <= 0 || thickness <= 0 {
		return
	}

	left := rect.x
	top := rect.y
	right := rect.x + rect.width
	bottom := rect.y + rect.height

	draw_line(Vector2F{left, top}, Vector2F{right, top}, thickness, color)
	draw_line(Vector2F{right, top}, Vector2F{right, bottom}, thickness, color)
	draw_line(Vector2F{right, bottom}, Vector2F{left, bottom}, thickness, color)
	draw_line(Vector2F{left, bottom}, Vector2F{left, top}, thickness, color)
}

draw_rectangle_line :: proc {
	draw_rectangle_line_f32,
	draw_rectangle_line_i32,
}

@(private = "file")
draw_rectangle_rounded_line_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius, thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		thickness,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius, thickness: f32,
	color: Color,
) {
	if rect.width <= 0 || rect.height <= 0 || thickness <= 0 {
		return
	}

	min_side := rect.width
	if rect.height < min_side {
		min_side = rect.height
	}

	radius := corner_radius
	if radius < 0 {
		radius = 0
	}

	max_radius := 0.5 * f32(min_side)
	if radius > max_radius {
		radius = max_radius
	}

	if radius == 0 {
		draw_rectangle_line(rect, thickness, color)
		return
	}

	left := rect.x
	top := rect.y
	right := rect.x + rect.width
	bottom := rect.y + rect.height

	draw_line(Vector2F{left + radius, top}, Vector2F{right - radius, top}, thickness, color)
	draw_line(Vector2F{right, top + radius}, Vector2F{right, bottom - radius}, thickness, color)
	draw_line(Vector2F{right - radius, bottom}, Vector2F{left + radius, bottom}, thickness, color)
	draw_line(Vector2F{left, bottom - radius}, Vector2F{left, top + radius}, thickness, color)

	segment_count := max(i32(radius / 4), 6)

	pi := f32(math.PI)
	draw_arc_line(
		right - radius,
		top + radius,
		radius,
		-pi * 0.5,
		0.0,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		right - radius,
		bottom - radius,
		radius,
		0.0,
		pi * 0.5,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		left + radius,
		bottom - radius,
		radius,
		pi * 0.5,
		pi,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		left + radius,
		top + radius,
		radius,
		pi,
		pi * 1.5,
		segment_count,
		thickness,
		color,
	)
}

draw_rectangle_rounded_line :: proc {
	draw_rectangle_rounded_line_f32,
	draw_rectangle_rounded_line_i32,
}

@(private = "file")
draw_circle_line_i32 :: #force_inline proc(
	center: Vector2I,
	radius, thickness: f32,
	color: Color,
) {
	draw_circle_line_f32(Vector2F{f32(center.x), f32(center.y)}, radius, thickness, color)
}

@(private = "file")
draw_circle_line_f32 :: #force_inline proc(
	center: Vector2F,
	radius, thickness: f32,
	color: Color,
) {
	if radius <= 0 || thickness <= 0 {
		return
	}

	segment_count := max(i32(radius / 3), 24)
	draw_arc_line(
		center.x,
		center.y,
		radius,
		0.0,
		2.0 * f32(math.PI),
		segment_count,
		thickness,
		color,
	)
}

draw_circle_line :: proc {
	draw_circle_line_f32,
	draw_circle_line_i32,
}

@(private = "file")
draw_triangle_line_i32 :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	color: Color,
) {
	draw_triangle_line_f32(convert_vector(v1), convert_vector(v2), convert_vector(v3), thickness, color)
}

@(private = "file")
draw_triangle_line_f32 :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	color: Color,
) {
	if thickness <= 0 {
		return
	}

	draw_line(v1, v2, thickness, color)
	draw_line(v2, v3, thickness, color)
	draw_line(v3, v1, thickness, color)
}

draw_triangle_line :: proc {
	draw_triangle_line_f32,
	draw_triangle_line_i32,
}
