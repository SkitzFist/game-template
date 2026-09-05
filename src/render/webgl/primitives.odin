#+build js wasm32
package webgl_backend

import gl "vendor:wasm/WebGL"

// TODO refactor shader
primitives_vert := #load("../../shaders/webgl/primitives.vert")
primitives_frag := #load("../../shaders/webgl/primitives.frag")
primitives_shader: gl.Program

vao: gl.VertexArrayObject

primitives_init :: proc() {
	primitives_shader = create_shader_u8(primitives_vert, primitives_frag)
	init_array_data()
}

primitives_shutdown :: proc() {
	gl.DeleteVertexArray(vao)
	gl.DeleteProgram(primitives_shader)
}

@(private = "file")
init_array_data :: proc() {
	vao = gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)

	pointer: uintptr = 0

	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, VERTEX_STRIDE_BYTES, 0)
	pointer += 2 * size_of(f32)

	gl.VertexAttribPointer(1, 4, gl.UNSIGNED_BYTE, true, VERTEX_STRIDE_BYTES, pointer)
	pointer += 1 * size_of(u32)

	gl.VertexAttribPointer(2, 2, gl.FLOAT, false, VERTEX_STRIDE_BYTES, pointer)
	pointer += 2 * size_of(f32)

	gl.VertexAttribPointer(3, 1, gl.FLOAT, false, VERTEX_STRIDE_BYTES, pointer)
}


draw_primitives :: proc(vertex_count: i32, last_drawn: i32) {
	if should_bind_shader(primitives_shader) {
		bind_shader(primitives_shader)
	}

	if should_bind_vao(vao) {
		bind_vao(vao)
	}

	gl.DrawArrays(gl.TRIANGLES, int(last_drawn), int(vertex_count))
}
