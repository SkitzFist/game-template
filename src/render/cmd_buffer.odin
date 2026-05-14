package render

import gl "opengl"

/*

	| Draw_Command | Draw_Style | Shader | vbo ? | vba ? 

*/


Draw_Command :: enum {
	PRIMITIVE,
}

draw_commands: [dynamic]Draw_Command
draw_count: [dynamic]i32

draw_command_buffer :: proc() {
	length := len(draw_commands)
	// log.infof("[RENDER] draw cmd buffer. Count={}", length)

	for i in 0 ..< length {
		switch draw_commands[i] {
		case .PRIMITIVE:
			when BACKEND == .OPENGL {
				gl.draw_primitives(draw_count[i])
			}
		}
	}


	// clear for next frame
	clear(&draw_commands)
	clear(&draw_count)
}

@(private = "file")
add_draw_command :: proc(cmd: Draw_Command, count: i32) {
	last_index := len(draw_commands) - 1
	if last_index >= 0 && draw_commands[last_index] == cmd {
		draw_count[last_index] += count
		// log.infof("[RENDER] append cmd={} count={}", cmd, draw_count[last_index])
	} else {
		append(&draw_commands, cmd)
		append(&draw_count, count)
		// log.info("[RENDER] add draw cmd=", cmd)
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

