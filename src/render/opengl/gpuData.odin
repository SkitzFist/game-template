package opengl

import gl "vendor:OpenGL"

Vertex :: struct {
	x, y:   f32,
	color:  u32,
	local:  [2]f32,
	radius: f32,
}

VERTEX_STRIDE_BYTES :: size_of(Vertex)

INIT_CAP :: 1_000_000

@(private = "file")
vertexes: [dynamic]Vertex

@(private = "file")
vbo, ubo, count: u32

@(private = "file")
is_dirty: bool

last_drawn: i32

gpu_data_init :: proc() {
	// Vertex buffer
	vertexes = make([dynamic]Vertex, 0, INIT_CAP)
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	// Ubo
	gl.GenBuffers(1, &ubo)
	gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
	gl.BufferData(gl.UNIFORM_BUFFER, size_of(f32), nil, gl.DYNAMIC_DRAW)
	gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, ubo)
}

gpu_data_shutdown :: proc() {
	delete(vertexes)
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteBuffers(1, &ubo)
}

append_vertex :: proc(vertex: Vertex) {

	if int(count) >= len(vertexes) {
		append_elem(&vertexes, vertex)
		is_dirty = true
		count += 1
		return
	}

	// TODO keep track of changed indices and only upload that
	// TODO option to opt out and always mark dirty
	if vertexes[count].x != vertex.x ||
	   vertexes[count].y != vertex.y ||
	   vertexes[count].color != vertex.color ||
	   vertexes[count].local != vertex.local ||
	   vertexes[count].radius != vertex.radius {
		is_dirty = true
	}

	vertexes[count] = vertex
	count += 1
}

gpu_data_begin_frame :: proc() {
	count = 0
	is_dirty = false
	last_drawn = 0
}

gpu_data_upload :: proc() {
	if is_dirty {
		gl.BufferData(
			gl.ARRAY_BUFFER,
			int(count) * size_of(Vertex),
			raw_data(vertexes[:]),
			gl.DYNAMIC_DRAW,
		)
	}

	gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)

	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(f32), &TIME)

	// bind back to vertex buffer, this way we can be sure to not rebind when drawing.
	// and we only need to bind vao
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
}

