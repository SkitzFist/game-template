#+build linux, windows
package opengl

import gl "vendor:OpenGL"

bitmap_frag := #load("../../shaders/bitmap.frag")
bitmap_vert := #load("../../shaders/bitmap.vert")
bitmap_shader: u32

bitmap_init :: proc() {
	bitmap_shader = create_shader_u8(bitmap_vert, bitmap_frag)
}

bitmap_shutdown :: proc() {
	gl.DeleteProgram(bitmap_shader)
}

draw_text :: proc(texture: u32, triangle_count: u32) {
	triangle_count := i32(triangle_count)
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

	vertex_count := triangle_count * 3

	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
	last_drawn += vertex_count
}

