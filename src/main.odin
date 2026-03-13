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

pos: [5]be.Vector2I = {{0, 0}, {600, 600}, {0, 1}, {0, 0}, {2560 - 400, 1440 - 400}}
rect_line: be.RectangleI = {400, 400, 200, 200}
acc: f32
rotation: f32
tick :: proc(dt: f32) {
	acc += dt
	rotation += dt * 0.25
	if rotation > 2 * 3.14 {
		rotation = 0.0
	}
	fps := int(1.0 / dt)
	// log.info("fps:", fps)

	// TODO should let
	// run input systems
	// run update systems

	for &vec in pos {
		vec.y += max(i32(50 * dt), 1)


		if vec.y > be.get_window_height() {
			vec.y = 0
		}
	}

	rect_line.x += max(i32(50 * dt), 1)

	if rect_line.x >= be.get_window_width() {
		rect_line.x = 0 - rect_line.width - 1
	}

	circle_radius: f32 = f32(rect_line.width / 2)
	center_y: f32 = f32(rect_line.y + rect_line.width / 2)
	circle_speed: f32 = 2.0
	circle_y: f32 = center_y + math.sin(acc * circle_speed) * f32(rect_line.height)
	circle_center: be.Vector2F = {f32(rect_line.x + rect_line.width / 2), circle_y}

	be.begin_drawing()
	be.clear_background(be.RAYWHITE)
	// run render systems
	// run render_ui systems

	//debug tests
	be.draw_rectangle(be.RectangleI{pos[0].x, pos[0].y, 100, 100}, be.GOLD)
	be.draw_circle(pos[1], 400, be.YELLOW)
	be.draw_line(pos[2], pos[1], 1, be.DARKPURPLE)
	be.draw_line(pos[3], be.convert_vector(circle_center), 1, be.DARKGREEN)

	be.draw_rectangle_rounded(be.RectangleI{pos[4].x, pos[4].y, 200, 200}, 20, be.BLUE)

	thickness :: 5.0

	be.draw_rectangle_line(rect_line, thickness, be.SKYBLUE)
	be.draw_circle_line(circle_center, circle_radius, thickness, be.RED)
	rect_2 := rect_line
	rect_2.y += rect_2.height
	be.draw_rectangle_rounded_line(rect_2, 20, thickness, rotation, be.Vector2I{0, 0}, be.BROWN)

	center: be.Vector2I = {be.get_window_width() / 2, be.get_window_height() / 2}
	size: i32 : 500
	be.draw_triangle(
		center,
		be.Vector2I{center.x + size, center.y + size},
		be.Vector2I{center.x, center.y + size},
		rotation,
		be.Vector2I{0, 0},
		be.RED,
	)

	be.draw_triangle_line(
		center,
		be.Vector2I{center.x + size, center.y},
		be.Vector2I{center.x + size, center.y + size},
		5,
		-rotation,
		be.Vector2I{0, 0},
		be.BLUE,
	)

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
