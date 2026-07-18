package render

import gl "opengl"

import "../util"

/*
	primitive handle:
	| draw_cmd | count_index |

	texture handle:
	| draw_cmd | count_index | texture_id |
*/

@(private = "file")
Handle :: u64

@(private = "file")
DRAW_CMD_FIELD: util.Bit_Field(Handle) : {
	bits  = 8, // cmd enum is u8
	shift = 0,
}

@(private = "file")
Count :: u32
COUNT_FIELD: util.Bit_Field(Handle) : {
	bits = size_of(Count) * 8,
	shift = DRAW_CMD_FIELD.shift + DRAW_CMD_FIELD.bits,
}

TEXTURE_INDEX_FIELD: util.Bit_Field(Handle) : {
	bits = size_of(Texture_Index) * 8,
	shift = COUNT_FIELD.shift + COUNT_FIELD.bits,
}

Draw_Command :: enum u8 {
	PRIMITIVE,
	TEXTURE,
	TEXT,
}

@(private = "file")
draw_commands: [dynamic]Handle

cmd_buffer_init :: proc() {
	assert(
		DRAW_CMD_FIELD.bits + COUNT_FIELD.bits + TEXTURE_INDEX_FIELD.bits <= (size_of(Handle) * 8),
		"[CMD_BUFFER] Bit Fields are larger then Handle",
	)

	draw_commands = make([dynamic]Handle, 0, 100)
}

cmd_buffer_shutdown :: proc() {
	delete(draw_commands)
}

draw_command_buffer :: proc() {
	draw_cmd: Draw_Command
	count: u32
	for handle in draw_commands {
		draw_cmd = util.get_field(handle, DRAW_CMD_FIELD, Draw_Command)
		count = util.get_field(handle, COUNT_FIELD, u32)

		switch draw_cmd {
		case .PRIMITIVE:
			when BACKEND == .OPENGL {
				gl.draw_primitives(count)
			}
		case .TEXTURE:
			when BACKEND == .OPENGL {
				texture_index := util.get_field(handle, TEXTURE_INDEX_FIELD, Texture_Index)
				gl.draw_textures(texture_id(texture_index), count)
			}
		case .TEXT:
			when BACKEND == .OPENGL {
				texture_index := util.get_field(handle, TEXTURE_INDEX_FIELD, Texture_Index)
				gl.draw_text(texture_id(texture_index), count)
			}
		}
	}

	// clear for next frame
	clear(&draw_commands)
}

@(private = "file")
increment_count :: proc(last_index: int, triangle_count: Count) {
	handle := draw_commands[last_index]
	prev_count := util.get_field(handle, COUNT_FIELD, Count)
	draw_commands[last_index] = util.set_field(handle, COUNT_FIELD, prev_count + triangle_count)
}

@(private = "file")
add_draw_command_primitive :: proc(cmd: Draw_Command, triangle_count: u32) {

	append_new :: proc(cmd: Draw_Command, triangle_count: u32) {
		handle: Handle = util.set_field(Handle{}, DRAW_CMD_FIELD, cmd)
		handle = util.set_field(handle, COUNT_FIELD, triangle_count)

		append(&draw_commands, handle)
	}

	last_index := len(draw_commands) - 1

	// first draw cmd of frame
	if last_index < 0 {
		append_new(cmd, triangle_count)
		return
	}

	handle := draw_commands[last_index]
	prev_cmd := util.get_field(handle, DRAW_CMD_FIELD, Draw_Command)

	if prev_cmd == cmd {
		increment_count(last_index, triangle_count)
	} else {
		append_new(cmd, triangle_count)
	}

}

@(private = "file")
add_draw_command_texture :: proc(
	cmd: Draw_Command,
	texture_index: Texture_Index,
	triangle_count: Count,
) {

	append_new :: proc(cmd: Draw_Command, texture_index: Texture_Index, triangle_count: Count) {
		handle: Handle = util.set_field(Handle{}, DRAW_CMD_FIELD, cmd)
		handle = util.set_field(handle, COUNT_FIELD, triangle_count)
		handle = util.set_field(handle, TEXTURE_INDEX_FIELD, texture_index)

		append(&draw_commands, handle)
	}

	prev_index := len(draw_commands) - 1

	if prev_index < 0 {
		append_new(cmd, texture_index, triangle_count)
		return
	}

	prev_handle := draw_commands[prev_index]
	prev_cmd := util.get_field(prev_handle, DRAW_CMD_FIELD, Draw_Command)
	prev_texture_index := util.get_field(prev_handle, TEXTURE_INDEX_FIELD, Texture_Index)

	only_increase_count := prev_cmd == cmd && prev_texture_index == texture_index

	if only_increase_count {
		increment_count(prev_index, triangle_count)
	} else {
		append_new(cmd, texture_index, triangle_count)
	}
}

draw_triangle :: proc(p1, p2, p3: [2]f32, color: Color) {
	add_draw_command_primitive(.PRIMITIVE, 1)

	when BACKEND == .OPENGL {
		gl.add_triangle(p1, p2, p3, color)
	}
}

draw_rectangle :: proc(pos, size: [2]f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command_primitive(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_rectangle(pos, size, color, roundness)
	}
}

draw_circle :: proc(pos: [2]f32, radius: f32, color: Color) {
	add_draw_command_primitive(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_circle(pos, radius, color)
	}
}

draw_line_points :: proc(p1, p2: [2]f32, thickness: f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command_primitive(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_line(p1, p2, thickness, color, roundness)
	}
}

draw_line_direction :: proc(
	point, direction: [2]f32,
	length, thickness: f32,
	color: Color,
	roundness: f32 = 0.0,
) {
	add_draw_command_primitive(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_line_direction(point, direction, length, thickness, color, roundness)
	}
}

draw_line :: proc {
	draw_line_points,
	draw_line_direction,
}


// ---- TEXTURE ----
draw_texture_full :: proc(texture: Texture_Index, pos, size: [2]f32, color: Color) {
	add_draw_command_texture(.TEXTURE, texture, 2)

	when BACKEND == .OPENGL {
		gl.add_texture_full(pos, size, color)
	}
}

draw_texture_part :: proc(texture: Texture_Index, pos, size: [2]f32, src: [4]f32, color: Color) {
	add_draw_command_texture(.TEXTURE, texture, 2)

	when BACKEND == .OPENGL {
		gl.add_texture_part(
			pos,
			size,
			{texture_width(texture), texture_height(texture)},
			src,
			color,
		)
	}

}

draw_texture :: proc {
	draw_texture_full,
	draw_texture_part,
}

// ---- TEXT ----

draw_text :: proc(text: string, pos: [2]f32, color: Color, font_index: Font_Index = 0) {
	is_multi_line, indexes := text_is_multiline(text)

	if is_multi_line {
		lines := text_get_multilines(text, indexes)
		y := pos.y

		for &line in lines {
			draw_text_impl(line, {pos.x, y}, color, font_index)
			y += text_height(font_index, line)
		}

	} else {
		draw_text_impl(text, pos, color, font_index)
	}
}


@(private = "file")
draw_text_impl :: proc(text: string, pos: [2]f32, color: Color, font_index: Font_Index = 0) {

	draw_glyph :: proc(texture: Texture_Index, pos, size: [2]f32, src: [4]f32, color: Color) {
		add_draw_command_texture(.TEXT, texture, 2)
		when BACKEND == .OPENGL {
			gl.add_texture_part(
				pos,
				size,
				{texture_width(texture), texture_height(texture)},
				src,
				color,
			)
		}
	}

	texture := font_get_texture(font_index)
	atlas_height := atlas_heights[font_index]

	min_yoff: f32 = 0
	for r in text {
		glyph := get_glyph(font_index, r)
		min_yoff = min(min_yoff, f32(glyph.yoff))
	}

	cursor_x, cursor_y := pos.x, pos.y

	src: [4]f32
	p: [2]f32
	size: [2]f32
	for r in text {
		glyph := get_glyph(font_index, r)
		w, h := f32(glyph.x1 - glyph.x0), f32(glyph.y1 - glyph.y0)

		src = {f32(glyph.x0), f32(atlas_height - i32(glyph.y0)), w, -h}
		p = {cursor_x + f32(glyph.xoff), cursor_y + f32(glyph.yoff) - min_yoff}

		size = {f32(glyph.x1 - glyph.x0), f32(glyph.y1 - glyph.y0)}

		draw_glyph(texture, p, size, src, color)

		cursor_x += f32(glyph.xadvance)
	}
}

