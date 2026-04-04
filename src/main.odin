package game

import "base:runtime"
import "core:log"
import "core:mem"

import "input"
import "render"
import "window"


//debug
import "core:fmt"

tracking_allocator: mem.Tracking_Allocator

main :: proc() {
	context = init()

	input.init()

	window.create(1080, 1920, PROJECT_NAME)
	defer (window.destroy())

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
		opt = {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color},
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
	// run input systems
	if input.is_pressed(input.Key.ESCAPE) {
		window.set_close(true)
	}

	// run update systems
	render.clear()
	// run render systems

	// run render_ui systems

	window.swap_buffer()

	// reset input
	input.post_frame()
}

shutdown :: proc() {

	log.info("[MAIN] shutting down...")
	reset_tracking_allocator(&tracking_allocator)

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

