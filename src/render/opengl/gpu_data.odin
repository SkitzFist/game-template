#+build linux, windows
package opengl

import gl "vendor:OpenGL"

/*
	TODO: add support for multiple VBO/UBO (should in pipeline update)
*/

VERTEX_STRIDE_BYTES: i32

@(private = "file")
vbo, ubo: u32

gpu_data_init :: proc($Vertex: typeid) {
	VERTEX_STRIDE_BYTES = size_of(Vertex)
	// Vertex buffer
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
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteBuffers(1, &ubo)
}


gpu_data_upload_vertex :: proc($Vertex: typeid, data: rawptr, count: u32) {
	gl.BufferData(gl.ARRAY_BUFFER, int(count) * size_of(Vertex), data, gl.DYNAMIC_DRAW)
}

gpu_data_ubo_upload :: proc(time: f32) {
	time := time

	// Upload global shader data
	gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(f32), &time)

	// bind back to vertex buffer, this way we can be sure to not rebind when drawing.
	// and we only need to bind vao
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
}
