#+build linux, windows
package opengl

import gl "vendor:OpenGL"

textures_vert := #load("../../shaders/opengl/textures.vert")
textures_frag := #load("../../shaders/opengl/textures.frag")
texture_shader: u32

texture_vao: u32

textures_init :: proc() {
	texture_shader = create_shader_u8(textures_vert, textures_frag)

	// setup vao
	gl.GenVertexArrays(1, &texture_vao)
	gl.BindVertexArray(texture_vao)

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
}

texture_shutdown :: proc() {
	gl.DeleteVertexArrays(1, &texture_vao)
	gl.DeleteProgram(texture_shader)
}

convert_internal_format :: proc(engine_format: u32) -> i32 {
	switch engine_format {
	case 0:
		return gl.R8
	case 1:
		return gl.RG8
	case 2:
		return gl.RGB8
	case 3:
		return gl.RGBA8
	}

	panic("[OPENGL] unsupported pixel format")
}

convert_format :: proc(engine_format: u32) -> (opengl_format: u32) {
	switch engine_format {
	case 0:
		return gl.RED
	case 1:
		return gl.RG
	case 2:
		return gl.RGB
	case 3:
		return gl.RGBA
	}

	panic("[OPENGL] unsupported pixel format")
}

load_texture :: proc(image_data: [^]u8, width, height: i32, format: u32) -> u32 {
	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	// wrapping/filtering
	// TODO allow for altering
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	internal_format := convert_internal_format(format)
	gl_format := convert_format(format)

	// data
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		internal_format,
		width,
		height,
		0,
		gl_format,
		gl.UNSIGNED_BYTE,
		image_data,
	)

	// TODO allow for calling manually
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return texture
}

unload_texture :: proc(texture: ^u32) {
	gl.DeleteTextures(1, texture)
}

draw_textures :: proc(texture: u32, vertex_count: i32, last_drawn: i32) {
	if should_bind_shader(texture_shader) {
		bind_shader(texture_shader)
	}

	if should_bind_vao(texture_vao) {
		bind_vao(texture_vao)
	}

	if should_bind_texture(texture) {
		bind_texture(texture)
	}

	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
}
