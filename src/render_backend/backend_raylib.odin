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

	return {pivot.x + dx * c - dy * s, pivot.y + dx * s + dy * c}
}

rotate_local_point_f32 :: #force_inline proc(local_point: Vector2F, rotation: f32) -> Vector2F {
	if rotation == 0 {
		return local_point
	}

	s := f32(math.sin(f64(rotation)))
	c := f32(math.cos(f64(rotation)))
	return {local_point.x * c - local_point.y * s, local_point.x * s + local_point.y * c}
}

transform_local_point_f32 :: #force_inline proc(
	world_pivot, local_point: Vector2F,
	rotation: f32,
) -> Vector2F {
	rotated := rotate_local_point_f32(local_point, rotation)
	return {world_pivot.x + rotated.x, world_pivot.y + rotated.y}
}

resolve_pivot_in_bounds_f32 :: #force_inline proc(
	min_x, min_y, width, height: f32,
	pivot: Vector2F,
) -> Vector2F {
	local_pivot := resolve_rect_pivot(width, height, pivot)
	return {min_x + local_pivot.x, min_y + local_pivot.y}
}

rotate_triangle_f32 :: #force_inline proc(
	v1, v2, v3: Vector2F,
	pivot: Vector2F,
	rotation: f32,
) -> (
	Vector2F,
	Vector2F,
	Vector2F,
) {
	if rotation == 0 {
		return v1, v2, v3
	}

	return rotate_point_f32(
		v1,
		pivot,
		rotation,
	), rotate_point_f32(v2, pivot, rotation), rotate_point_f32(v3, pivot, rotation)
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
	draw_rectangle_i32_rot(rect, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_i32_rot :: #force_inline proc(
	rect: RectangleI,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_f32 :: #force_inline proc(rect: RectangleF, color: Color) {
	draw_rectangle_f32_rot(rect, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_f32_rot :: #force_inline proc(
	rect: RectangleF,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	if rotation == 0 {
		rl.DrawRectangleRec(
			rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
			convert_color(color),
		)
		return
	}

	pivot_world := resolve_pivot_in_bounds_f32(rect.x, rect.y, rect.width, rect.height, pivot)
	p1 := transform_local_point_f32(pivot_world, Vector2F{rect.x - pivot_world.x, rect.y - pivot_world.y}, rotation)
	p2 := transform_local_point_f32(
		pivot_world,
		Vector2F{rect.x + rect.width - pivot_world.x, rect.y - pivot_world.y},
		rotation,
	)
	p3 := transform_local_point_f32(
		pivot_world,
		Vector2F{rect.x + rect.width - pivot_world.x, rect.y + rect.height - pivot_world.y},
		rotation,
	)
	p4 := transform_local_point_f32(
		pivot_world,
		Vector2F{rect.x - pivot_world.x, rect.y + rect.height - pivot_world.y},
		rotation,
	)

	r1 := p1
	r2 := p2
	r3 := p3
	r4 := p4
	area2 := (r2.x - r1.x) * (r3.y - r1.y) - (r2.y - r1.y) * (r3.x - r1.x)
	if area2 > 0 {
		r2, r4 = r4, r2
	}

	fill := convert_color(color)
	rl.DrawTriangle(convert_vector2f(r1), convert_vector2f(r2), convert_vector2f(r3), fill)
	rl.DrawTriangle(convert_vector2f(r1), convert_vector2f(r3), convert_vector2f(r4), fill)
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
		PIVOT_TOP_LEFT,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(rect, corner_radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	rl.DrawRectangleRounded(
		{rect.x, rect.y, rect.width, rect.height},
		0.5,
		8,
		convert_color(color),
	)

	// if rect.width <= 0 || rect.height <= 0 {
	// 	return
	// }

	// min_side := rect.width
	// if rect.height < min_side {
	// 	min_side = rect.height
	// }

	// max_radius := 0.5 * f32(min_side)
	// radius := corner_radius
	// if radius < 0 {
	// 	radius = 0
	// }
	// if radius > max_radius {
	// 	radius = max_radius
	// }

	// if radius == 0 {
	// 	draw_rectangle(rect, color)
	// 	return
	// }

	// roundness := radius / max_radius
	// segments := i32(8)

	// rl.DrawRectangleRounded(
	// 	rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
	// 	roundness,
	// 	segments,
	// 	convert_color(color),
	// )
	// if rotation != 0 {
	// 	_ = pivot
	// }
}

draw_rectangle_rounded :: proc {
	draw_rectangle_rounded_f32,
	draw_rectangle_rounded_f32_rot,
	draw_rectangle_rounded_i32,
	draw_rectangle_rounded_i32_rot,
}

@(private = "file")
draw_circle_i32 :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	draw_circle_i32_rot(center, radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_i32_rot :: #force_inline proc(
	center: Vector2I,
	radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_circle_f32_rot(convert_vector(center), radius, rotation, pivot, color)
}

@(private = "file")
draw_circle_f32 :: #force_inline proc(center: Vector2F, radius: f32, color: Color) {
	draw_circle_f32_rot(center, radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_f32_rot :: #force_inline proc(
	center: Vector2F,
	radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	pivot_world := resolve_pivot_in_bounds_f32(center.x - radius, center.y - radius, radius * 2, radius * 2, pivot)
	rotated_center := transform_local_point_f32(
		pivot_world,
		Vector2F{center.x - pivot_world.x, center.y - pivot_world.y},
		rotation,
	)
	rl.DrawCircleV(convert_vector2f(rotated_center), radius, convert_color(color))
}

draw_circle :: proc {
	draw_circle_f32,
	draw_circle_f32_rot,
	draw_circle_i32,
	draw_circle_i32_rot,
}

@(private = "file")
draw_triangle_i32 :: #force_inline proc(v1, v2, v3: Vector2I, color: Color) {
	draw_triangle_i32_rot(
		v1,
		v2,
		v3,
		0.0,
		normalized_pivot_in_bounds(
			f32(min(v1.x, min(v2.x, v3.x))),
			f32(min(v1.y, min(v2.y, v3.y))),
			f32(max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x))),
			f32(max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y))),
			f32(v1.x + v2.x + v3.x) / 3.0,
			f32(v1.y + v2.y + v3.y) / 3.0,
		),
		color,
	)
}

@(private = "file")
draw_triangle_i32_rot :: #force_inline proc(
	v1, v2, v3: Vector2I,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_triangle_f32_rot(
		convert_vector(v1),
		convert_vector(v2),
		convert_vector(v3),
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_triangle_f32 :: #force_inline proc(v1, v2, v3: Vector2F, color: Color) {
	draw_triangle_f32_rot(
		v1,
		v2,
		v3,
		0.0,
		normalized_pivot_in_bounds(
			min(v1.x, min(v2.x, v3.x)),
			min(v1.y, min(v2.y, v3.y)),
			max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x)),
			max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y)),
			(v1.x + v2.x + v3.x) / 3.0,
			(v1.y + v2.y + v3.y) / 3.0,
		),
		color,
	)
}

@(private = "file")
draw_triangle_f32_rot :: #force_inline proc(
	v1, v2, v3: Vector2F,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	min_x := min(v1.x, min(v2.x, v3.x))
	min_y := min(v1.y, min(v2.y, v3.y))
	bounds_width := max(v1.x, max(v2.x, v3.x)) - min_x
	bounds_height := max(v1.y, max(v2.y, v3.y)) - min_y
	pivot_world := resolve_pivot_in_bounds_f32(min_x, min_y, bounds_width, bounds_height, pivot)
	v1r, v2r, v3r := rotate_triangle_f32(v1, v2, v3, pivot_world, rotation)

	area2 := (v2r.x - v1r.x) * (v3r.y - v1r.y) - (v2r.y - v1r.y) * (v3r.x - v1r.x)
	if area2 > 0 {
		rl.DrawTriangle(
			convert_vector2f(v1r),
			convert_vector2f(v3r),
			convert_vector2f(v2r),
			convert_color(color),
		)
		return
	}

	rl.DrawTriangle(
		convert_vector2f(v1r),
		convert_vector2f(v2r),
		convert_vector2f(v3r),
		convert_color(color),
	)
}

draw_triangle :: proc {
	draw_triangle_f32,
	draw_triangle_f32_rot,
	draw_triangle_i32,
	draw_triangle_i32_rot,
}

@(private = "file")
draw_line_i32 :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	draw_line_i32_rot(start, end, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_line_i32_rot :: #force_inline proc(
	start, end: Vector2I,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_line_f32_rot(
		convert_vector(start),
		convert_vector(end),
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_line_f32 :: #force_inline proc(start, end: Vector2F, thickness: f32, color: Color) {
	draw_line_f32_rot(start, end, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_line_f32_rot :: #force_inline proc(
	start, end: Vector2F,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	if thickness <= 0 {
		return
	}

	min_x := min(start.x, end.x)
	min_y := min(start.y, end.y)
	bounds_width := max(start.x, end.x) - min_x
	bounds_height := max(start.y, end.y) - min_y
	pivot_world := resolve_pivot_in_bounds_f32(min_x, min_y, bounds_width, bounds_height, pivot)
	start_r := transform_local_point_f32(
		pivot_world,
		Vector2F{start.x - pivot_world.x, start.y - pivot_world.y},
		rotation,
	)
	end_r := transform_local_point_f32(
		pivot_world,
		Vector2F{end.x - pivot_world.x, end.y - pivot_world.y},
		rotation,
	)
	rl.DrawLineEx(
		convert_vector2f(start_r),
		convert_vector2f(end_r),
		thickness,
		convert_color(color),
	)
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
	if segments <= 0 || radius <= 0 || thickness <= 0 {
		return
	}

	half_thickness := thickness * 0.5
	inner_radius := max(radius - half_thickness, 0.0)
	outer_radius := radius + half_thickness
	start_deg := start_angle * (180.0 / f32(math.PI))
	end_deg := end_angle * (180.0 / f32(math.PI))

	rl.DrawRing(
		rl.Vector2{center_x, center_y},
		inner_radius,
		outer_radius,
		start_deg,
		end_deg,
		max(segments, 3),
		convert_color(color),
	)
}

@(private = "file")
draw_rectangle_line_i32 :: #force_inline proc(rect: RectangleI, thickness: f32, color: Color) {
	draw_rectangle_line_i32_rot(rect, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_line_i32_rot :: #force_inline proc(
	rect: RectangleI,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_line_f32 :: #force_inline proc(rect: RectangleF, thickness: f32, color: Color) {
	draw_rectangle_line_f32_rot(rect, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_line_f32_rot :: #force_inline proc(
	rect: RectangleF,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	if rect.width <= 0 || rect.height <= 0 || thickness <= 0 {
		return
	}

	left := rect.x
	top := rect.y
	right := rect.x + rect.width
	bottom := rect.y + rect.height
	pivot_world := resolve_pivot_in_bounds_f32(rect.x, rect.y, rect.width, rect.height, pivot)

	p1 := transform_local_point_f32(pivot_world, Vector2F{left - pivot_world.x, top - pivot_world.y}, rotation)
	p2 := transform_local_point_f32(pivot_world, Vector2F{right - pivot_world.x, top - pivot_world.y}, rotation)
	p3 := transform_local_point_f32(
		pivot_world,
		Vector2F{right - pivot_world.x, bottom - pivot_world.y},
		rotation,
	)
	p4 := transform_local_point_f32(pivot_world, Vector2F{left - pivot_world.x, bottom - pivot_world.y}, rotation)

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
		PIVOT_TOP_LEFT,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius, thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius, thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(rect, corner_radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_line_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius, thickness: f32,
	rotation: f32,
	pivot: Vector2F,
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

	roundness := radius / max_radius
	segment_count := max(i32(radius / 2), 8)

	if radius == 0 {
		draw_rectangle_line(rect, thickness, color)
		return
	}

	if rotation == 0 {
		rl.DrawRectangleRoundedLinesEx(
			rl.Rectangle{rect.x, rect.y, rect.width, rect.height},
			roundness,
			segment_count,
			thickness,
			convert_color(color),
		)
		return
	}

	left := rect.x
	top := rect.y
	right := rect.x + rect.width
	bottom := rect.y + rect.height
	pivot_world := resolve_pivot_in_bounds_f32(rect.x, rect.y, rect.width, rect.height, pivot)

	top_start := transform_local_point_f32(pivot_world, Vector2F{left + radius - pivot_world.x, top - pivot_world.y}, rotation)
	top_end := transform_local_point_f32(pivot_world, Vector2F{right - radius - pivot_world.x, top - pivot_world.y}, rotation)
	right_start := transform_local_point_f32(pivot_world, Vector2F{right - pivot_world.x, top + radius - pivot_world.y}, rotation)
	right_end := transform_local_point_f32(pivot_world, Vector2F{right - pivot_world.x, bottom - radius - pivot_world.y}, rotation)
	bottom_start := transform_local_point_f32(pivot_world, Vector2F{right - radius - pivot_world.x, bottom - pivot_world.y}, rotation)
	bottom_end := transform_local_point_f32(pivot_world, Vector2F{left + radius - pivot_world.x, bottom - pivot_world.y}, rotation)
	left_start := transform_local_point_f32(pivot_world, Vector2F{left - pivot_world.x, bottom - radius - pivot_world.y}, rotation)
	left_end := transform_local_point_f32(pivot_world, Vector2F{left - pivot_world.x, top + radius - pivot_world.y}, rotation)

	draw_line_f32(top_start, top_end, thickness, color)
	draw_line_f32(right_start, right_end, thickness, color)
	draw_line_f32(bottom_start, bottom_end, thickness, color)
	draw_line_f32(left_start, left_end, thickness, color)

	pi := f32(math.PI)
	arc1_center := transform_local_point_f32(pivot_world, Vector2F{right - radius - pivot_world.x, top + radius - pivot_world.y}, rotation)
	arc2_center := transform_local_point_f32(pivot_world, Vector2F{right - radius - pivot_world.x, bottom - radius - pivot_world.y}, rotation)
	arc3_center := transform_local_point_f32(pivot_world, Vector2F{left + radius - pivot_world.x, bottom - radius - pivot_world.y}, rotation)
	arc4_center := transform_local_point_f32(pivot_world, Vector2F{left + radius - pivot_world.x, top + radius - pivot_world.y}, rotation)

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
	draw_circle_line_i32_rot(center, radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_line_i32_rot :: #force_inline proc(
	center: Vector2I,
	radius, thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_circle_line_f32_rot(
		Vector2F{f32(center.x), f32(center.y)},
		radius,
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_circle_line_f32 :: #force_inline proc(
	center: Vector2F,
	radius, thickness: f32,
	color: Color,
) {
	draw_circle_line_f32_rot(center, radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_line_f32_rot :: #force_inline proc(
	center: Vector2F,
	radius, thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	if radius <= 0 || thickness <= 0 {
		return
	}

	pivot_world := resolve_pivot_in_bounds_f32(center.x - radius, center.y - radius, radius * 2, radius * 2, pivot)
	rotated_center := transform_local_point_f32(
		pivot_world,
		Vector2F{center.x - pivot_world.x, center.y - pivot_world.y},
		rotation,
	)
	segment_count := max(i32(radius / 3), 24)
	draw_arc_line(
		rotated_center.x,
		rotated_center.y,
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
draw_triangle_line_i32 :: #force_inline proc(v1, v2, v3: Vector2I, thickness: f32, color: Color) {
	draw_triangle_line_i32_rot(
		v1,
		v2,
		v3,
		thickness,
		0.0,
		normalized_pivot_in_bounds(
			f32(min(v1.x, min(v2.x, v3.x))),
			f32(min(v1.y, min(v2.y, v3.y))),
			f32(max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x))),
			f32(max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y))),
			f32(v1.x + v2.x + v3.x) / 3.0,
			f32(v1.y + v2.y + v3.y) / 3.0,
		),
		color,
	)
}

@(private = "file")
draw_triangle_line_i32_rot :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_triangle_line_f32_rot(
		convert_vector(v1),
		convert_vector(v2),
		convert_vector(v3),
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_triangle_line_f32 :: #force_inline proc(v1, v2, v3: Vector2F, thickness: f32, color: Color) {
	draw_triangle_line_f32_rot(
		v1,
		v2,
		v3,
		thickness,
		0.0,
		normalized_pivot_in_bounds(
			min(v1.x, min(v2.x, v3.x)),
			min(v1.y, min(v2.y, v3.y)),
			max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x)),
			max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y)),
			(v1.x + v2.x + v3.x) / 3.0,
			(v1.y + v2.y + v3.y) / 3.0,
		),
		color,
	)
}

@(private = "file")
draw_triangle_line_f32_rot :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	if thickness <= 0 {
		return
	}

	min_x := min(v1.x, min(v2.x, v3.x))
	min_y := min(v1.y, min(v2.y, v3.y))
	bounds_width := max(v1.x, max(v2.x, v3.x)) - min_x
	bounds_height := max(v1.y, max(v2.y, v3.y)) - min_y
	pivot_world := resolve_pivot_in_bounds_f32(min_x, min_y, bounds_width, bounds_height, pivot)
	v1r, v2r, v3r := rotate_triangle_f32(v1, v2, v3, pivot_world, rotation)

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
