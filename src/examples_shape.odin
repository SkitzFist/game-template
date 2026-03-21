package game

import be "render_backend"

examples_shape_draw :: proc() {

	THICKNESS :: 5.0
	ROUNDNESS :: 20.0
	padding :: 50
	size := (be.get_window_width() - padding * 6) / 4
	rect: be.RectangleI = {padding, padding, size, size}

	be.draw_rectangle(rect, be.BLUE)

	rect.x += size + padding
	be.draw_rectangle_line(rect, THICKNESS, be.BLUE)

	rect.x += size + padding
	be.draw_rectangle_rounded(rect, ROUNDNESS, be.BLUE)

	rect.x += size + padding
	be.draw_rectangle_rounded_line(rect, ROUNDNESS * 4, 5.0, be.BLUE)
	inside_rect: be.RectangleI = {rect.x + size / 4, rect.y + size / 4, size / 2, size / 2}
	be.draw_rectangle_rounded_line(inside_rect, ROUNDNESS * 2, THICKNESS, be.GREEN)

	rect.y += rect.height + padding
	rect.x = padding
	be.draw_triangle(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		be.Vector2I{rect.x, rect.y + rect.height},
		be.BLUE,
	)

	rect.x += size + padding
	be.draw_triangle_line(
		be.Vector2I{rect.x, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y},
		be.Vector2I{rect.x + rect.width, rect.y + rect.height},
		THICKNESS,
		be.BLUE,
	)

	rect.y += rect.height + padding
	rect.x = padding
	be.draw_circle(
		be.Vector2I{rect.x + rect.width / 2, rect.y + rect.height / 2},
		f32(rect.width / 2),
		be.BLUE,
	)

	rect.x += size + padding
	be.draw_circle_line(
		be.Vector2I{rect.x + rect.width / 2, rect.y + rect.height / 2},
		f32(rect.width / 2),
		THICKNESS,
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

