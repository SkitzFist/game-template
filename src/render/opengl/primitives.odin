#+build linux, windows
package opengl

import gl "vendor:OpenGL"

Primitives :: struct {
	vao: u32,
}

// TODO refactor shader
primitives_vert := #load("../../shaders/opengl/primitives.vert")
primitives_frag := #load("../../shaders/opengl/primitives.frag")
primitives_shader: u32

primitives: Primitives


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


draw_primitives :: proc(vertex_count: i32, last_drawn: i32) {
	if should_bind_shader(primitives_shader) {
		bind_shader(primitives_shader)
	}

	if should_bind_vao(primitives.vao) {
		bind_vao(primitives.vao)
	}

	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
}
