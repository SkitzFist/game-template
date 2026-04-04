package opengl

import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 1

// ---- WINDOW ---- //
pre_window_create :: proc() {
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
}

attach_to_window :: proc(window_handle: glfw.WindowHandle) {

	glfw.MakeContextCurrent(window_handle)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
}

clear :: proc() {
	gl.ClearColor(0, 0, 0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

