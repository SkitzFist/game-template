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

on_frame_buffer_size_changed :: proc(width, height: i32) {
	when BACKEND == .OPENGL {
		gl.on_frame_buffer_size_changed(width, height)
	}
}

shutdown :: proc() {
	when BACKEND == .OPENGL {
		gl.shutdown()
	}
}

// ---- FRAME ----

draw_begin :: proc() {
	when BACKEND == .OPENGL {
		gl.draw_begin()
	}
}

draw_end :: proc() {
	when BACKEND == .OPENGL {
		gl.draw_end()
	}
}

clear_screen :: proc() {
	when BACKEND == .OPENGL {
		gl.clear_screen()
	}
}

