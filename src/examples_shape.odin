package game

import "core:math"
import be "render_backend"

examples_shape_draw :: proc() {

	THICKNESS :: 5.0
	ROUNDNESS :: 20.0
	padding :: 50
	size_x := (be.get_window_width() - padding * 6) / 4
	size_y := (be.get_window_height() - padding * 6) / 4
	rect: be.RectangleI = {padding, padding, size_x, size_y}

	be.draw_rectangle(rect, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_line(rect, THICKNESS, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_rounded(rect, ROUNDNESS, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_rounded_line(rect, ROUNDNESS * 4, 5.0, be.BLUE)
	inside_rect: be.RectangleI = {rect.x + size_x / 4, rect.y + size_y / 4, size_x / 2, size_y / 2}
	be.draw_rectangle_rounded_line(inside_rect, ROUNDNESS * 2, THICKNESS, be.GREEN)

	rect.y += rect.height + padding
	rect.x = padding
	be.draw_triangle(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		be.Vector2I{rect.x, rect.y + rect.height},
		be.BLUE,
	)

	rect.x += size_x + padding
	be.draw_triangle_line(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		THICKNESS,
		be.BLUE,
	)

	circle_radius := f32((rect.width / 2 + rect.height / 2) / 2)
	rect.y += rect.height + padding
	rect.x = padding
	be.draw_circle(
		be.Vector2I{rect.x + i32(circle_radius), rect.y + i32(circle_radius)},
		circle_radius,
		be.BLUE,
	)

	rect.x += rect.width + padding
	be.draw_circle_line(
		be.Vector2I{rect.x + i32(circle_radius), rect.y + i32(circle_radius)},
		circle_radius,
		THICKNESS,
		be.BLUE,
	)

}


acc: f32

examples_shape_rotation_draw :: proc(dt: f32) {

	THICKNESS :: 5.0
	ROUNDNESS :: 20.0
	padding :: 50
	size_x := (be.get_window_width() - padding * 6) / 4
	size_y := (be.get_window_height() - padding * 5) / 3
	rect: be.RectangleI = {padding, padding, size_x, size_y}

	acc += dt
	rotation: f32 = 0 + math.sin(acc * 0.5) * math.PI
	rect_pivot := be.PIVOT_CENTER

	be.draw_rectangle(rect, rotation, rect_pivot, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_line(rect, THICKNESS, rotation, rect_pivot, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_rounded(rect, ROUNDNESS, rotation, rect_pivot, be.BLUE)

	rect.x += size_x + padding
	be.draw_rectangle_rounded_line(rect, ROUNDNESS * 4, THICKNESS, rotation, rect_pivot, be.BLUE)
	inside_rect: be.RectangleI = {rect.x + size_x / 4, rect.y + size_y / 4, size_x / 2, size_y / 2}
	be.draw_rectangle_rounded_line(
		inside_rect,
		ROUNDNESS * 2,
		THICKNESS,
		rotation,
		be.PIVOT_CENTER,
		be.GREEN,
	)

	rect.y += rect.height + padding
	rect.x = padding
	triangle_pivot := be.Vector2F{0.333, 0.667}
	be.draw_triangle(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		be.Vector2I{rect.x, rect.y + rect.height},
		rotation,
		triangle_pivot,
		be.BLUE,
	)

	rect.x += size_x + padding
	triangle_line_pivot := be.Vector2F{0.667, 0.333}
	be.draw_triangle_line(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		THICKNESS,
		rotation,
		triangle_line_pivot,
		be.BLUE,
	)

	circle_radius := f32((rect.width / 2 + rect.height / 2) / 2)
	circle_pivot := be.PIVOT_CENTER
	rect.y += rect.height + padding
	rect.x = padding
	be.draw_circle(
		be.Vector2I{rect.x + i32(circle_radius), rect.y + i32(circle_radius)},
		circle_radius,
		rotation,
		circle_pivot,
		be.BLUE,
	)

	rect.x += rect.width + padding
	be.draw_circle_line(
		be.Vector2I{rect.x + i32(circle_radius), rect.y + i32(circle_radius)},
		circle_radius,
		THICKNESS,
		rotation,
		circle_pivot,
		be.BLUE,
	)

}

examples_arc_line :: proc(dt: f32) {

	center_x: f32 = f32(be.get_window_width() / 2)
	center_y: f32 = f32(be.get_window_height() / 2)
	radius: f32 = f32(be.get_window_width() / 4)
	start_angle: f32 = 0.0
	end_angle: f32 = -3.14
	segments: i32 = 64
	thickness: f32 = 10.0

	// be.draw_arc_line(
	// 	center_x,
	// 	center_y,
	// 	radius,
	// 	start_angle,
	// 	end_angle,
	// 	segments,
	// 	thickness,
	// 	be.BLUE,
	// )
}

