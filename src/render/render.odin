package render

import gl "opengl"

import "vendor:glfw"

// ---- WINDOW ---- //
pre_window_create :: proc() {
	when BACKEND == .OPENGL {
		gl.pre_window_create()
	}
}

attach_to_window :: proc(window_handle: glfw.WindowHandle) {
	when BACKEND == .OPENGL {
		gl.attach_to_window(window_handle)
	}
}

init :: proc() {
	when BACKEND == .OPENGL {
		gl.init()
	}
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	when BACKEND == .OPENGL {
		gl.on_frame_buffer_size_changed(width, height)
	}
}

shutdown :: proc() {
	when BACKEND == .OPENGL {
		gl.shutdown()
	}

	delete(draw_commands)
	delete(draw_count)
}

// ---- FRAME ----

draw_begin :: proc(time: f64) {
	when BACKEND == .OPENGL {
		gl.draw_begin(f32(time))
	}
}

draw_end :: proc() {
	when BACKEND == .OPENGL {
		gl.draw_end()
	}
	draw_command_buffer()
}

clear_screen :: proc(color: Color) {
	when BACKEND == .OPENGL {
		gl.clear_screen(
			f32(color[0]) / 255.0,
			f32(color[1]) / 255.0,
			f32(color[2]) / 255.0,
			f32(color[3]) / 255.0,
		)
	}
}

