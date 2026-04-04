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

clear :: proc() {
	when BACKEND == .OPENGL {
		gl.clear()
	}
}

