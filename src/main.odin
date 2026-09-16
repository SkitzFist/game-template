#+build linux, windows
package game

import "assets"

import str "stride:api"

main :: proc() {
	context = init_default_context()
	assets.init()

	str.create(PROJECT_NAME, CONFIG)

	wall := str.load_texture_from_data("wall", assets.sprites["wall.jpg"])
	tex2 := str.load_texture_from_data("textures2", assets.sprites["textures2.png"])

	prev, curr: f64 = str.get_time(), 0.0
	dt: f64
	for !str.should_window_close() {
		curr = str.get_time()
		dt = curr - prev
		prev = curr

		str.poll_events()
		tick(f32(dt))
	}

	str.shutdown()
}
