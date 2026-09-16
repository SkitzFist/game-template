package game

// import "base:runtime"
// import "core:log"
// import "core:mem"

// import "assets"
// import gfx "gfx_context"
// import "input"
// import r "render"
// import "window"

// // TODO: This entire file needs to be refactored

// tracking_allocator: mem.Tracking_Allocator
// arena: mem.Arena
// arena_buffer: [1024 * 1024]byte

// init_default_context :: proc() -> runtime.Context {
// 	context = runtime.default_context()
// 	context.logger = log.create_console_logger(opt = {.Level, .Line, .Terminal_Color})

// 	log.info("[MAIN] Init:", ODIN_OS, ODIN_ARCH)
// 	log.info("[MAIN] Render backend:", gfx.API)

// 	// Mem Tracker
// 	when MEM_TRACK {
// 		// innit tracking allocator
// 		default_allocator := context.allocator
// 		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
// 		context.allocator = mem.tracking_allocator(&tracking_allocator)
// 		log.info("[MAIN] memory tracker initialized")
// 	}

// 	// Arena allocator
// 	mem.arena_init(&arena, arena_buffer[:])
// 	context.temp_allocator = mem.arena_allocator(&arena)
// 	log.info("[MAIN] temp allocator (arena stack buffer) initialized")

// 	return context
// }

// tick :: proc(dt: f32) {
// 	// fmt.println("Fps:", 1 / dt)
// 	frame += 1
// 	// run input systems
// 	if input.is_pressed(input.Key.ESCAPE) {
// 		window.set_close(true)
// 	}

// 	// run update systems
// 	r.clear_screen(r.BLACK)

// 	// run render systems
// 	r.draw_begin(window.get_time())

// 	runtime_tests_update(dt)

// 	r.draw_end()
// 	window.swap_buffer()

// 	// reset input
// 	input.post_frame()

// 	// reset arena alloc
// 	mem.arena_free_all(&arena)
// }

// shutdown :: proc() {
// 	log.info("[MAIN] shutting down...")

// 	assets.destroy()
// 	log.info("[MAIN] Assets destroyed sucessfully")

// 	r.shutdown()
// 	log.info("[MAIN] Renderer shut down successfully")

// 	window.shutdown()
// 	log.info("[MAIN] Window shutdown successfully")

// 	when MEM_TRACK {
// 		reset_tracking_allocator(&tracking_allocator)
// 	}

// 	log.info("[MAIN] shutdown completed")
// }

// reset_tracking_allocator :: proc(allocator: ^mem.Tracking_Allocator) -> bool {
// 	err := false

// 	for _, value in allocator.allocation_map {
// 		log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
// 		err = true
// 	}

// 	mem.tracking_allocator_clear(allocator)
// 	return err
// }
