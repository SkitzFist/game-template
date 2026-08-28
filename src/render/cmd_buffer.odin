package render

import gl "opengl"

import "core:log"

import gfx "../gfx_context"
import "../util"

/*
	NOTE: All cmd buffer handles must implement cmd type at first bit shift
*/

@(private = "file")
Handle :: u64

@(private = "file")
Count :: u32

CMD_BIT_FIELD: util.Bit_Field(Handle) = {
	bits  = Handle(size_of(Draw_Command) * 8),
	shift = 0,
}

Primitive_Handle_Field :: enum u8 {
	CMD,
	COUNT,
}
primitive_handle := util.create_handle_data(
	Handle,
	[Primitive_Handle_Field]Handle{.CMD = CMD_BIT_FIELD.bits, .COUNT = Handle(size_of(Count) * 8)},
)

Texture_Handle_Field :: enum u8 {
	CMD,
	COUNT,
	TEXTURE_INDEX,
}
texture_handle := util.create_handle_data(
	Handle,
	[Texture_Handle_Field]Handle {
		.CMD = CMD_BIT_FIELD.bits,
		.COUNT = size_of(Count) * 8,
		.TEXTURE_INDEX = size_of(Texture_Index) * 8,
	},
)

Blend_Mode_Field :: enum u8 {
	CMD,
	BLEND_MODE,
}
blend_mode_fields := util.create_handle_data(
	Handle,
	[Blend_Mode_Field]Handle{.CMD = CMD_BIT_FIELD.bits, .BLEND_MODE = size_of(gfx.Blend_Mode) * 8},
)

Draw_Command :: enum u8 {
	PRIMITIVE,
	TEXTURE,
	TEXT,
	BLEND_MODE,
}

@(private = "file")
draw_commands: [dynamic]Handle

cmd_buffer_init :: proc() {
	//init at one cache line
	cache_line_fit := 64 / size_of(Handle)
	draw_commands = make([dynamic]Handle, 0, cache_line_fit)
}

cmd_buffer_shutdown :: proc() {
	delete(draw_commands)
}

draw_command_buffer :: proc() {
	draw_cmd: Draw_Command

	for handle in draw_commands {
		draw_cmd = util.get_field(handle, CMD_BIT_FIELD, Draw_Command)

		switch draw_cmd {
		case .PRIMITIVE:
			count := util.get_field(handle, primitive_handle.fields[.COUNT], Count)
			vertex_count := i32(count) * 3
			when gfx.API == .OPENGL {
				gl.draw_primitives(vertex_count, vertex_last_drawn)
			}
			vertex_last_drawn += vertex_count

		case .TEXTURE:
			texture_index := util.get_field(
				handle,
				texture_handle.fields[.TEXTURE_INDEX],
				Texture_Index,
			)
			count := util.get_field(handle, texture_handle.fields[.COUNT], Count)
			vertex_count := i32(count) * 3
			when gfx.API == .OPENGL {
				gl.draw_textures(texture_id(texture_index), vertex_count, vertex_last_drawn)
			}
			vertex_last_drawn += vertex_count

		case .TEXT:
			texture_index := util.get_field(
				handle,
				texture_handle.fields[.TEXTURE_INDEX],
				Texture_Index,
			)
			count := util.get_field(handle, texture_handle.fields[.COUNT], Count)
			vertex_count := i32(count) * 3
			when gfx.API == .OPENGL {
				gl.draw_text(texture_id(texture_index), vertex_count, vertex_last_drawn)
			}
			vertex_last_drawn += vertex_count

		case .BLEND_MODE:
			blend_mode := util.get_field(
				handle,
				blend_mode_fields.fields[.BLEND_MODE],
				gfx.Blend_Mode,
			)

			when gfx.API == .OPENGL {
				gl.set_blend_mode(blend_mode)
			}

		}
	}

	// clear for next frame
	clear(&draw_commands)
}

@(private = "file")
increment_count :: proc(
	last_index: int,
	count_field: util.Bit_Field(Handle),
	triangle_count: Count,
) {
	handle := draw_commands[last_index]
	prev_count := util.get_field(handle, count_field, Count)
	draw_commands[last_index] = util.set_field(handle, count_field, prev_count + triangle_count)
}

@(private = "file")
add_draw_command_primitive :: proc(cmd: Draw_Command, triangle_count: u32) {

	append_new :: proc(cmd: Draw_Command, triangle_count: u32) {
		handle: Handle = util.set_field(Handle{}, primitive_handle.fields[.CMD], cmd)
		handle = util.set_field(handle, primitive_handle.fields[.COUNT], triangle_count)

		append(&draw_commands, handle)
	}

	last_index := len(draw_commands) - 1

	// first draw cmd of frame
	if last_index < 0 {
		append_new(cmd, triangle_count)
		return
	}

	handle := draw_commands[last_index]
	prev_cmd := util.get_field(handle, primitive_handle.fields[.CMD], Draw_Command)

	if prev_cmd == cmd {
		increment_count(last_index, primitive_handle.fields[.COUNT], triangle_count)
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
		handle: Handle = util.set_field(Handle{}, texture_handle.fields[.CMD], cmd)
		handle = util.set_field(handle, texture_handle.fields[.COUNT], triangle_count)
		handle = util.set_field(handle, texture_handle.fields[.TEXTURE_INDEX], texture_index)

		append(&draw_commands, handle)
	}

	prev_index := len(draw_commands) - 1

	if prev_index < 0 {
		append_new(cmd, texture_index, triangle_count)
		return
	}

	prev_handle := draw_commands[prev_index]
	prev_cmd := util.get_field(prev_handle, texture_handle.fields[.CMD], Draw_Command)
	prev_texture_index := util.get_field(
		prev_handle,
		texture_handle.fields[.TEXTURE_INDEX],
		Texture_Index,
	)

	only_increase_count := prev_cmd == cmd && prev_texture_index == texture_index

	if only_increase_count {
		increment_count(prev_index, texture_handle.fields[.COUNT], triangle_count)
	} else {
		append_new(cmd, texture_index, triangle_count)
	}
}

@(private = "file")
add_blend_mode_command :: proc(blend_mode: gfx.Blend_Mode) {
	handle := util.set_field(Handle{}, blend_mode_fields.fields[.CMD], Draw_Command.BLEND_MODE)
	handle = util.set_field(handle, blend_mode_fields.fields[.BLEND_MODE], blend_mode)
	append(&draw_commands, handle)
}

draw_triangle :: proc(p1, p2, p3: [2]f32, color: Color) {
	add_draw_command_primitive(.PRIMITIVE, 1)
	add_triangle(p1, p2, p3, color)
}

draw_rectangle :: proc(pos, size: [2]f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command_primitive(.PRIMITIVE, 2)
	add_rectangle(pos, size, color, roundness)
}

draw_circle :: proc(pos: [2]f32, radius: f32, color: Color) {
	add_draw_command_primitive(.PRIMITIVE, 2)
	add_circle(pos, radius, color)
}

draw_line_points :: proc(p1, p2: [2]f32, thickness: f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command_primitive(.PRIMITIVE, 2)
	add_line(p1, p2, thickness, color, roundness)
}

draw_line_direction :: proc(
	point, direction: [2]f32,
	length, thickness: f32,
	color: Color,
	roundness: f32 = 0.0,
) {
	add_draw_command_primitive(.PRIMITIVE, 2)
	add_line_direction(point, direction, length, thickness, color, roundness)
}

draw_line :: proc {
	draw_line_points,
	draw_line_direction,
}


// ---- TEXTURE ----
draw_texture_full :: proc(texture: Texture_Index, pos, size: [2]f32, color: Color) {
	add_draw_command_texture(.TEXTURE, texture, 2)
	add_texture_full(pos, size, color)
}

draw_texture_part :: proc(texture: Texture_Index, pos, size: [2]f32, src: [4]f32, color: Color) {
	add_draw_command_texture(.TEXTURE, texture, 2)
	add_texture_part(pos, size, {texture_width(texture), texture_height(texture)}, src, color)

}

draw_texture :: proc {
	draw_texture_full,
	draw_texture_part,
}

// ---- TEXT ----

draw_text :: proc(
	text: string,
	pos: [2]f32,
	style: Font_Style = DEFAULT_FONT_STYLE,
	handle: Font_Handle = DEFAULT_FONT,
) {
	if style.size <= 0 {
		return
	}

	if !font_is_handle_valid(handle) {
		log.error("Font handle is not valid")
		return
	}

	is_multi_line, indexes := text_is_multiline(text)

	if is_multi_line {
		lines := text_get_multilines(text, indexes)
		y := pos.y

		for &line in lines {
			draw_text_impl(line, {pos.x, y}, style.color, style, handle)
			y += text_height(handle, line, style)
		}

	} else {
		draw_text_impl(text, pos, style.color, style, handle)
	}
}


@(private = "file")
draw_text_impl :: proc(
	text: string,
	pos: [2]f32,
	color: Color,
	style: Font_Style = DEFAULT_FONT_STYLE,
	handle: Font_Handle = DEFAULT_FONT,
) {
	draw_glyph :: proc(texture: Texture_Index, pos, size: [2]f32, src: [4]f32, color: Color) {
		add_draw_command_texture(.TEXT, texture, 2)
		add_texture_part(pos, size, {texture_width(texture), texture_height(texture)}, src, color)
	}

	texture := font_get_texture(handle)
	atlas_height := font_get_atlas_height(handle)
	font_index := font_get_index(handle)
	size_scalar := style.size / font_get_base_height(handle)

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
		p = {
			cursor_x + f32(glyph.xoff) * size_scalar,
			cursor_y + (f32(glyph.yoff) - min_yoff) * size_scalar,
		}

		size = {f32(glyph.x1 - glyph.x0) * size_scalar, f32(glyph.y1 - glyph.y0) * size_scalar}

		draw_glyph(texture, p, size, src, color)

		cursor_x += f32(glyph.xadvance) * size_scalar
	}
}

// ---- BLEND MODES ---- //
set_blend_mode :: proc(blend_mode: gfx.Blend_Mode) {
	add_blend_mode_command(blend_mode)
}

end_blend_mode :: proc() {
	// set default blend mode
	add_blend_mode_command(gfx.DEFAULT_BLEND_MODE)
}
