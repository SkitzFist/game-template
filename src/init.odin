package game

import "base:runtime"
import "core:log"
import "core:mem"

import r "render"

tracking_allocator: mem.Tracking_Allocator
arena: mem.Arena
arena_buffer: [1024 * 1024]byte

init :: proc() -> runtime.Context {
	context = runtime.default_context()
	context.logger = log.create_console_logger(opt = {.Level, .Line, .Terminal_Color})

	log.info("[MAIN] Init:", ODIN_OS, ODIN_ARCH)
	log.info("[MAIN] Render backend:", r.BACKEND)

	// Mem Tracker
	when MEM_TRACK {
		// innit tracking allocator
		default_allocator := context.allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
		log.info("[MAIN] memory tracker initialized")
	}

	// Arena allocator
	mem.arena_init(&arena, arena_buffer[:])
	context.temp_allocator = mem.arena_allocator(&arena)
	log.info("temp allocator (arena stack buffer) initialized")

	return context
}

