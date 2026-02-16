package game

import "base:runtime"
import "core:log"
import "core:mem"

//debug
import "core:fmt"


tracking_allocator: mem.Tracking_Allocator

MEM_TRACK :: #config(MEM_TRACK, true)
PLATFORM :: #config(PLATFORM, "DESKTOP")

main :: proc() {

	context = init()

	tick(0.016)

	shutdown()
}

init :: proc() -> runtime.Context {

	context = runtime.default_context()
	context.logger = log.create_console_logger(
		opt = {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color},
	)
	log.info("[MAIN] Init:", PLATFORM)

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

tick :: proc(dt: f32) {
	fps := int(1.0 / dt)
	log.info("dt:", dt, "\tfps:", fps)
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

