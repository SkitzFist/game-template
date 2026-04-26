package render

import gl "opengl"

import "core:log"

/*

	| Draw_Command | Draw_Style | Shader | vbo ? | vba ? 

*/


Draw_Command :: enum {
	TRIANGLE,
	RECTANGLE,
}

draw_commands: [dynamic]Draw_Command
draw_count: [dynamic]i32

draw_command_buffer :: proc() {
	length := len(draw_commands)
	// log.infof("[RENDER] draw cmd buffer. Count={}", length)

	for i in 0 ..< length {
		switch draw_commands[i] {
		case .TRIANGLE:
			when BACKEND == .OPENGL {
				gl.draw_triangles(draw_count[i])
			}

		case .RECTANGLE:
		//No impl
		}
	}


	// clear for next frame
	clear(&draw_commands)
	clear(&draw_count)
}

@(private = "file")
add_draw_command :: proc(cmd: Draw_Command) {
	last_index := len(draw_commands) - 1
	if last_index >= 0 && draw_commands[last_index] == cmd {
		draw_count[last_index] += 1
		// log.infof("[RENDER] append cmd={} count={}", cmd, draw_count[last_index])
	} else {
		append(&draw_commands, cmd)
		append(&draw_count, 1)
		// log.info("[RENDER] add draw cmd=", cmd)
	}
}

draw_triangle :: proc(p1, p2, p3: [2]f32, color: Color) {
	add_draw_command(.TRIANGLE)

	when BACKEND == .OPENGL {
		gl.add_triangle(p1, p2, p3, color)
	}
}

