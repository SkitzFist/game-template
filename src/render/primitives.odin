package render

import "core:math"

add_rectangle :: proc(pos, size: [2]f32, color: [4]u8, roundness: f32 = 0.0) {
	append_quad(
		to_clip_space(pos),
		{size.x / render_width * 2, size.y / render_height * 2},
		{size.x * 0.5, size.y * 0.5},
		pack_color(color),
		roundness,
	)
}

add_circle :: proc(pos: [2]f32, radius: f32, color: [4]u8) {
	size: [2]f32 = {
		((radius * 2) / f32(render_width) * 2),
		((radius * 2) / f32(render_height)) * 2,
	}

	pos := to_clip_space(pos)
	pos.x -= size.x / 2
	pos.y += size.y / 2

	append_quad(pos, size, radius, pack_color(color), 1.0)
}

add_triangle :: proc(p1, p2, p3: [2]f32, color: [4]u8) {
	append_triangle(to_clip_space(p1), to_clip_space(p2), to_clip_space(p3), pack_color(color))
}

add_line_points :: proc(p1, p2: [2]f32, thickness: f32, color: [4]u8, roundness: f32 = 0.0) {
	color := pack_color(color)
	dx, dy := p2.x - p1.x, p2.y - p1.y
	d := math.sqrt((dx * dx) + (dy * dy))

	half_length := d / 2
	half_thickness := thickness / 2

	p1 := to_clip_space(p1)
	p2 := to_clip_space(p2)

	offset_x, offset_y: f32
	if d != 0 {
		dx /= d
		dy /= d

		nx, ny := -dy, dx
		offset_x = (nx * half_thickness / f32(render_width)) * 2.0
		offset_y = -(ny * half_thickness / f32(render_height)) * 2.0
	}
	x1a, y1a := p1.x + offset_x, p1.y + offset_y
	vertex_append(Vertex{x1a, y1a, color, {-half_length, half_thickness}, roundness})

	x1b, y1b := p1.x - offset_x, p1.y - offset_y
	vertex_append(Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})

	x2a, y2a := p2.x + offset_x, p2.y + offset_y
	vertex_append(Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})

	x2b, y2b := p2.x - offset_x, p2.y - offset_y
	vertex_append(Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})
	vertex_append(Vertex{x2b, y2b, color, {half_length, -half_thickness}, roundness})
	vertex_append(Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})

}

add_line_direction :: proc(
	point, direction: [2]f32,
	length, thickness: f32,
	color: [4]u8,
	roundness: f32 = 0.0,
) {
	dx, dy := direction.x, direction.y
	d := math.sqrt((dx * dx) + (dy * dy))

	p2 := point
	if d != 0 {
		scale := length / d
		p2 += direction * scale
	}

	add_line_points(point, p2, thickness, color, roundness)
}

add_line :: proc {
	add_line_points,
	add_line_direction,
}
