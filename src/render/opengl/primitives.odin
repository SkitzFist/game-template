package opengl

import gl "vendor:OpenGL"

import "core:math"

Primitives :: struct {
	vao: u32,
}

// TODO refactor shader
primitives_vert := #load("../../shaders/primitives.vert")
primitives_frag := #load("../../shaders/primitives.frag")
primitives_shader: u32

primitives: Primitives

NONE_HALF: [2]f32 : {0, 0}

primitives_init :: proc() {
	primitives_shader = create_shader_u8(primitives_vert, primitives_frag)
	init_array_data(&primitives)
}

primitives_shutdown :: proc() {
	gl.DeleteVertexArrays(1, &primitives.vao)
	gl.DeleteProgram(primitives_shader)
}

@(private = "file")
init_array_data :: proc(data: ^Primitives) {
	gl.GenVertexArrays(1, &data.vao)
	gl.BindVertexArray(data.vao)

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)

	pointer: uintptr = 0

	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 0)
	pointer += 2 * size_of(f32)

	gl.VertexAttribPointer(1, 4, gl.UNSIGNED_BYTE, gl.TRUE, VERTEX_STRIDE_BYTES, pointer)
	pointer += 1 * size_of(u32)

	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, pointer)
	pointer += 2 * size_of(f32)

	gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, pointer)

}

// TODO refactor to other place
pack_color :: proc(color: [4]u8) -> u32 {
	return u32(color[0]) | u32(color[1]) << 8 | u32(color[2]) << 16 | u32(color[3]) << 24
}

// TODO refactor to other place
to_clip_space :: proc(x, y: f32) -> (f32, f32) {
	clip_x := (x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (y / f32(render_height)) * 2.0
	return clip_x, clip_y
}

add_rectangle :: proc(pos, size: [2]f32, color: [4]u8, roundness: f32 = 0.0) {
	color := pack_color(color)
	x, y := to_clip_space(pos.x, pos.y)

	// world space
	half_w, half_h := size.x / 2, size.y / 2

	// clip_space
	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2

	// *---+ 0
	// |---|
	// +---+
	append_vertex(Vertex{x, y, color, {-half_w, half_h}, roundness})

	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {half_w, half_h}, roundness})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(Vertex{x, y - height, color, {-half_w, -half_h}, roundness})
	append_vertex(Vertex{x, y - height, color, {-half_w, -half_h}, roundness})


	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {half_w, half_h}, roundness})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(Vertex{x + width, y - height, color, {half_w, -half_h}, roundness})
}

add_circle :: proc(pos: [2]f32, roundness: f32, color: [4]u8) {
	color := pack_color(color)

	width, height :=
		((roundness * 2) / f32(render_width) * 2), ((roundness * 2) / f32(render_height)) * 2
	half_w, half_h := roundness, roundness

	x, y := to_clip_space(pos.x, pos.y)
	x, y = x - (width / 2), y + (height / 2)

	// *---+ 0
	// |---|
	// +---+
	append_vertex(Vertex{x, y, color, {-half_w, half_h}, 1.0})

	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {half_w, half_h}, 1.0})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(Vertex{x, y - height, color, {-half_w, -half_h}, 1.0})
	append_vertex(Vertex{x, y - height, color, {-half_w, -half_h}, 1.0})


	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {half_w, half_h}, 1.0})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(Vertex{x + width, y - height, color, {half_w, -half_h}, 1.0})
}

add_triangle :: proc(p1, p2, p3: [2]f32, color: [4]u8) {
	color := pack_color(color)

	x1, y1 := to_clip_space(p1.x, p1.y)
	append_vertex(Vertex{x1, y1, color, NONE_HALF, 0})

	x2, y2 := to_clip_space(p2.x, p2.y)
	append_vertex(Vertex{x2, y2, color, NONE_HALF, 0})

	x3, y3 := to_clip_space(p3.x, p3.y)
	append_vertex(Vertex{x3, y3, color, NONE_HALF, 0})
}

add_line :: proc(p1, p2: [2]f32, thickness: f32, color: [4]u8, roundness: f32 = 0) {
	color := pack_color(color)

	dx, dy := p2.x - p1.x, p2.y - p1.y
	d := math.sqrt((dx * dx) + (dy * dy))
	if d == 0 {
		panic("Line length is 0")
	}

	dx /= d
	dy /= d

	n: [2]f32 = {-dy, dx}

	half_length := d / 2
	half_thickness := thickness / 2

	p1a := p1 + n * half_thickness
	x1a, y1a := to_clip_space(p1a.x, p1a.y)
	append_vertex(Vertex{x1a, y1a, color, {-half_length, half_thickness}, roundness})

	p1b := p1 - n * half_thickness
	x1b, y1b := to_clip_space(p1b.x, p1b.y)
	append_vertex(Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})

	p2a := p2 + n * half_thickness
	x2a, y2a := to_clip_space(p2a.x, p2a.y)
	append_vertex(Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})

	p2b := p2 - n * half_thickness
	x2b, y2b := to_clip_space(p2b.x, p2b.y)
	append_vertex(Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})
	append_vertex(Vertex{x2b, y2b, color, {half_length, -half_thickness}, roundness})
	append_vertex(Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})
}

draw_primitives :: proc(count: i32) {
	// TODO should always check what previous used shader/vao is, and only switch if different
	gl.UseProgram(primitives_shader)
	gl.BindVertexArray(primitives.vao)

	// three vertexes per triangle
	vertex_count := count * 3
	// log.info("primitives:", vertex_count / 3)
	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
	last_drawn += vertex_count
}

