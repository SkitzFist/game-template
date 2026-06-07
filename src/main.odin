package game
import "base:runtime"
import "core:log"
import "core:mem"

import "input"
import r "render"
import "window"

//debug
import "core:fmt"
import "core:math"

tracking_allocator: mem.Tracking_Allocator
arena: mem.Arena
arena_buffer: [1024 * 1024]byte

wall, tex2: u32

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

