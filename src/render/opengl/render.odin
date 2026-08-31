#+build linux, windows
package opengl

import gfx "../../gfx_context"
import "core:log"
import gl "vendor:OpenGL"

@(private)
TAG :: "[OPENGL]"

@(private = "file")
SUPPORTED_VERSIONS: []gfx.Version = {{4, 6}, {4, 3}, {4, 1}, {3, 3}}

// ---- WINDOW ---- //
context_config :: proc() -> gfx.Config {
	return {
		api = .OPENGL,
		samples = 8,
		backend_config = gfx.OpenGl_Config{supported_versions = SUPPORTED_VERSIONS[:]},
	}
}

attach_context :: proc(width, height: i32, window_response: gfx.Window_Response) {

	switch response in window_response {
	case gfx.Window_WebGl_Response:
		panic("[OPENGL] Does not support Window_WebGl_Response")
	case gfx.Window_OpenGl_Response:
		gl.load_up_to(
			response.accepted_version.major,
			response.accepted_version.minor,
			response.set_proc_address,
		)
	}

	gl.Viewport(0, 0, width, height)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CW)

	log.info(TAG, "Attached to window")
}

init :: proc($Vertex: typeid) {
	gpu_data_init(Vertex)
	primitives_init()
	textures_init()
	bitmap_init()
	set_blend_mode(gfx.DEFAULT_BLEND_MODE)
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

shutdown :: proc() {
	gpu_data_shutdown()
	primitives_shutdown()
	texture_shutdown()
	bitmap_shutdown()
}

// --- FRAME --- //
draw_begin :: proc(time: f32) {
	gpu_data_ubo_upload(time)
}

draw_end :: proc() {
}

// --- DRAW --- //
clear_screen :: proc(r, g, b, a: f32) {
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}
