#+build js wasm32
package game

import "base:runtime"

import gfx "gfx_context"
import "input"
import r "render"
import "window"

web_context: runtime.Context

/*
	TODO: Add file load support (must in order to add texture and font)
	TODO: Add input support for web
*/

main :: proc() {
	context = init_default_context()
	web_context = context

	window.init()
	input.init()

	window_response := window.create(
		"Game is the template",
		gfx.Config {
			api = .WEBGL,
			samples = 8,
			backend_config = gfx.WebGl_Config {
				canvas_name = "canvas",
				web_window_mode = .STRETCH,
				width = 1920,
				height = 1080,
				aspect_ratio = 1920 / 1080,
			},
		},
	)
	append(&window.resize_callbacks, r.on_frame_buffer_size_changed)

	r.init()
	r.attach_context(i32(window.width), i32(window.height), window_response)
}


@(export)
web_tick :: proc "c" (dt: f32) {
	context = web_context

	r.draw_begin(window.get_time())
	r.clear_screen(r.BLACK)

	r.set_blend_mode(.ADDITIVE)
	r.draw_circle({window.width / 4, window.height / 4}, window.width / 4, r.YELLOW)
	r.draw_circle({window.width / 2, window.height / 2}, window.width / 2, r.BLUE - {0, 0, 0, 100})

	// runtime_tests_update(dt)

	r.draw_end()
}

@(export)
web_shutdown :: proc "c" () {
	context = web_context
	shutdown()
}
