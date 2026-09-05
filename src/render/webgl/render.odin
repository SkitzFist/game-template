#+build js wasm32
package webgl_backend

import gfx "../../gfx_context"
import "core:log"
import gl "vendor:wasm/WebGL"

@(private)
TAG :: "[WEBGL]"

// ---- WINDOW ---- //
attach_context :: proc(width, height: i32, window_response: gfx.Window_Response) {

	window_response := window_response.(gfx.Window_WebGl_Response)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CW)

	gl.Viewport(0, 0, width, height)

	log.info(TAG, "Attached to window")
}

init :: proc($Vertex: typeid) {
	gpu_data_init(Vertex)
	primitives_init()
	textures_init()
	bitmap_init()
	set_blend_mode(gfx.DEFAULT_BLEND_MODE)
}

shutdown :: proc() {
	gpu_data_shutdown()
	primitives_shutdown()
	texture_shutdown()
	bitmap_shutdown()
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	gl.Viewport(0, 0, width, height)
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
	gl.Clear(u32(gl.COLOR_BUFFER_BIT))
}
