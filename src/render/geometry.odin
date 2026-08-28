package render

to_clip_space :: #force_inline proc(v: [2]f32) -> [2]f32 {
	clip_x := (v.x / f32(render_width)) * 2.0 - 1.0
	clip_y := 1.0 - (v.y / f32(render_height)) * 2.0
	return {clip_x, clip_y}
}

size_to_clip_size :: #force_inline proc(size: [2]f32) -> [2]f32 {
	return {(size.x / render_width) * 2, (size.y / render_height) * 2}
}

pack_color :: proc(color: [4]u8) -> u32 {
	return u32(color[0]) | u32(color[1]) << 8 | u32(color[2]) << 16 | u32(color[3]) << 24
}

append_quad :: proc(pos, size, half: [2]f32, color: u32, roundness: f32) {
	vertex_append(Vertex{pos.x, pos.y, color, {-half.x, half.y}, roundness})

	// +---* 1
	// |---|
	// +---+
	vertex_append(Vertex{pos.x + size.x, pos.y, color, {half.x, half.y}, roundness})

	// +---+ 2
	// |---|
	// *---+
	vertex_append(Vertex{pos.x, pos.y - size.y, color, {-half.x, -half.y}, roundness})
	vertex_append(Vertex{pos.x, pos.y - size.y, color, {-half.x, -half.y}, roundness})


	// +---* 1
	// |---|
	// +---+
	vertex_append(Vertex{pos.x + size.x, pos.y, color, {half.x, half.y}, roundness})

	// +---+ 3
	// |---|
	// +---*
	vertex_append(Vertex{pos.x + size.x, pos.y - size.y, color, {half.x, -half.y}, roundness})
}

@(private = "file")
DEFAULT_TEXTURE_SRC: [5][2]f32 = {{0, 1}, {1, 1}, {0, 0}, {1, 1}, {1, 0}}

append_texture_quad :: proc(pos, size: [2]f32, color: u32, src: [5][2]f32 = DEFAULT_TEXTURE_SRC) {

	vertex_append(Vertex{pos.x, pos.y, color, src[0], 0})

	// +---* 1
	// |---|
	// +---+
	vertex_append(Vertex{pos.x + size.x, pos.y, color, src[1], 0})

	// +---+ 2
	// |---|
	// *---+
	vertex_append(Vertex{pos.x, pos.y - size.y, color, src[2], 0})
	vertex_append(Vertex{pos.x, pos.y - size.y, color, src[2], 0})


	// +---* 1
	// |---|
	// +---+
	vertex_append(Vertex{pos.x + size.x, pos.y, color, src[3], 0})

	// +---+ 3
	// |---|
	// +---*
	vertex_append(Vertex{pos.x + size.x, pos.y - size.y, color, src[4], 0})
}

append_triangle :: proc(p1, p2, p3: [2]f32, color: u32) {
	NONE_HALF: [2]f32 : {0, 0}

	vertex_append(Vertex{p1.x, p1.y, color, NONE_HALF, 0})
	vertex_append(Vertex{p2.x, p2.y, color, NONE_HALF, 0})
	vertex_append(Vertex{p3.x, p3.y, color, NONE_HALF, 0})
}
