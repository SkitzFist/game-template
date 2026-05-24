package opengl

import "../../gfx_context"
import "core:log"
import gl "vendor:OpenGL"

@(private)
TAG :: "[OPENGL]"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 2

@(private)
render_width, render_height: i32

@(private)
TIME: f32

// ---- WINDOW ---- //
context_config :: proc() -> gfx_context.Config {
	return {
		api = .OPENGL,
		major_version = GL_MAJOR_VERSION,
		minor_version = GL_MINOR_VERSION,
		profile = .CORE,
		samples = 8,
	}
}

attach_context :: proc(width, height: i32, set_proc_address: gfx_context.Set_Proc_Address) {
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, set_proc_address)

	render_width = width
	render_height = height

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
	textures_init()
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	gl.Viewport(0, 0, width, height)
	render_width = width
	render_height = height
}

shutdown :: proc() {
	gpu_data_shutdown()
	primitives_shutdown()
	texture_shutdown()
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

