package game

import "base:runtime"
import "core:log"
import "core:mem"

import rl "vendor:raylib"

tracking_allocator: mem.Tracking_Allocator

main :: proc() {

	context = init()
	init_window()


	for !rl.WindowShouldClose() {
		//TODO should do my own dt calc
		tick(rl.GetFrameTime())
	}

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

init_window :: proc() {
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
	monitor: i32 = 0
	width := rl.GetMonitorWidth(monitor)
	height := rl.GetMonitorHeight(monitor)
	rl.InitWindow(width, height, PROJECT_NAME)
}

tick :: proc(dt: f32) {
	fps := int(1.0 / dt)

	// TODO should let
	// run input systems
	// run update systems

	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)
	// run render systems
	// run render_ui systems
	rl.EndDrawing()
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

