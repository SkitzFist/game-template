package opengl

import gl "vendor:OpenGL"

import "core:log"

Vertex :: struct {
	x, y:  f32,
	color: u32,
}

Array_Data :: struct {
	vertexes:        [dynamic]Vertex,
	vbo, vao, count: u32,
	last_drawn:      i32,
	is_dirty:        bool,
}

VERTEX_STRIDE_BYTES :: size_of(Vertex)

basic_vert := #load("../../shaders/basic.vert")
basic_frag := #load("../../shaders/basic.frag")

primitive_solid_shader: u32
primitives: Array_Data

INIT_CAP :: 1_000_000

primitives_init :: proc() {
	// Shader
	primitive_solid_shader = create_shader_u8(basic_vert, basic_frag)

	// Data
	init_array_data(&primitives)
}

primitices_shutdown :: proc() {
	delete(primitives.vertexes)
	gl.DeleteVertexArrays(1, &primitives.vao)
	gl.DeleteBuffers(1, &primitives.vbo)

	gl.DeleteProgram(primitive_solid_shader)
}

init_array_data :: proc(data: ^Array_Data) {
	data.vertexes = make([dynamic]Vertex, 0, INIT_CAP)
	data.vbo = 0
	gl.GenBuffers(1, &data.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(data.vertexes) * size_of(Vertex),
		raw_data(data.vertexes[:]),
		gl.DYNAMIC_DRAW,
	)

	data.vao = 0
	gl.GenVertexArrays(1, &data.vao)
	gl.BindVertexArray(data.vao)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 0)
	gl.VertexAttribPointer(1, 4, gl.UNSIGNED_BYTE, gl.TRUE, VERTEX_STRIDE_BYTES, 2 * size_of(f32))

}

@(private)
pack_color :: proc(color: [4]u8) -> u32 {
	return u32(color[0]) | u32(color[1]) << 8 | u32(color[2]) << 16 | u32(color[3]) << 24
}

@(private)
append_vertex :: proc(
	vertexes: ^[dynamic]Vertex,
	count: ^u32,
	is_dirty: ^bool,
	x, y: f32,
	color: [4]u8,
) {
	packed_color := pack_color(color)

	if int(count^) >= len(vertexes) {
		append_elem(vertexes, Vertex{x = x, y = y, color = packed_color})

		is_dirty^ = true
		count^ += 1
		return
	}

	// TODO keep track of changed indices and only upload that
	if vertexes[count^].x != x ||
	   vertexes[count^].y != y ||
	   vertexes[count^].color != packed_color {
		is_dirty^ = true
	}

	vertexes[count^] = Vertex {
		x     = x,
		y     = y,
		color = packed_color,
	}

	count^ += 1
}

to_clip_space :: proc(x, y: f32) -> (f32, f32) {
	clip_x := (x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (y / f32(render_height)) * 2.0
	return clip_x, clip_y
}

@(private)
add_triangle_screen_space :: proc(p1, p2, p3: [2]f32, color: [4]u8) {
	x1, y1 := to_clip_space(p1.x, p1.y)
	x2, y2 := to_clip_space(p2.x, p2.y)
	x3, y3 := to_clip_space(p3.x, p3.y)

	add_triangle_clip_space(x1, y1, x2, y2, x3, y3, color)
}

@(private)
add_triangle_clip_space :: proc(x1, y1, x2, y2, x3, y3: f32, color: [4]u8) {
	append_vertex(&primitives.vertexes, &primitives.count, &primitives.is_dirty, x1, y1, color)
	append_vertex(&primitives.vertexes, &primitives.count, &primitives.is_dirty, x2, y2, color)
	append_vertex(&primitives.vertexes, &primitives.count, &primitives.is_dirty, x3, y3, color)
}

add_triangle :: proc {
	add_triangle_screen_space,
	add_triangle_clip_space,
}

@(private)
add_rectangle_screen_space :: proc(p, size: [2]f32, color: [4]u8) {
	x, y := to_clip_space(p.x, p.y)
	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2
	add_rectangle_clip_space(x, y, width, height, color)
}

@(private)
add_rectangle_clip_space :: proc(x, y, width, height: f32, color: [4]u8) {

	// *---+ 0
	// |---|
	// +---+
	append_vertex(&primitives.vertexes, &primitives.count, &primitives.is_dirty, x, y, color)

	// +---* 1
	// |---|
	// +---+
	append_vertex(
		&primitives.vertexes,
		&primitives.count,
		&primitives.is_dirty,
		x + width,
		y,
		color,
	)

	// +---+ 2
	// |---|
	// *---+
	append_vertex(
		&primitives.vertexes,
		&primitives.count,
		&primitives.is_dirty,
		x,
		y - height,
		color,
	)

	// +---+ 2
	// |---|
	// *---+
	append_vertex(
		&primitives.vertexes,
		&primitives.count,
		&primitives.is_dirty,
		x,
		y - height,
		color,
	)

	// +---* 1
	// |---|
	// +---+
	append_vertex(
		&primitives.vertexes,
		&primitives.count,
		&primitives.is_dirty,
		x + width,
		y,
		color,
	)

	// +---+ 3
	// |---|
	// +---*
	append_vertex(
		&primitives.vertexes,
		&primitives.count,
		&primitives.is_dirty,
		x + width,
		y - height,
		color,
	)
}

add_rectangle :: proc {
	add_rectangle_screen_space,
	add_rectangle_clip_space,
}


// TODO make shader/style as a parameter, maybe?
draw_primitives :: proc(count: i32) {
	gl.UseProgram(primitive_solid_shader)
	gl.BindBuffer(gl.ARRAY_BUFFER, primitives.vbo)
	gl.BindVertexArray(primitives.vao)

	vertex_count := count * 3

	log.info("primitives:", vertex_count / 3)

	gl.DrawArrays(gl.TRIANGLES, primitives.last_drawn, vertex_count)
	primitives.last_drawn += vertex_count
}


data_to_gpu :: proc() {
	if primitives.is_dirty {
		log.info("[OPENGL] primitives dirty. uploading to gpu")
		gl.BindBuffer(gl.ARRAY_BUFFER, primitives.vbo)
		gl.BufferData(
			gl.ARRAY_BUFFER,
			int(primitives.count) * size_of(Vertex),
			raw_data(primitives.vertexes[:primitives.count]),
			gl.DYNAMIC_DRAW,
		)
	}
}

