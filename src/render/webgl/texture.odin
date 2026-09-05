#+build js wasm32
package webgl_backend

import gl "vendor:wasm/WebGL"

textures_vert := #load("../../shaders/webgl/textures.vert")
textures_frag := #load("../../shaders/webgl/textures.frag")
texture_shader: gl.Program

texture_vao: gl.VertexArrayObject

textures_init :: proc() {
	texture_shader = create_shader_u8(textures_vert, textures_frag)

	// setup vao
	texture_vao = gl.CreateVertexArray()
	gl.BindVertexArray(texture_vao)

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
}

texture_shutdown :: proc() {
	gl.DeleteVertexArray(texture_vao)
	gl.DeleteProgram(texture_shader)
}

convert_internal_format :: proc(engine_format: u32) -> gl.Enum {
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

	panic("[WEBGL] unsupported pixel format")
}

convert_format :: proc(engine_format: u32) -> gl.Enum {
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

	panic("[WEBGL] unsupported pixel format")
}

load_texture :: proc(image_data: [^]u8, width, height: i32, format: u32) -> gl.Texture {
	texture := gl.CreateTexture()
	gl.BindTexture(gl.TEXTURE_2D, texture)

	// wrapping/filtering
	// TODO allow for altering
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, i32(gl.REPEAT))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(gl.LINEAR_MIPMAP_LINEAR))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, i32(gl.LINEAR))

	internal_format := convert_internal_format(format)
	gl_format := convert_format(format)

	channel_count := int(format) + 1
	data_size := int(width) * int(height) * channel_count

	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		internal_format,
		width,
		height,
		0,
		gl_format,
		gl.UNSIGNED_BYTE,
		data_size,
		image_data,
	)

	// TODO allow for calling manually
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return texture
}

unload_texture :: proc(texture: gl.Texture) {
	gl.DeleteTexture(texture)
}

draw_textures :: proc(texture: u32, vertex_count: i32, last_drawn: i32) {
	if should_bind_shader(texture_shader) {
		bind_shader(texture_shader)
	}

	if should_bind_vao(texture_vao) {
		bind_vao(texture_vao)
	}

	texture := gl.Texture(texture)
	if should_bind_texture(texture) {
		bind_texture(texture)
	}

	gl.DrawArrays(gl.TRIANGLES, int(last_drawn), int(vertex_count))
}
