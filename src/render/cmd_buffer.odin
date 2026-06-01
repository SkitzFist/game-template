package render

import gl "opengl"

/*

	| Draw_Command | Draw_Style | Shader | vbo ? | vba ? 

*/


Draw_Command :: enum {
	PRIMITIVE,
	TEXTURE,
	TEXT,
}

@(private = "file")
draw_commands: [dynamic]Draw_Command

@(private = "file")
draw_count: [dynamic]i32

@(private = "file")
texture_index: [dynamic]u32


cmd_buffer_shutdown :: proc() {
	delete(draw_commands)
	delete(draw_count)
	delete(texture_index)
}

draw_command_buffer :: proc() {
	length := len(draw_commands)
	// log.infof("[RENDER] draw cmd buffer. Count={}", length)

	for i in 0 ..< length {
		switch draw_commands[i] {
		case .PRIMITIVE:
			when BACKEND == .OPENGL {
				gl.draw_primitives(draw_count[i])
			}
		case .TEXTURE:
			when BACKEND == .OPENGL {
				gl.draw_textures(texture_id(texture_index[i]), draw_count[i])
			}
		case .TEXT:
			when BACKEND == .OPENGL {
				gl.draw_text(texture_id(texture_index[i]), draw_count[i])
			}
		}
	}


	// clear for next frame
	clear(&draw_commands)
	clear(&draw_count)
	clear(&texture_index)
}

@(private = "file")
add_draw_command :: proc(cmd: Draw_Command, triangle_count: i32) {
	last_index := len(draw_commands) - 1
	if last_index >= 0 && draw_commands[last_index] == cmd {
		draw_count[last_index] += triangle_count
		// log.infof("[RENDER] append cmd={} count={}", cmd, draw_count[last_index])
	} else {
		append(&draw_commands, cmd)
		append(&draw_count, triangle_count)
		// log.info("[RENDER] add draw cmd=", cmd)
	}

	// TODO when switching to handles, remove this
	append(&texture_index, 0)
}

@(private = "file")
add_draw_command_texture :: proc(cmd: Draw_Command, texture: u32, triangle_count: i32) {
	last_index := len(draw_commands) - 1

	only_increase_count :=
		last_index >= 0 && draw_commands[last_index] == cmd && texture_index[last_index] == texture

	if only_increase_count {
		draw_count[last_index] += triangle_count
	} else {
		append(&draw_commands, cmd)
		append(&draw_count, triangle_count)
		append(&texture_index, texture)
	}
}

draw_triangle :: proc(p1, p2, p3: [2]f32, color: Color) {
	add_draw_command(.PRIMITIVE, 1)

	when BACKEND == .OPENGL {
		gl.add_triangle(p1, p2, p3, color)
	}
}

draw_rectangle :: proc(pos, size: [2]f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_rectangle(pos, size, color, roundness)
	}
}

draw_circle :: proc(pos: [2]f32, radius: f32, color: Color) {
	add_draw_command(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_circle(pos, radius, color)
	}
}

draw_line_points :: proc(p1, p2: [2]f32, thickness: f32, color: Color, roundness: f32 = 0.0) {
	add_draw_command(.PRIMITIVE, 2)

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
	add_draw_command(.PRIMITIVE, 2)

	when BACKEND == .OPENGL {
		gl.add_line_direction(point, direction, length, thickness, color, roundness)
	}
}

draw_line :: proc {
	draw_line_points,
	draw_line_direction,
}


// ---- TEXTURE ----
draw_texture_full :: proc(texture: u32, pos, size: [2]f32, color: Color) {
	add_draw_command_texture(.TEXTURE, texture, 2)

	when BACKEND == .OPENGL {
		gl.add_texture_full(pos, size, color)
	}
}

draw_texture_part :: proc(texture: u32, pos, size: [2]f32, src: [4]f32, color: Color) {
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

draw_text :: proc(text: string, pos: [2]f32, color: Color, font_index: u32 = 0) {
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
draw_text_impl :: proc(text: string, pos: [2]f32, color: Color, font_index: u32 = 0) {

	draw_glyph :: proc(texture: u32, pos, size: [2]f32, src: [4]f32, color: Color) {
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

