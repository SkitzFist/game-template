#+build linux, windows
package game
import "base:runtime"
import "core:log"
import "core:mem"

import "input"
import r "render"
import "window"

//debug
import "core:fmt"

main :: proc() {
	context = init()

	input.init()

	window.create_fullscreen(PROJECT_NAME, r.context_config())
	defer (window.destroy())

	r.attach_context(i32(window.width), i32(window.height), window.gl_set_proc_address)
	window.set_framebuffer_resize_callback(r.on_frame_buffer_size_changed)
	r.init()

	wall = r.load_texture("assets/sprites/wall.jpg")
	tex2 = r.load_texture("assets/sprites/textures2.png")

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


tick :: proc(dt: f32) {
	fmt.println("Fps:", 1 / dt)
	frame += 1
	// run input systems
	if input.is_pressed(input.Key.ESCAPE) {
		window.set_close(true)
	}


	// run update systems
	r.clear_screen(r.BLACK)

	// run render systems
	r.draw_begin(window.get_time())

	runtime_tests_update(dt)

	r.draw_end()
	window.swap_buffer()

	// reset input
	input.post_frame()

	// reset arena alloc
	mem.arena_free_all(&arena)
}

shutdown :: proc() {
	r.shutdown()


	log.info("[MAIN] shutting down...")

	when MEM_TRACK {
		reset_tracking_allocator(&tracking_allocator)
	}

	log.info("[MAIN] shutdown completed")
}

reset_tracking_allocator :: proc(allocator: ^mem.Tracking_Allocator) -> bool {
	err := false

	for _, value in allocator.allocation_map {
		log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
		err = true
	}

	mem.tracking_allocator_clear(allocator)
	return err
}

