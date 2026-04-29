package opengl

import gl "vendor:OpenGL"

import "core:fmt"
import "core:log"

@(private = "file")
Vertex :: struct {
	x, y:   f32,
	color:  u32,
	local:  [2]f32,
	radius: f32,
}

@(private = "file")
Array_Data :: struct {
	vertexes:        [dynamic]Vertex,
	vbo, vao, count: u32,
	last_drawn:      i32,
	is_dirty:        bool,
}

VERTEX_STRIDE_BYTES :: size_of(Vertex)

rounded_vert := #load("../../shaders/rounded.vert")
rounded_frag := #load("../../shaders/rounded.frag")

primitives_rounded_shader: u32
primitives_rounded: Array_Data

primitives_rounded_init :: proc() {
	primitives_rounded_shader = create_shader_u8(rounded_vert, rounded_frag)

	init_array_data(&primitives_rounded)
}

primitives_rounded_shutdown :: proc() {
	delete(primitives_rounded.vertexes)
	gl.DeleteVertexArrays(1, &primitives_rounded.vao)
	gl.DeleteBuffers(1, &primitives_rounded.vbo)

	gl.DeleteProgram(primitives_rounded_shader)
}

@(private = "file")
init_array_data :: proc(data: ^Array_Data) {
	data.vertexes = make([dynamic]Vertex, 0, INIT_CAP)

	gl.GenBuffers(1, &data.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

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

append_vertex :: proc(data: ^Array_Data, vertex: Vertex) {

	if int(data.count) >= len(data.vertexes) {
		append_elem(&data.vertexes, vertex)
		data.is_dirty = true
		data.count += 1
		return
	}

	// TODO keep track of changed indices and only upload that
	if data.vertexes[data.count].x != vertex.x ||
	   data.vertexes[data.count].y != vertex.y ||
	   data.vertexes[data.count].color != vertex.color ||
	   data.vertexes[data.count].local != vertex.local ||
	   data.vertexes[data.count].radius != vertex.radius {
		data.is_dirty = true
	}

	data.vertexes[data.count] = vertex
	data.count += 1
}

add_rectangle_rounded_screen_space :: proc(pos, size: [2]f32, radius: f32, color: [4]u8) {
	x, y := to_clip_space(pos.x, pos.y)
	add_rectangle_rounded_clip_space(x, y, size, radius, color)
}

add_rectangle_rounded_clip_space :: proc(x, y: f32, size: [2]f32, radius: f32, color: [4]u8) {

	// clip_space
	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2
	// world space
	half_w, half_h := size.x / 2, size.y / 2
	color := pack_color(color)

	// *---+ 0
	// |---|
	// +---+
	append_vertex(&primitives_rounded, Vertex{x, y, color, {-half_w, half_h}, radius})

	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives_rounded, Vertex{x + width, y, color, {half_w, half_h}, radius})

	// +---+ 2
	// |---|
	// *---+
	append_vertex(&primitives_rounded, Vertex{x, y - height, color, {-half_w, -half_h}, radius})
	append_vertex(&primitives_rounded, Vertex{x, y - height, color, {-half_w, -half_h}, radius})


	// +---* 1
	// |---|
	// +---+
	append_vertex(&primitives_rounded, Vertex{x + width, y, color, {half_w, half_h}, radius})

	// +---+ 3
	// |---|
	// +---*
	append_vertex(
		&primitives_rounded,
		Vertex{x + width, y - height, color, {half_w, -half_h}, radius},
	)
}

add_rectangle_rounded :: proc {
	add_rectangle_rounded_screen_space,
	add_rectangle_rounded_clip_space,
}

draw_primitives_rounded :: proc(count: i32) {
	gl.UseProgram(primitives_rounded_shader)
	gl.BindBuffer(gl.ARRAY_BUFFER, primitives_rounded.vbo)
	gl.BindVertexArray(primitives_rounded.vao)

	vertex_count := count * 3
	log.info("primitives_rounded:", vertex_count / 3)
	gl.DrawArrays(gl.TRIANGLES, primitives_rounded.last_drawn, vertex_count)
	primitives_rounded.last_drawn += vertex_count
}

primitives_rounded_data_to_gpu :: proc() {
	if primitives_rounded.is_dirty {
		log.info("[OPENGL] primitives rounded dirty, uploading to gpu")
		gl.BindBuffer(gl.ARRAY_BUFFER, primitives_rounded.vbo)
		gl.BufferData(
			gl.ARRAY_BUFFER,
			int(primitives_rounded.count) * size_of(Vertex),
			raw_data(primitives_rounded.vertexes[:primitives_rounded.count]),
			gl.DYNAMIC_DRAW,
		)
	}
}

