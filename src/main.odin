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

motion: bool
frame: int
cell_size: f32 = 2.0
Test :: enum {
	ALL_PRIMITIVES,
	RECTANGLE_CHECKER,
	RECTANGLE_CHECKER_COLOR,
	RECTANGLE_CHECKER_MOTION,
	TRIANGLE_STATIC,
	TRIANGLE_PULSE_TEST,
	SINGLE_TEXTURE,
	TWO_TEXTURES,
	TEXTURE_CHECKER,
	TEXTURE_PART,
	TEXT_SINGLE_LINE,
	TEXT_MULTI_LINE,
}

test: Test = .TEXT_MULTI_LINE

tick :: proc(dt: f32) {
	fmt.println("Fps:", 1 / dt)
	frame += 1
	// run input systems
	if input.is_pressed(input.Key.ESCAPE) {
		window.set_close(true)
	}

	if input.is_pressed(input.Key.LEFT) {
		next := int(test) - 1
		if next < 0 {
			next = len(Test) - 1
		}
		next %= len(Test)
		test = Test(next)
	} else if input.is_pressed(input.Key.RIGHT) {
		next := (int(test) + 1) % len(Test)
		test = Test(next)
	}

	size: f32 = input.is_held(input.Key.LEFT_CONTROL) ? 2.0 : 0.5

	if input.is_pressed(input.Key.UP) {
		cell_size += size
	} else if input.is_pressed(input.Key.DOWN) {
		cell_size -= size
		cell_size = max(cell_size, 0)
	}

	// run update systems
	r.clear_screen(r.BLACK)

	// run render systems
	r.draw_begin(window.get_time())

	switch test {
	case .ALL_PRIMITIVES:
		all_primitives()
	case .RECTANGLE_CHECKER:
		rectangle_checker_test(cell_size)
	case .RECTANGLE_CHECKER_COLOR:
		rectangle_checker_color_test(cell_size)
	case .RECTANGLE_CHECKER_MOTION:
		rectangle_checker_test_motion(cell_size)
	case .TRIANGLE_STATIC:
		triangle_static_test(cell_size)
	case .TRIANGLE_PULSE_TEST:
		triangle_pulse_test(cell_size)
	case .SINGLE_TEXTURE:
		single_texture()
	case .TWO_TEXTURES:
		two_textures()
	case .TEXTURE_CHECKER:
		texture_checker_test(cell_size)
	case .TEXTURE_PART:
		texture_part_test()
	case .TEXT_SINGLE_LINE:
		text_single_line()
	case .TEXT_MULTI_LINE:
		text_multi_line()
	}

	// r.draw_rectangle(0, 200, r.BLUE)
	// r.draw_circle(200, 50, 50)
	// r.draw_texture(tex2, 500, {r.texture_width(tex2), r.texture_height(tex2)}, r.WHITE)
	//

	r.draw_end()
	window.swap_buffer()

	// reset input
	input.post_frame()

	// reset arena alloc
	mem.arena_free_all(&arena)
}

text_single_line :: proc() {
	ascii: [95]u8
	for a, i in 32 ..< 95 + 32 {
		ascii[i] = u8(a)
	}
	text: string = string(ascii[:])
	pos: [2]f32 = {200, 200}
	r.draw_text(text, pos, r.WHITE)
	text_width := r.text_width(r.FONT_DEFAULT, text)
	text_height := r.text_height(r.FONT_DEFAULT, text)
	r.draw_line_direction(pos + {0, text_height + 10}, {90, 0}, text_width, 3.0, r.BLUE)
	r.draw_line_direction(pos - {10, 0}, {0, 90}, text_height, 3.0, r.BLUE)
}

text_multi_line :: proc() {
	ascii: [95 * 2 + 1]u8
	for a, i in 32 ..< 95 + 32 {
		ascii[i] = u8(a)
	}

	ascii[95] = u8('\n')

	for a, i in 32 ..< 95 + 32 {
		ascii[i + 95 + 1] = u8(a)
	}

	text: string = string(ascii[:])
	pos: [2]f32 = {200, 200}

	r.draw_text(text, pos, r.WHITE)
	text_width := r.text_width(r.FONT_DEFAULT, text)
	text_height := r.text_height(r.FONT_DEFAULT, text)
	r.draw_line_direction(pos + {0, text_height + 10}, {90, 0}, text_width, 3.0, r.BLUE)
	r.draw_line_direction(pos - {10, 0}, {0, 90}, text_height, 3.0, r.BLUE)
}

single_texture :: proc() {
	r.draw_texture(wall, 0, {f32(window.width), f32(window.height)}, r.WHITE)
}

two_textures :: proc() {
	r.draw_texture(wall, 0, {r.texture_width(wall), r.texture_height(wall)}, r.WHITE)
	r.draw_texture(tex2, {250, 250}, {r.texture_width(tex2), r.texture_height(tex2)}, r.WHITE)
}

texture_checker_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			is_even := (row + col) % 2 == 0
			if is_even {
				r.draw_texture(
					wall,
					{f32(col) * cell_size, f32(row) * cell_size},
					{cell_size, cell_size},
					255,
				)
			}
		}
	}

	for row in 0 ..< rows {
		for col in 0 ..< cols {
			is_even := (row + col) % 2 == 0
			if !is_even {
				r.draw_texture(
					tex2,
					{f32(col) * cell_size, f32(row) * cell_size},
					{cell_size, cell_size},
					255,
				)
			}
		}
	}
}

texture_part_test :: proc() {

	t_w := r.texture_width(tex2)
	t_h := r.texture_height(tex2)

	h_w := t_w / 2
	h_h := t_h / 2

	start: f32 = 200

	p := 0.5 * math.sin(window.get_time()) + 0.5
	offset: f32 = f32(p) * 50

	r.draw_texture(tex2, start, {h_w, h_h}, {0, 0, h_w, h_h}, r.WHITE)
	r.draw_texture(tex2, {start + h_w + offset, start}, {h_w, h_h}, {h_w, 0, h_w, h_h}, r.WHITE)
	r.draw_texture(tex2, {start, start + h_h + offset}, {h_w, h_h}, {0, h_h, h_w, h_h}, 255)

	r.draw_texture(
		tex2,
		{start + h_w + offset, start + h_h + offset},
		{h_w, h_h},
		{h_w, h_h, h_w, h_h},
		255,
	)
}

all_primitives :: proc() {

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
}

rectangle_checker_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
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

rectangle_rounded_checker_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)

	t := window.get_time()
	pulse := f32((math.sin(t) + 1.0) * 0.5)

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

rectangle_checker_color_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
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

rectangle_checker_test_motion :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
	time := window.get_time()
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

triangle_static_test :: proc(cell_size: f32) {
	window_width := f32(window.width)
	window_height := f32(window.height)
	cols := i32(window_width / cell_size) + 2
	rows := i32(window_height / cell_size) + 2

	for row in 0 ..< rows {
		y1 := f32(row) * cell_size
		y2 := y1 + cell_size

		for col in 0 ..< cols {
			x1 := f32(col) * cell_size
			x2 := x1 + cell_size

			if (row + col) % 2 == 0 {
				r.draw_triangle({x1, y1}, {x2, y1}, {x2, y2}, r.BLUE)
				r.draw_triangle({x1, y1}, {x2, y2}, {x1, y2}, r.GREEN)
			} else {
				r.draw_triangle({x1, y1}, {x2, y1}, {x1, y2}, r.GREEN)
				r.draw_triangle({x2, y1}, {x2, y2}, {x1, y2}, r.BLUE)
			}
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

