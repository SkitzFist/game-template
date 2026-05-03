package opengl

import gl "vendor:OpenGL"

import "core:math"

import "core:log"

@(private = "file")
Vertex :: struct {
	x, y:   f32,
	color:  u32,
	local:  [2]f32,
	radius: f32,
}

@(private = "file")
Array_Data :: struct {
	vertexes:        [dynamic]Vertex,
	vbo, vao, count: u32,
	last_drawn:      i32,
	is_dirty:        bool,
}

@(private = "file")
VERTEX_STRIDE_BYTES :: size_of(Vertex)

primitives_vert := #load("../../shaders/primitives.vert")
primitives_frag := #load("../../shaders/primitives.frag")

primitives_shader: u32

INIT_CAP :: 1_000_000
primitives: Array_Data

NONE_HALF: [2]f32 : {0, 0}

primitives_init :: proc() {
	primitives_shader = create_shader_u8(primitives_vert, primitives_frag)

	init_array_data(&primitives)
}

primitives_shutdown :: proc() {
	delete(primitives.vertexes)
	gl.DeleteVertexArrays(1, &primitives.vao)
	gl.DeleteBuffers(1, &primitives.vbo)

	gl.DeleteProgram(primitives_shader)
}

@(private = "file")
init_array_data :: proc(data: ^Array_Data) {
	data.vertexes = make([dynamic]Vertex, 0, INIT_CAP)

	gl.GenBuffers(1, &data.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

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

pack_color :: proc(color: [4]u8) -> u32 {
	return u32(color[0]) | u32(color[1]) << 8 | u32(color[2]) << 16 | u32(color[3]) << 24
}

to_clip_space :: proc(x, y: f32) -> (f32, f32) {
	clip_x := (x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (y / f32(render_height)) * 2.0
	return clip_x, clip_y
}

@(private = "file")
append_vertex :: proc(data: ^Array_Data, vertex: Vertex) {

	if int(data.count) >= len(data.vertexes) {
		append_elem(&data.vertexes, vertex)
		data.is_dirty = true
		data.count += 1
		return
	}

	// TODO keep track of changed indices and only upload that
	// TODO option to opt out and always mark dirty
	if data.vertexes[data.count].x != vertex.x ||
	   data.vertexes[data.count].y != vertex.y ||
	   data.vertexes[data.count].color != vertex.color ||
	   data.vertexes[data.count].local != vertex.local ||
	   data.vertexes[data.count].radius != vertex.radius {
		data.is_dirty = true
	}

	data.vertexes[data.count] = vertex
	data.count += 1
}

add_rectangle_screen_space :: proc(pos, size: [2]f32, color: [4]u8) {
	x, y := to_clip_space(pos.x, pos.y)
	append_rectangle_vertexes(x, y, size, 0, NONE_HALF, pack_color(color))
}

add_rectangle_clip_space :: proc(x, y, width, height: f32, color: [4]u8) {
	append_rectangle_vertexes(x, y, {width, height}, 0, NONE_HALF, pack_color(color))
}

add_rectangle :: proc {
	add_rectangle_screen_space,
	add_rectangle_clip_space,
}

add_rectangle_rounded_screen_space :: proc(pos, size: [2]f32, radius: f32, color: [4]u8) {
	x, y := to_clip_space(pos.x, pos.y)
	add_rectangle_rounded_clip_space(x, y, size, radius, color)
}

add_rectangle_rounded_clip_space :: proc(x, y: f32, size: [2]f32, radius: f32, color: [4]u8) {

	// world space
	half_w, half_h := size.x / 2, size.y / 2
	append_rectangle_vertexes(x, y, size, radius, {half_w, half_h}, pack_color(color))
}

add_rectangle_rounded :: proc {
	add_rectangle_rounded_screen_space,
	add_rectangle_rounded_clip_space,
}

@(private = "file")
append_rectangle_vertexes :: #force_inline proc(
	x, y: f32,
	size: [2]f32,
	radius: f32,
	half: [2]f32,
	color: u32,
) {

	// clip_space
	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2

	// *---+ 0
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x, y, color, {-half.x, half.y}, radius})

	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x + width, y, color, {half.x, half.y}, radius})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(&primitives, Vertex{x, y - height, color, {-half.x, -half.y}, radius})
	append_vertex(&primitives, Vertex{x, y - height, color, {-half.x, -half.y}, radius})


	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x + width, y, color, {half.x, half.y}, radius})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(&primitives, Vertex{x + width, y - height, color, {half.x, -half.y}, radius})
}

add_circle_screen_space :: proc(pos: [2]f32, radius: f32, color: [4]u8) {
	x, y := to_clip_space(pos.x, pos.y)
	add_circle_clip_space(x, y, radius, color)
}

add_circle_clip_space :: proc(x, y, radius: f32, color: [4]u8) {

	// clip_space
	width, height :=
		((radius * 2) / f32(render_width) * 2), ((radius * 2) / f32(render_height)) * 2
	// world space
	half_w, half_h := radius, radius
	// x, y := x + radius, y + radius
	color := pack_color(color)

	x, y := x - (width / 2), y + (height / 2)

	// *---+ 0
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x, y, color, {-half_w, half_h}, 1.0})

	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x + width, y, color, {half_w, half_h}, 1.0})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(&primitives, Vertex{x, y - height, color, {-half_w, -half_h}, 1.0})
	append_vertex(&primitives, Vertex{x, y - height, color, {-half_w, -half_h}, 1.0})


	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives, Vertex{x + width, y, color, {half_w, half_h}, 1.0})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(&primitives, Vertex{x + width, y - height, color, {half_w, -half_h}, 1.0})
}

add_circle :: proc {
	add_circle_screen_space,
	add_circle_clip_space,
}

add_triangle_world_space :: proc(p1, p2, p3: [2]f32, color: [4]u8) {
	x1, y1 := to_clip_space(p1.x, p1.y)
	x2, y2 := to_clip_space(p2.x, p2.y)
	x3, y3 := to_clip_space(p3.x, p3.y)

	add_triangle_clip_space(x1, y1, x2, y2, x3, y3, color)
}

add_triangle_clip_space :: proc(x1, y1, x2, y2, x3, y3: f32, color: [4]u8) {
	color := pack_color(color)

	append_vertex(&primitives, Vertex{x1, y1, color, NONE_HALF, 0})
	append_vertex(&primitives, Vertex{x2, y2, color, NONE_HALF, 0})
	append_vertex(&primitives, Vertex{x3, y3, color, NONE_HALF, 0})
}

add_triangle :: proc {
	add_triangle_world_space,
	add_triangle_clip_space,
}

add_line_screen_space :: proc(p1, p2: [2]f32, thickness: f32, color: [4]u8, roundness: f32 = 0) {
	x1, y1 := to_clip_space(p1.x, p1.y)
	x2, y2 := to_clip_space(p2.x, p2.y)
	add_line_clip_space(x1, y1, x2, y2, thickness, color, roundness)
}


add_line_clip_space :: proc(x1, y1, x2, y2, thickness: f32, color: [4]u8, roundness: f32 = 0) {
	color := pack_color(color)

	p1_base: [2]f32 = {(x1 + 1.0) * 0.5 * f32(render_width), (1.0 - y1) * 0.5 * f32(render_height)}
	p2_base: [2]f32 = {(x2 + 1.0) * 0.5 * f32(render_width), (1.0 - y2) * 0.5 * f32(render_height)}

	dx, dy := p2_base.x - p1_base.x, p2_base.y - p1_base.y
	d := math.sqrt((dx * dx) + (dy * dy))
	dx /= d
	dy /= d

	n: [2]f32 = {-dy, dx}

	half_length := d / 2
	half_thickness := thickness / 2

	p1 := p1_base + n * half_thickness
	x1a, y1a := to_clip_space(p1.x, p1.y)
	append_vertex(&primitives, Vertex{x1a, y1a, color, {-half_length, half_thickness}, roundness})

	p2 := p1_base - n * half_thickness
	x1b, y1b := to_clip_space(p2.x, p2.y)
	append_vertex(&primitives, Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})

	p3 := p2_base + n * half_thickness
	x2a, y2a := to_clip_space(p3.x, p3.y)
	append_vertex(&primitives, Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})

	p4 := p2_base - n * half_thickness
	x2b, y2b := to_clip_space(p4.x, p4.y)
	append_vertex(&primitives, Vertex{x1b, y1b, color, {-half_length, -half_thickness}, roundness})
	append_vertex(&primitives, Vertex{x2b, y2b, color, {half_length, -half_thickness}, roundness})
	append_vertex(&primitives, Vertex{x2a, y2a, color, {half_length, half_thickness}, roundness})
}

add_line :: proc {
	add_line_screen_space,
	add_line_clip_space,
}

draw_primitives :: proc(count: i32) {
	gl.UseProgram(primitives_shader)
	gl.BindBuffer(gl.ARRAY_BUFFER, primitives.vbo)
	gl.BindVertexArray(primitives.vao)

	vertex_count := count * 3
	log.info("primitives:", vertex_count / 3)
	gl.DrawArrays(gl.TRIANGLES, primitives.last_drawn, vertex_count)
	primitives.last_drawn += vertex_count
}

@(private)
primitives_data_to_gpu :: proc() {
	if primitives.is_dirty {
		log.info("[OPENGL] primitives dirty, uploading to gpu")
		gl.BindBuffer(gl.ARRAY_BUFFER, primitives.vbo)
		gl.BufferData(
			gl.ARRAY_BUFFER,
			int(primitives.count) * size_of(Vertex),
			raw_data(primitives.vertexes[:primitives.count]),
			gl.DYNAMIC_DRAW,
		)
	}
}

