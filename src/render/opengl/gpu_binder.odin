#+build linux, windows
package opengl

import gl "vendor:OpenGL"

last_used_shader: u32 = max(u32)
last_used_vao: u32 = max(u32)
last_used_texture: u32 = max(u32)

should_bind_shader :: #force_inline proc(shader: u32) -> bool {
	return shader != last_used_shader
}

bind_shader :: proc(shader: u32) {
	gl.UseProgram(shader)
	last_used_shader = shader
}

should_bind_vao :: proc(vao: u32) -> bool {
	return last_used_vao != vao
}

bind_vao :: proc(vao: u32) {
	gl.BindVertexArray(vao)
	last_used_vao = vao
}

should_bind_texture :: proc(texture: u32) -> bool {
	return texture != last_used_texture
}

bind_texture :: proc(texture: u32) {
	gl.BindTexture(gl.TEXTURE_2D, texture)
	last_used_texture = texture
}

