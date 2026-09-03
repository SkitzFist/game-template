#+build linux, windows
package opengl

import gl "vendor:OpenGL"

bitmap_frag := #load("../../shaders/opengl/bitmap.frag")
bitmap_vert := #load("../../shaders/opengl/bitmap.vert")
bitmap_shader: u32

bitmap_init :: proc() {
	bitmap_shader = create_shader_u8(bitmap_vert, bitmap_frag)
}

bitmap_shutdown :: proc() {
	gl.DeleteProgram(bitmap_shader)
}

draw_text :: proc(texture: u32, vertex_count, last_drawn: i32) {
	if should_bind_shader(bitmap_shader) {
		bind_shader(bitmap_shader)
	}

	// shares vao with texture for now
	if should_bind_vao(texture_vao) {
		bind_vao(texture_vao)
	}

	if should_bind_texture(texture) {
		bind_texture(texture)
	}

	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
}
