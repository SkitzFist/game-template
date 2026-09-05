#+build js wasm32
package webgl_backend

import gl "vendor:wasm/WebGL"

/*
	TODO: add support for multiple VBO/UBO (should in pipeline update)
*/

VERTEX_STRIDE_BYTES: int

@(private = "file")
vbo, ubo: gl.Buffer

gpu_data_init :: proc($Vertex: typeid) {
	VERTEX_STRIDE_BYTES = size_of(Vertex)
	// Vertex buffer
	vbo = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	// Ubo
	ubo = gl.CreateBuffer()
	gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
	// todo std140 requires 16 bytes to be allocated
	gl.BufferData(gl.UNIFORM_BUFFER, size_of(f32) * 4, nil, gl.DYNAMIC_DRAW)
	gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, ubo)
}

gpu_data_shutdown :: proc() {
	gl.DeleteBuffer(vbo)
	gl.DeleteBuffer(ubo)
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
