package opengl

import gl "vendor:OpenGL"

vertexes: [dynamic]f32
vbo, vao: u32
primitive_solid_shader: u32

VERTEX_FLOATS_PER_VERTEX :: 6
VERTEX_STRIDE_BYTES :: VERTEX_FLOATS_PER_VERTEX * size_of(f32)

basic_vert := #load("../../shaders/basic.vert")
basic_frag := #load("../../shaders/basic.frag")

init_primitives :: proc() {
	vertexes = make([dynamic]f32, 0, 1000000)
	vbo = 0
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertexes) * size_of(f32),
		raw_data(vertexes[:]),
		gl.DYNAMIC_DRAW,
	)

	vao = 0
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 0)
	gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 2 * size_of(f32))

	primitive_solid_shader = create_shader_u8(basic_vert, basic_frag)


	// TODO refactor blend
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

@(private)
append_vertex :: proc(x, y: f32, color: [4]f32) {
	append_elem(&vertexes, x)
	append_elem(&vertexes, y)
	append_elem(&vertexes, color.x)
	append_elem(&vertexes, color.y)
	append_elem(&vertexes, color.z)
	append_elem(&vertexes, color.w)
}

to_clip_space :: proc(x, y: f32) -> (f32, f32) {
	clip_x := (x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (y / f32(render_height)) * 2.0
	return clip_x, clip_y
}

@(private)
add_triangle_screen_space :: proc(p1, p2, p3: [2]f32, color: [4]f32) {
	x1, y1 := to_clip_space(p1.x, p1.y)
	x2, y2 := to_clip_space(p2.x, p2.y)
	x3, y3 := to_clip_space(p3.x, p3.y)

	add_triangle_clip_space(x1, y1, x2, y2, x3, y3, color)
}

@(private)
add_triangle_clip_space :: proc(x1, y1, x2, y2, x3, y3: f32, color: [4]f32) {
	append_vertex(x1, y1, color)
	append_vertex(x2, y2, color)
	append_vertex(x3, y3, color)
}

add_triangle :: proc {
	add_triangle_screen_space,
	add_triangle_clip_space,
}

@(private)
add_rectangle_screen_space :: proc(p, size: [2]f32, color: [4]f32) {
	x, y := to_clip_space(p.x, p.y)
	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2
	add_rectangle_clip_space(x, y, width, height, color)
}

@(private)
add_rectangle_clip_space :: proc(x, y, width, height: f32, color: [4]f32) {
	// *---+
	// |---|
	// +---+
	append_vertex(x, y, color)

	// +---*
	// |---|
	// +---+
	append_vertex(x + width, y, color)

	// +---+
	// |---|
	// *---+
	append_vertex(x, y - height, color)

	// +---+
	// |---|
	// *---+
	append_vertex(x, y - height, color)

	// +---*
	// |---|
	// +---+
	append_vertex(x + width, y, color)

	// +---+
	// |---|
	// +---*
	append_vertex(x + width, y - height, color)
}

add_rectangle :: proc {
	add_rectangle_screen_space,
	add_rectangle_clip_space,
}

draw_primitives :: proc() {
	gl.UseProgram(primitive_solid_shader)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BindVertexArray(vao)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertexes) * size_of(f32),
		raw_data(vertexes[:]),
		gl.DYNAMIC_DRAW,
	)

	gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertexes) / VERTEX_FLOATS_PER_VERTEX))
}

