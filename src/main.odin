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

main :: proc() {


	context = init()

	input.init()

	window.create_fullscreen(PROJECT_NAME, r.context_config())
	defer (window.destroy())

	r.attach_context(window.width, window.height, window.gl_set_proc_address)
	window.set_framebuffer_resize_callback(r.on_frame_buffer_size_changed)
	r.init()

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

	return context
}

motion: bool
frame: int
tick :: proc(dt: f32) {
	fmt.println("Fps:", 1 / dt)
	frame += 1
	// run input systems
	if input.is_pressed(input.Key.ESCAPE) {
		window.set_close(true)
	}

	if input.is_pressed(input.Key.SPACE) {
		motion = !motion
	}

	// run update systems
	r.clear_screen(r.BLACK)

	// run render systems
	r.draw_begin(window.get_time())

	// if motion {
	// 	rectangle_checker_test_motion()
	// } else {
	// 	rectangle_checker_test()
	// }

	// rectangle_checker_color_test()

	width, height := f32(window.width), f32(window.height)

	size: f32 = 500.0
	x, y := width / 2 - size / 2, height / 2 - size / 2
	r.draw_rectangle({x, y}, size, r.GREEN)
	r.draw_circle({x + size / 2, y + size / 2}, size / 2, r.RED)
	r.draw_triangle(
		{x, y + size},
		{x + size / 2, y},
		{x + size, y + size},
		r.BLUE - {0, 0, 0, 100},
	)

	r.draw_line({x, y + size * 1.1}, {x + size, y + size * 1.1}, 25.0, r.GOLD, 0.8)

	length := f32(0.5 * math.sin(window.get_time()) + 0.5) * size
	r.draw_line({x, y + size * 1.5}, {1.0, 0.0}, length, 25.0, r.BLUE, 0.8)

	// rectangle_rounded_checker_test()

	r.draw_end()
	window.swap_buffer()

	// reset input
	input.post_frame()
}

rectangle_checker_test :: proc() {
	window_width := f32(window.width)
	window_height := f32(window.height)
	cell_size: f32 = 1.5
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			color := (row + col) % 2 == 0 ? r.BLUE : r.GREEN

			r.draw_rectangle(
				{f32(col) * cell_size, f32(row) * cell_size},
				{cell_size, cell_size},
				color,
			)
		}
	}
}

rectangle_rounded_checker_test :: proc() {
	window_width := f32(window.width)
	window_height := f32(window.height)

	t := window.get_time()
	pulse := f32((math.sin(t) + 1.0) * 0.5)

	cell_size: f32 = 2.5
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2
	// roundness := (math.sin(t * 2.0 * math.PI / 10) + 1.0) * 0.5
	roundness := 0.5

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			color := (row + col) % 2 == 0 ? r.BLUE : r.GREEN

			r.draw_rectangle(
				{f32(col) * cell_size, f32(row) * cell_size},
				{cell_size, cell_size},
				color,
				f32(roundness),
			)
		}
	}
}

rectangle_checker_color_test :: proc() {
	window_width := f32(window.width)
	window_height := f32(window.height)
	cell_size: f32 = 2.0
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			color := (row + col) % 2 == 0 ? r.BLUE : r.GREEN

			color.r = u8(frame % 255)

			r.draw_rectangle(
				{f32(col) * cell_size, f32(row) * cell_size},
				{cell_size, cell_size},
				color,
			)
		}
	}
}

rectangle_checker_test_motion :: proc() {
	window_width := f32(window.width)
	window_height := f32(window.height)
	time := window.get_time()
	cell_size: f32 = 32
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			pulse := f32(0.5 + 0.5 * math.sin(time * 2.10 + f64(col) * 0.55 + f64(row) * 0.85))

			color_a := r.rgba8(
				r.channel_u8(0.10 + 0.25 * pulse),
				r.channel_u8(0.20 + 0.20 * (1 - pulse)),
				r.channel_u8(0.70 + 0.25 * pulse),
				255,
			)
			color_b := r.rgba8(
				r.channel_u8(0.10 + 0.20 * (1 - pulse)),
				r.channel_u8(0.45 + 0.45 * pulse),
				r.channel_u8(0.15 + 0.20 * (1 - pulse)),
				255,
			)

			color := (row + col) % 2 == 0 ? color_a : color_b

			r.draw_rectangle(
				{f32(col) * cell_size, f32(row) * cell_size},
				{cell_size, cell_size},
				color,
			)
		}
	}
}

triangle_pulse_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
	time := window.get_time()
	amplitude := cell_size * 0.35
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		y1 := f32(row) * cell_size
		y2 := y1 + cell_size

		for col in 0 ..< cols {
			x1 := f32(col) * cell_size
			x2 := x1 + cell_size

			top_left :=
				y1 + f32(math.sin(time * 1.30 + f64(col) * 0.35 + f64(row) * 0.18)) * amplitude
			top_right :=
				y1 + f32(math.sin(time * 1.10 + f64(col + 1) * 0.35 + f64(row) * 0.18)) * amplitude
			bottom_left :=
				y2 + f32(math.sin(time * 1.20 + f64(col) * 0.35 + f64(row + 1) * 0.18)) * amplitude
			bottom_right :=
				y2 +
				f32(math.sin(time * 1.00 + f64(col + 1) * 0.35 + f64(row + 1) * 0.18)) * amplitude

			pulse_a := f32(0.5 + 0.5 * math.sin(time * 2.00 + f64(col) * 0.70 + f64(row) * 0.90))
			pulse_b := f32(
				0.5 + 0.5 * math.sin(time * 1.70 + f64(col) * 0.50 - f64(row) * 0.60 + 1.57),
			)

			color_a := r.rgba8(
				r.channel_u8(0.15 + 0.35 * pulse_a),
				r.channel_u8(0.25 + 0.25 * (1 - pulse_a)),
				r.channel_u8(0.75 + 0.20 * pulse_a),
				255,
			)
			color_b := r.rgba8(
				r.channel_u8(0.85 - 0.50 * pulse_b),
				r.channel_u8(0.20 + 0.60 * pulse_b),
				r.channel_u8(0.35 + 0.45 * (1 - pulse_b)),
				255,
			)

			if (row + col) % 2 == 0 {
				r.draw_triangle({x1, top_left}, {x2, top_right}, {x2, bottom_right}, color_a)
				r.draw_triangle({x1, top_left}, {x2, bottom_right}, {x1, bottom_left}, color_b)
			} else {
				r.draw_triangle({x1, top_left}, {x2, top_right}, {x1, bottom_left}, color_a)
				r.draw_triangle({x2, top_right}, {x2, bottom_right}, {x1, bottom_left}, color_b)
			}
		}
	}
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
