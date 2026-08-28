package render

import gfx "../gfx_context"
import gl "opengl"

// ---- STRUCTS ---- //

Vertex :: struct {
	x, y:   f32,
	color:  u32,
	local:  [2]f32,
	radius: f32,
}

// ---- CONSTANTS ---- //

VERTEX_STRIDE_BYTES :: size_of(Vertex)
INIT_CAP :: 1_000_000

// ---- VARIABLES ---- //

@(private = "file")
vertexes: [dynamic]Vertex

@(private = "file")
count: u32

@(private = "file")
is_dirty: bool

vertex_last_drawn: i32


vertex_init :: proc() {
	vertexes = make([dynamic]Vertex, 0, INIT_CAP)
}

vertex_shutdown :: proc() {
	delete(vertexes)
}

vertex_begin_frame :: proc() {
	count = 0
	vertex_last_drawn = 0
}

vertex_upload :: proc() {
	if is_dirty {
		when gfx.API == .OPENGL {
			gl.gpu_data_upload_vertex(Vertex, raw_data(vertexes[:]), count)
		} else when gfx.API == .WEBGL {
			// no impl yet
		}

		is_dirty = false
	}
}

vertex_append :: proc(vertex: Vertex) {
	if int(count) >= len(vertexes) {
		append_elem(&vertexes, vertex)
		is_dirty = true
		count += 1
		return
	}

	// TODO keep track of changed indices and only upload that
	// TODO option to opt out and always mark dirty
	// TODO this check is so godamn slow, lowers with ~20 fps on 1.8 million triangles
	if vertexes[count].x != vertex.x ||
	   vertexes[count].y != vertex.y ||
	   vertexes[count].color != vertex.color ||
	   vertexes[count].local != vertex.local ||
	   vertexes[count].radius != vertex.radius {
		vertexes[count] = vertex
		is_dirty = true
	}

	count += 1
}
