#+build js wasm32
package webgl_backend

import gl "vendor:wasm/WebGL"

last_used_shader: gl.Program
last_used_vao: gl.VertexArrayObject
last_used_texture: gl.Texture


should_bind_shader :: #force_inline proc(shader: gl.Program) -> bool {
	return shader != last_used_shader
}

bind_shader :: proc(shader: gl.Program) {
	gl.UseProgram(shader)
	last_used_shader = shader
}

should_bind_vao :: proc(vao: gl.VertexArrayObject) -> bool {
	return last_used_vao != vao
}

bind_vao :: proc(vao: gl.VertexArrayObject) {
	gl.BindVertexArray(vao)
	last_used_vao = vao
}

should_bind_texture :: proc(texture: gl.Texture) -> bool {
	return texture != last_used_texture
}

bind_texture :: proc(texture: gl.Texture) {
	gl.BindTexture(gl.TEXTURE_2D, texture)
	last_used_texture = texture
}
