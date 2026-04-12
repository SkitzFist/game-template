package game

import "base:runtime"
import "core:log"
import "core:mem"

import "input"
import "render"
import "window"

//debug
import "core:math"
import gl "render/opengl"

tracking_allocator: mem.Tracking_Allocator

main :: proc() {


	context = init()

	input.init()

	window.create_fullscreen(PROJECT_NAME)
	defer (window.destroy())

	gl.init_primitives()
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

init :: proc() -> runtime.Context {

	context = runtime.default_context()
	context.logger = log.create_console_logger(
		opt = {.Level, .Time, .Line, .Procedure, .Terminal_Color},
	)

	log.info("[MAIN] Init:", ODIN_OS, ODIN_ARCH)
	log.info("[MAIN] Render backend:", render.BACKEND)

	// Mem Tracker
	when MEM_TRACK {
		// innit tracking allocator
		default_allocator := context.allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
		log.info("[MAIN] memory tracker initialized")
	}

	return context
}

i: int
word: [100]u8

tick :: proc(dt: f32) {
	// fmt.println("Fps:", 1 / dt)
	// run input systems
	if input.is_pressed(input.Key.ESCAPE) {
		window.set_close(true)
	}

	// run update systems
	render.clear_screen()

	// run render systems
	render.draw_begin()

	window_width := f32(window.width)
	window_height := f32(window.height)

	gl.add_rectangle(-0.5, 0.5, 1.0, 1.0, {0, 0, 1.0, 1.0})

	x := math.abs(f32(math.sin(window.get_time() * 0.5)) * window_width / 2)
	gl.add_triangle({0, 0}, {x, window_height / 2}, {0, window_height}, {0.2, 1.0, 0.2, 1.0})
	gl.add_triangle(
		{(window_width), 0},
		{window_width / 2 + x, window_height / 2},
		{window_width, window_height},
		{0.2, 0.2, 0.8, 0.5},
	)


	// run render_ui systems

	gl.draw_end()
	window.swap_buffer()

	// reset input
	input.post_frame()
}

shutdown :: proc() {
	render.shutdown()


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

