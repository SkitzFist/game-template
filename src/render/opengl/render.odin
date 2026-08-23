#+build linux, windows
package opengl

import gfx "../../gfx_context"
import "core:log"
import gl "vendor:OpenGL"

@(private)
TAG :: "[OPENGL]"

@(private)
render_width, render_height: i32

@(private)
TIME: f32

@(private = "file")
SUPPORTED_VERSIONS: []gfx.Version = {{4, 6}, {4, 3}, {4, 1}, {3, 3}}

// ---- WINDOW ---- //
context_config :: proc() -> gfx.Config {
	return {
		api = .OPENGL,
		supported_versions = SUPPORTED_VERSIONS[:],
		profile = .CORE,
		samples = 8,
	}
}

attach_context :: proc(
	width, height: i32,
	version: gfx.Version,
	set_proc_address: gfx.Set_Proc_Address,
) {
	gl.load_up_to(version.major, version.minor, set_proc_address)

	render_width = width
	render_height = height

	gl.Viewport(0, 0, render_width, render_height)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CW)

	log.info(TAG, "Attached to window")
}

init :: proc() {
	gpu_data_init()
	primitives_init()
	textures_init()
	bitmap_init()
	set_blend_mode(gfx.DEFAULT_BLEND_MODE)
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
	bitmap_shutdown()
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

