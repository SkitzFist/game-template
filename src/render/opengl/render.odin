package opengl

import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

@(private)
TAG :: "[OPENGL]"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 2

@(private)
render_width, render_height: i32

@(private)
TIME: f32

// ---- WINDOW ---- //
pre_window_create :: proc() {
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
}

attach_to_window :: proc(window_handle: glfw.WindowHandle) {
	glfw.MakeContextCurrent(window_handle)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	render_width, render_height = glfw.GetFramebufferSize(window_handle)

	gl.Viewport(0, 0, render_width, render_height)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CW)

	log.info(TAG, "Attached to window")
}

init :: proc() {
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gpu_data_init()
	primitives_init()
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	gl.Viewport(0, 0, width, height)
	render_width = width
	render_height = height
}

shutdown :: proc() {
	gpu_data_shutdown()
	primitives_shutdown()
}

// --- FRAME --- //
draw_begin :: proc(time: f32) {
	TIME = time
	gpu_data_begin_frame()
}

draw_end :: proc() {
	gpu_data_upload()
}


// --- DRAW --- //
clear_screen :: proc(r, g, b, a: f32) {
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

