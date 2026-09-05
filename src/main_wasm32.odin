#+build js wasm32
package game

import "base:runtime"

import "assets"
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

	assets.init()

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

	wall = r.load_texture_by_asset("wall.jpg")
	tex2 = r.load_texture_by_asset("textures2.png")
}


@(export)
web_tick :: proc "c" (dt: f32) {
	context = web_context
	tick(dt)
}

@(export)
web_shutdown :: proc "c" () {
	context = web_context
	shutdown()
}
