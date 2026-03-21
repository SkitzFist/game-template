package game

import "base:runtime"
import "core:log"
import "core:math"
import "core:mem"

import be "render_backend"

tracking_allocator: mem.Tracking_Allocator

main :: proc() {
	context = init()
	init_window()


	for !be.should_close() {
		//TODO should do my own dt calc
		tick(0.016)
	}

	shutdown()
}

init :: proc() -> runtime.Context {

	context = runtime.default_context()
	context.logger = log.create_console_logger(
		opt = {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color},
	)
	log.info("[MAIN] Init:", ODIN_OS, ODIN_ARCH)

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

init_window :: proc() {
	be.init_window(2560, 1440, PROJECT_NAME)
}

tick :: proc(dt: f32) {
	fps := int(1.0 / dt)
	// log.info("fps:", fps)

	// TODO should let
	// run input systems
	// run update systems

	be.begin_drawing()
	be.clear_background(be.RAYWHITE)
	// run render systems
	examples_shape_draw()
	// examples_arc_line(dt)

	// run render_ui systems

	be.end_drawing()
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

