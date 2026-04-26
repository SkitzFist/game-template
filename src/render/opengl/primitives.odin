package opengl

import "base:intrinsics"
import gl "vendor:OpenGL"

import "core:log"

Array_Data :: struct {
	vertexes:        [dynamic]f32,
	vbo, vao, count: u32,
	last_drawn:      i32,
	is_dirty:        bool,
}

Element_Data :: struct {}

VERTEX_FLOATS_PER_VERTEX :: 6
VERTEX_STRIDE_BYTES :: VERTEX_FLOATS_PER_VERTEX * size_of(f32)

basic_vert := #load("../../shaders/basic.vert")
basic_frag := #load("../../shaders/basic.frag")

primitive_solid_shader: u32
triangles: Array_Data

init_primitives :: proc() {
	// Shader
	primitive_solid_shader = create_shader_u8(basic_vert, basic_frag)

	// Data
	init_array_data(&triangles)

}

init_array_data :: proc(data: ^Array_Data) {
	data.vertexes = make([dynamic]f32, 0, 1000000)
	data.vbo = 0
	gl.GenBuffers(1, &data.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(data.vertexes) * size_of(f32),
		raw_data(data.vertexes[:]),
		gl.DYNAMIC_DRAW,
	)

	data.vao = 0
	gl.GenVertexArrays(1, &data.vao)
	gl.BindVertexArray(data.vao)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.BindBuffer(gl.ARRAY_BUFFER, data.vbo)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 0)
	gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, VERTEX_STRIDE_BYTES, 2 * size_of(f32))

}

@(private)
append_vertex :: proc(data: ^Array_Data, x, y: f32, color: [4]f32) {

	count := data.count

	if int(count + 6) >= len(data.vertexes) {
		append_elem(&data.vertexes, x)
		append_elem(&data.vertexes, y)
		append_elem(&data.vertexes, color.x)
		append_elem(&data.vertexes, color.y)
		append_elem(&data.vertexes, color.z)
		append_elem(&data.vertexes, color.w)

		data.is_dirty = true
		data.count += 6
		return
	}

	// TODO keep track of changed indices and only upload that data.
	if data.vertexes[count] != x ||
	   data.vertexes[count + 1] != y ||
	   data.vertexes[count + 2] != color[0] ||
	   data.vertexes[count + 3] != color[1] ||
	   data.vertexes[count + 4] != color[2] ||
	   data.vertexes[count + 5] != color[3] {
		data.is_dirty = true
	}

	data.vertexes[count] = x
	data.vertexes[count + 1] = y
	data.vertexes[count + 2] = color[0]
	data.vertexes[count + 3] = color[1]
	data.vertexes[count + 4] = color[2]
	data.vertexes[count + 5] = color[3]

	data.count += 6
}

to_clip_space :: proc(x, y: f32) -> (f32, f32) {
	clip_x := (x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (y / f32(render_height)) * 2.0
	return clip_x, clip_y
}

@(private)
add_triangle_screen_space :: proc(p1, p2, p3: [2]f32, color: [4]f32) {
	x1, y1 := to_clip_space(p1.x, p1.y)
	x2, y2 := to_clip_space(p2.x, p2.y)
	x3, y3 := to_clip_space(p3.x, p3.y)

	add_triangle_clip_space(x1, y1, x2, y2, x3, y3, color)
}

@(private)
add_triangle_clip_space :: proc(x1, y1, x2, y2, x3, y3: f32, color: [4]f32) {
	append_vertex(&triangles, x1, y1, color)
	append_vertex(&triangles, x2, y2, color)
	append_vertex(&triangles, x3, y3, color)
}

add_triangle :: proc {
	add_triangle_screen_space,
	add_triangle_clip_space,
}

// @(private)
// add_rectangle_screen_space :: proc(p, size: [2]f32, color: [4]f32) {
// 	x, y := to_clip_space(p.x, p.y)
// 	width, height := (size.x / f32(render_width) * 2), (size.y / f32(render_height)) * 2
// 	add_rectangle_clip_space(x, y, width, height, color)
// }

// @(private)
// add_rectangle_clip_space :: proc(x, y, width, height: f32, color: [4]f32) {
// 	// *---+
// 	// |---|
// 	// +---+
// 	append_vertex(x, y, color)

// 	// +---*
// 	// |---|
// 	// +---+
// 	append_vertex(x + width, y, color)

// 	// +---+
// 	// |---|
// 	// *---+
// 	append_vertex(x, y - height, color)

// 	// +---+
// 	// |---|
// 	// *---+
// 	append_vertex(x, y - height, color)

// 	// +---*
// 	// |---|
// 	// +---+
// 	append_vertex(x + width, y, color)

// 	// +---+
// 	// |---|
// 	// +---*
// 	append_vertex(x + width, y - height, color)
// }

// add_rectangle :: proc {
// 	add_rectangle_screen_space,
// 	add_rectangle_clip_space,
// }

// draw_primitives :: proc() {
// 	gl.UseProgram(primitive_solid_shader)
// 	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
// 	gl.BindVertexArray(vao)
// 	gl.BufferData(
// 		gl.ARRAY_BUFFER,
// 		len(vertexes) * size_of(f32),
// 		raw_data(vertexes[:]),
// 		gl.DYNAMIC_DRAW,
// 	)

// 	gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertexes) / VERTEX_FLOATS_PER_VERTEX))
// }


// TODO make shader as a parameter, maybe?
draw_triangles :: proc(count: i32) {
	gl.UseProgram(primitive_solid_shader)
	gl.BindBuffer(gl.ARRAY_BUFFER, triangles.vbo)
	gl.BindVertexArray(triangles.vao)

	vertice_count := count * 6

	log.info("Triangles:", vertice_count / 6)

	gl.DrawArrays(gl.TRIANGLES, triangles.last_drawn, vertice_count)
	triangles.last_drawn += vertice_count
}


data_to_gpu :: proc() {
	if triangles.is_dirty {

		log.info("[OPENGL] trianlges dirty. uploading to gpu")
		gl.BindBuffer(gl.ARRAY_BUFFER, triangles.vbo)
		gl.BufferData(
			gl.ARRAY_BUFFER,
			int(triangles.count) * size_of(f32),
			raw_data(triangles.vertexes[:triangles.count]),
			gl.DYNAMIC_DRAW,
		)
	}
}

