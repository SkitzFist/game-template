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

rotate_point_f32 :: #force_inline proc(point, pivot: Vector2F, rotation: f32) -> Vector2F {
	if rotation == 0 {
		return point
	}

	s := f32(math.sin(f64(rotation)))
	c := f32(math.cos(f64(rotation)))
	dx := point.x - pivot.x
	dy := point.y - pivot.y

	return {pivot.x + dx*c - dy*s, pivot.y + dx*s + dy*c}
}

rotate_triangle_f32 :: #force_inline proc(v1, v2, v3: Vector2F, rotation: f32) -> (Vector2F, Vector2F, Vector2F) {
	if rotation == 0 {
		return v1, v2, v3
	}

	pivot := Vector2F{(v1.x + v2.x + v3.x) / 3.0, (v1.y + v2.y + v3.y) / 3.0}
	return rotate_point_f32(v1, pivot, rotation), rotate_point_f32(v2, pivot, rotation), rotate_point_f32(v3, pivot, rotation)
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
	draw_rectangle_i32_rot(rect, 0.0, color)
}

@(private = "file")
draw_rectangle_i32_rot :: #force_inline proc(rect: RectangleI, rotation: f32, color: Color) {
	draw_rectangle_f32_rot(RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)}, rotation, color)
}

@(private = "file")
draw_rectangle_f32 :: #force_inline proc(rect: RectangleF, color: Color) {
	draw_rectangle_f32_rot(rect, 0.0, color)
}

@(private = "file")
draw_rectangle_f32_rot :: #force_inline proc(rect: RectangleF, rotation: f32, color: Color) {
	if rotation == 0 {
		rl.DrawRectangleRec(
			rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
			convert_color(color),
		)
		return
	}

	deg := rotation * (180.0 / f32(math.PI))
	origin := rl.Vector2{rect.width * 0.5, rect.height * 0.5}
	rl.DrawRectanglePro(rl.Rectangle{rect.x, rect.y, rect.width, rect.height}, origin, deg, convert_color(color))
}

draw_rectangle :: proc {
	draw_rectangle_f32,
	draw_rectangle_f32_rot,
	draw_rectangle_i32,
	draw_rectangle_i32_rot,
}

@(private = "file")
draw_rectangle_rounded_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		0.0,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	rotation: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		rotation,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(rect, corner_radius, 0.0, color)
}

@(private = "file")
draw_rectangle_rounded_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	rotation: f32,
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
	if rotation == 0 {
		return
	}
}

draw_rectangle_rounded :: proc {
	draw_rectangle_rounded_f32,
	draw_rectangle_rounded_f32_rot,
	draw_rectangle_rounded_i32,
	draw_rectangle_rounded_i32_rot,
}

@(private = "file")
draw_circle_i32 :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	draw_circle_i32_rot(center, radius, 0.0, color)
}

@(private = "file")
draw_circle_i32_rot :: #force_inline proc(center: Vector2I, radius: f32, rotation: f32, color: Color) {
	draw_circle_f32_rot(convert_vector(center), radius, rotation, color)
}

@(private = "file")
draw_circle_f32 :: #force_inline proc(center: Vector2F, radius: f32, color: Color) {
	draw_circle_f32_rot(center, radius, 0.0, color)
}

@(private = "file")
draw_circle_f32_rot :: #force_inline proc(center: Vector2F, radius: f32, rotation: f32, color: Color) {
	_ = rotation
	rl.DrawCircleV(convert_vector2f(center), radius, convert_color(color))
}

draw_circle :: proc {
	draw_circle_f32,
	draw_circle_f32_rot,
	draw_circle_i32,
	draw_circle_i32_rot,
}

@(private = "file")
draw_triangle_i32 :: #force_inline proc(v1, v2, v3: Vector2I, color: Color) {
	draw_triangle_i32_rot(v1, v2, v3, 0.0, color)
}

@(private = "file")
draw_triangle_i32_rot :: #force_inline proc(v1, v2, v3: Vector2I, rotation: f32, color: Color) {
	draw_triangle_f32_rot(convert_vector(v1), convert_vector(v2), convert_vector(v3), rotation, color)
}

@(private = "file")
draw_triangle_f32 :: #force_inline proc(v1, v2, v3: Vector2F, color: Color) {
	draw_triangle_f32_rot(v1, v2, v3, 0.0, color)
}

@(private = "file")
draw_triangle_f32_rot :: #force_inline proc(v1, v2, v3: Vector2F, rotation: f32, color: Color) {
	v1r, v2r, v3r := rotate_triangle_f32(v1, v2, v3, rotation)

	area2 := (v2r.x-v1r.x)*(v3r.y-v1r.y) - (v2r.y-v1r.y)*(v3r.x-v1r.x)
	if area2 > 0 {
		rl.DrawTriangle(convert_vector2f(v1r), convert_vector2f(v3r), convert_vector2f(v2r), convert_color(color))
		return
	}

	rl.DrawTriangle(convert_vector2f(v1r), convert_vector2f(v2r), convert_vector2f(v3r), convert_color(color))
}

draw_triangle :: proc {
	draw_triangle_f32,
	draw_triangle_f32_rot,
	draw_triangle_i32,
	draw_triangle_i32_rot,
}

@(private = "file")
draw_line_i32 :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	draw_line_i32_rot(start, end, thickness, 0.0, color)
}

@(private = "file")
draw_line_i32_rot :: #force_inline proc(start, end: Vector2I, thickness: f32, rotation: f32, color: Color) {
	draw_line_f32_rot(convert_vector(start), convert_vector(end), thickness, rotation, color)
}

@(private = "file")
draw_line_f32 :: #force_inline proc(start, end: Vector2F, thickness: f32, color: Color) {
	draw_line_f32_rot(start, end, thickness, 0.0, color)
}

@(private = "file")
draw_line_f32_rot :: #force_inline proc(start, end: Vector2F, thickness: f32, rotation: f32, color: Color) {
	if thickness <= 0 {
		return
	}

	pivot := Vector2F{(start.x + end.x) * 0.5, (start.y + end.y) * 0.5}
	start_r := rotate_point_f32(start, pivot, rotation)
	end_r := rotate_point_f32(end, pivot, rotation)
	rl.DrawLineEx(convert_vector2f(start_r), convert_vector2f(end_r), thickness, convert_color(color))
}

draw_line :: proc {
	draw_line_f32,
	draw_line_f32_rot,
	draw_line_i32,
	draw_line_i32_rot,
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
	draw_rectangle_line_i32_rot(rect, thickness, 0.0, color)
}

@(private = "file")
draw_rectangle_line_i32_rot :: #force_inline proc(rect: RectangleI, thickness: f32, rotation: f32, color: Color) {
	draw_rectangle_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		thickness,
		rotation,
		color,
	)
}

@(private = "file")
draw_rectangle_line_f32 :: #force_inline proc(rect: RectangleF, thickness: f32, color: Color) {
	draw_rectangle_line_f32_rot(rect, thickness, 0.0, color)
}

@(private = "file")
draw_rectangle_line_f32_rot :: #force_inline proc(rect: RectangleF, thickness: f32, rotation: f32, color: Color) {
	if rect.width <= 0 || rect.height <= 0 || thickness <= 0 {
		return
	}

	left := rect.x
	top := rect.y
	right := rect.x + rect.width
	bottom := rect.y + rect.height

	pivot := Vector2F{(left + right) * 0.5, (top + bottom) * 0.5}
	p1 := rotate_point_f32(Vector2F{left, top}, pivot, rotation)
	p2 := rotate_point_f32(Vector2F{right, top}, pivot, rotation)
	p3 := rotate_point_f32(Vector2F{right, bottom}, pivot, rotation)
	p4 := rotate_point_f32(Vector2F{left, bottom}, pivot, rotation)

	draw_line_f32(p1, p2, thickness, color)
	draw_line_f32(p2, p3, thickness, color)
	draw_line_f32(p3, p4, thickness, color)
	draw_line_f32(p4, p1, thickness, color)
}

draw_rectangle_line :: proc {
	draw_rectangle_line_f32,
	draw_rectangle_line_f32_rot,
	draw_rectangle_line_i32,
	draw_rectangle_line_i32_rot,
}

@(private = "file")
draw_rectangle_rounded_line_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius, thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		thickness,
		0.0,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius, thickness: f32,
	rotation: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		thickness,
		rotation,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius, thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(rect, corner_radius, thickness, 0.0, color)
}

@(private = "file")
draw_rectangle_rounded_line_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius, thickness: f32,
	rotation: f32,
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

	pivot := Vector2F{(left + right) * 0.5, (top + bottom) * 0.5}

	top_start := rotate_point_f32(Vector2F{left + radius, top}, pivot, rotation)
	top_end := rotate_point_f32(Vector2F{right - radius, top}, pivot, rotation)
	right_start := rotate_point_f32(Vector2F{right, top + radius}, pivot, rotation)
	right_end := rotate_point_f32(Vector2F{right, bottom - radius}, pivot, rotation)
	bottom_start := rotate_point_f32(Vector2F{right - radius, bottom}, pivot, rotation)
	bottom_end := rotate_point_f32(Vector2F{left + radius, bottom}, pivot, rotation)
	left_start := rotate_point_f32(Vector2F{left, bottom - radius}, pivot, rotation)
	left_end := rotate_point_f32(Vector2F{left, top + radius}, pivot, rotation)

	draw_line_f32(top_start, top_end, thickness, color)
	draw_line_f32(right_start, right_end, thickness, color)
	draw_line_f32(bottom_start, bottom_end, thickness, color)
	draw_line_f32(left_start, left_end, thickness, color)

	segment_count := max(i32(radius / 4), 6)

	pi := f32(math.PI)
	arc1_center := rotate_point_f32(Vector2F{right - radius, top + radius}, pivot, rotation)
	arc2_center := rotate_point_f32(Vector2F{right - radius, bottom - radius}, pivot, rotation)
	arc3_center := rotate_point_f32(Vector2F{left + radius, bottom - radius}, pivot, rotation)
	arc4_center := rotate_point_f32(Vector2F{left + radius, top + radius}, pivot, rotation)

	draw_arc_line(
		arc1_center.x,
		arc1_center.y,
		radius,
		-pi * 0.5 + rotation,
		0.0 + rotation,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		arc2_center.x,
		arc2_center.y,
		radius,
		0.0 + rotation,
		pi * 0.5 + rotation,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		arc3_center.x,
		arc3_center.y,
		radius,
		pi * 0.5 + rotation,
		pi + rotation,
		segment_count,
		thickness,
		color,
	)
	draw_arc_line(
		arc4_center.x,
		arc4_center.y,
		radius,
		pi + rotation,
		pi * 1.5 + rotation,
		segment_count,
		thickness,
		color,
	)
}

draw_rectangle_rounded_line :: proc {
	draw_rectangle_rounded_line_f32,
	draw_rectangle_rounded_line_f32_rot,
	draw_rectangle_rounded_line_i32,
	draw_rectangle_rounded_line_i32_rot,
}

@(private = "file")
draw_circle_line_i32 :: #force_inline proc(
	center: Vector2I,
	radius, thickness: f32,
	color: Color,
) {
	draw_circle_line_i32_rot(center, radius, thickness, 0.0, color)
}

@(private = "file")
draw_circle_line_i32_rot :: #force_inline proc(
	center: Vector2I,
	radius, thickness: f32,
	rotation: f32,
	color: Color,
) {
	draw_circle_line_f32_rot(Vector2F{f32(center.x), f32(center.y)}, radius, thickness, rotation, color)
}

@(private = "file")
draw_circle_line_f32 :: #force_inline proc(
	center: Vector2F,
	radius, thickness: f32,
	color: Color,
) {
	draw_circle_line_f32_rot(center, radius, thickness, 0.0, color)
}

@(private = "file")
draw_circle_line_f32_rot :: #force_inline proc(
	center: Vector2F,
	radius, thickness: f32,
	rotation: f32,
	color: Color,
) {
	_ = rotation
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
	draw_circle_line_f32_rot,
	draw_circle_line_i32,
	draw_circle_line_i32_rot,
}

@(private = "file")
draw_triangle_line_i32 :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	color: Color,
) {
	draw_triangle_line_i32_rot(v1, v2, v3, thickness, 0.0, color)
}

@(private = "file")
draw_triangle_line_i32_rot :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	rotation: f32,
	color: Color,
) {
	draw_triangle_line_f32_rot(convert_vector(v1), convert_vector(v2), convert_vector(v3), thickness, rotation, color)
}

@(private = "file")
draw_triangle_line_f32 :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	color: Color,
) {
	draw_triangle_line_f32_rot(v1, v2, v3, thickness, 0.0, color)
}

@(private = "file")
draw_triangle_line_f32_rot :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	rotation: f32,
	color: Color,
) {
	if thickness <= 0 {
		return
	}

	v1r, v2r, v3r := rotate_triangle_f32(v1, v2, v3, rotation)

	draw_line(v1r, v2r, thickness, color)
	draw_line(v2r, v3r, thickness, color)
	draw_line(v3r, v1r, thickness, color)
}

draw_triangle_line :: proc {
	draw_triangle_line_f32,
	draw_triangle_line_f32_rot,
	draw_triangle_line_i32,
	draw_triangle_line_i32_rot,
}
