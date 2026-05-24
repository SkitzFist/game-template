package render

import gl "opengl"

/*

	| Draw_Command | Draw_Style | Shader | vbo ? | vba ? 

*/


Draw_Command :: enum {
	PRIMITIVE,
	TEXTURE,
}

draw_commands: [dynamic]Draw_Command
draw_count: [dynamic]i32
texture_index: [dynamic]u32

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
			gl.draw_textures(texture_id(texture_index[i]), draw_count[i])
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
add_draw_command_texture :: proc(texture: u32, triangle_count: i32) {
	last_index := len(draw_commands) - 1

	only_increase_count :=
		last_index >= 0 &&
		draw_commands[last_index] == .TEXTURE &&
		texture_index[last_index] == texture

	if only_increase_count {
		draw_count[last_index] += triangle_count
	} else {
		append(&draw_commands, Draw_Command.TEXTURE)
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
	add_draw_command_texture(texture, 2)

	when BACKEND == .OPENGL {
		gl.add_texture_full(pos, size, color)
	}
}

draw_texture_part :: proc(texture: u32, pos, size: [2]f32, src: [4]f32, color: Color) {
	add_draw_command_texture(texture, 2)

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

