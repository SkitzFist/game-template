#+build linux, windows
package game

import "assets"
import "input"
import r "render"
import "window"

main :: proc() {
	context = init_default_context()
	assets.init()

	window.init()
	input.init()

	window_response := window.create(PROJECT_NAME, r.context_config())

	r.attach_context(i32(window.width), i32(window.height), window_response)
	append(&window.resize_callbacks, r.on_frame_buffer_size_changed)

	r.init()


	wall = r.load_texture_by_asset("wall.jpg")
	tex2 = r.load_texture_by_asset("textures2.png")

	prev, curr: f64 = window.get_time(), 0.0
	dt: f64
	for !window.should_close() {
		curr = window.get_time()
		dt = curr - prev
		prev = curr

		window.poll_events()
		tick(f32(dt))
	}

	shutdown()
}
