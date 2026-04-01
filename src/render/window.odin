package render

import "vendor:glfw"

import opengl "opengl"

pre_window_create :: proc() {
	when BACKEND == .OPENGL {
		opengl.pre_window_create()
	}
}

attach_to_window :: proc(window_handle: glfw.WindowHandle) {
	when BACKEND == .OPENGL {
		opengl.attach_to_window(window_handle)
	}
}

