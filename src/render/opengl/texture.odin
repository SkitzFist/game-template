#+build linux, windows
package opengl

import gl "vendor:OpenGL"

import "core:log"

textures_vert := #load("../../shaders/textures.vert")
textures_frag := #load("../../shaders/textures.frag")
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

add_texture_full :: proc(pos, size: [2]f32, color: [4]u8) {

	color := pack_color(color)
	x, y := to_clip_space(pos.x, pos.y)

	// clip_space
	width, height := (size.x / f32(render_width)) * 2, (size.y / f32(render_height)) * 2

	// *---+ 0
	// |---|
	// +---+
	append_vertex(Vertex{x, y, color, {0.0, 1.0}, 0})

	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {1.0, 1.0}, 0})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(Vertex{x, y - height, color, {0.0, 0.0}, 0})
	append_vertex(Vertex{x, y - height, color, {0.0, 0.0}, 0})


	// +---* 1
	// |---|
	// +---+
	append_vertex(Vertex{x + width, y, color, {1.0, 1.0}, 0})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(Vertex{x + width, y - height, color, {1.0, 0.0}, 0})
}

add_texture_part :: proc(pos, size, texture_size_px: [2]f32, src_px: [4]f32, color: [4]u8) {

	color := pack_color(color)
	x, y := to_clip_space(pos.x, pos.y)

	width, height := (size.x / f32(render_width)) * 2, (size.y / f32(render_height)) * 2

	src_left: f32 = src_px.x / texture_size_px.x
	src_right: f32 = (src_px.x + src_px[2]) / texture_size_px.x
	src_top: f32 = 1.0 - src_px.y / texture_size_px.y
	src_bottom: f32 = 1.0 - (src_px.y + src_px[3]) / texture_size_px.y

	append_vertex(Vertex{x, y, color, {src_left, src_top}, 0})

	append_vertex(Vertex{x + width, y, color, {src_right, src_top}, 0})

	append_vertex(Vertex{x, y - height, color, {src_left, src_bottom}, 0})
	append_vertex(Vertex{x, y - height, color, {src_left, src_bottom}, 0})

	append_vertex(Vertex{x + width, y, color, {src_right, src_top}, 0})

	append_vertex(Vertex{x + width, y - height, color, {src_right, src_bottom}, 0})

}

draw_textures :: proc(texture: u32, triangle_count: i32) {
	if should_bind_shader(texture_shader) {
		bind_shader(texture_shader)
	}

	if should_bind_vao(texture_vao) {
		bind_vao(texture_vao)
	}

	if should_bind_texture(texture) {
		bind_texture(texture)
	}

	// log.infof("Texture count: %i", triangle_count / 2)

	vertex_count := triangle_count * 3

	gl.DrawArrays(gl.TRIANGLES, last_drawn, vertex_count)
	last_drawn += vertex_count
}

