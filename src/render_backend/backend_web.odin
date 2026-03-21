#+build js wasm32
package render_backend

foreign import "game_env"

@(default_calling_convention = "contextless")
foreign game_env {
	init_window_js :: proc(width, height: i32, window_title: string) ---
	get_render_width :: proc() -> i32 ---
	get_render_height :: proc() -> i32 ---
	should_close_js :: proc() -> bool ---
	submit_commands_js :: proc(cmd_type_ptr: [^]u32, cmd_data_ptr: [^]u32, cmd_data_size_ptr: [^]u32, cmd_count: i32, cmd_data_count: i32) ---
}

COMMAND_CAPACITY :: 1024
COMMAND_DATA_CAPACITY :: 4096

Command_Type :: enum u32 {
	CLEAR_BACKGROUND       = 1,
	DRAW_RECTANGLE         = 2,
	DRAW_RECTANGLE_ROUNDED = 3,
	DRAW_CIRCLE            = 4,
	DRAW_LINE              = 5,
	DRAW_RECTANGLE_LINE    = 6,
	DRAW_RECT_ROUNDED_LINE = 7,
	DRAW_CIRCLE_LINE       = 8,
	DRAW_TRIANGLE          = 9,
	DRAW_TRIANGLE_LINE     = 10,
}

command_type: [COMMAND_CAPACITY]u32
command_data_size: [COMMAND_CAPACITY]u32
command_data: [COMMAND_DATA_CAPACITY]u32

command_count: int
command_data_count: int

push_data_u32 :: #force_inline proc(value: u32) {
	if command_data_count >= COMMAND_DATA_CAPACITY {
		return
	}
	command_data[command_data_count] = value
	command_data_count += 1
}

push_data_i32 :: #force_inline proc(value: i32) {
	push_data_u32(u32(value))
}

push_data_f32 :: #force_inline proc(value: f32) {
	push_data_u32(transmute(u32)value)
}

pack_rgba :: #force_inline proc(color: Color) -> u32 {
	return u32(color.r) | (u32(color.g) << 8) | (u32(color.b) << 16) | (u32(color.a) << 24)
}

push_command_header :: #force_inline proc(kind: Command_Type, data_word_count: u32) {
	command_type[command_count] = u32(kind)
	command_data_size[command_count] = data_word_count
	command_count += 1
}

// WINDOW
init_window :: #force_inline proc(width, height: i32, window_title: cstring) {
	init_window_js(width, height, string(window_title))
}

get_window_width :: #force_inline proc() -> i32 {
	return get_render_width()
}

get_window_height :: #force_inline proc() -> i32 {
	return get_render_height()
}

should_close :: #force_inline proc() -> bool {
	return should_close_js()
}

// DRAWING
begin_drawing :: #force_inline proc() {
	command_count = 0
	command_data_count = 0
}

end_drawing :: #force_inline proc() {
	submit_commands_js(
		&command_type[0],
		&command_data[0],
		&command_data_size[0],
		i32(command_count),
		i32(command_data_count),
	)
}

clear_background :: #force_inline proc(color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.CLEAR_BACKGROUND, 1)
	push_data_u32(packed_rgba)
}

@(private = "file")
draw_rectangle_i32 :: #force_inline proc(rect: RectangleI, color: Color) {
	draw_rectangle_i32_rot(rect, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_i32_rot :: #force_inline proc(rect: RectangleI, rotation: f32, pivot: Vector2F, color: Color) {
	draw_rectangle_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_f32 :: #force_inline proc(rect: RectangleF, color: Color) {
	draw_rectangle_f32_rot(rect, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_f32_rot :: #force_inline proc(rect: RectangleF, rotation: f32, pivot: Vector2F, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_RECTANGLE, 8)
	push_data_f32(rect.x)
	push_data_f32(rect.y)
	push_data_f32(rect.width)
	push_data_f32(rect.height)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_rectangle :: proc {
	draw_rectangle_f32,
	draw_rectangle_f32_rot,
	draw_rectangle_i32,
	draw_rectangle_i32_rot,
}

@(private = "file")
draw_rectangle_rounded_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_i32_rot(rect, corner_radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	color: Color,
) {
	draw_rectangle_rounded_f32_rot(rect, corner_radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_RECTANGLE_ROUNDED, 9)
	push_data_f32(rect.x)
	push_data_f32(rect.y)
	push_data_f32(rect.width)
	push_data_f32(rect.height)
	push_data_f32(corner_radius)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_rectangle_rounded :: proc {
	draw_rectangle_rounded_f32,
	draw_rectangle_rounded_f32_rot,
	draw_rectangle_rounded_i32,
	draw_rectangle_rounded_i32_rot,
}

@(private = "file")
draw_circle_i32 :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	draw_circle_i32_rot(center, radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_i32_rot :: #force_inline proc(center: Vector2I, radius: f32, rotation: f32, pivot: Vector2F, color: Color) {
	draw_circle_f32_rot(Vector2F{f32(center.x), f32(center.y)}, radius, rotation, pivot, color)
}

@(private = "file")
draw_circle_f32 :: #force_inline proc(center: Vector2F, radius: f32, color: Color) {
	draw_circle_f32_rot(center, radius, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_f32_rot :: #force_inline proc(center: Vector2F, radius: f32, rotation: f32, pivot: Vector2F, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_CIRCLE, 7)
	push_data_f32(center.x)
	push_data_f32(center.y)
	push_data_f32(radius)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_circle :: proc {
	draw_circle_f32,
	draw_circle_f32_rot,
	draw_circle_i32,
	draw_circle_i32_rot,
}

@(private = "file")
draw_triangle_i32 :: #force_inline proc(v1, v2, v3: Vector2I, color: Color) {
	draw_triangle_i32_rot(v1, v2, v3, 0.0, normalized_pivot_in_bounds(f32(min(v1.x, min(v2.x, v3.x))), f32(min(v1.y, min(v2.y, v3.y))), f32(max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x))), f32(max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y))), f32(v1.x + v2.x + v3.x) / 3.0, f32(v1.y + v2.y + v3.y) / 3.0), color)
}

@(private = "file")
draw_triangle_i32_rot :: #force_inline proc(v1, v2, v3: Vector2I, rotation: f32, pivot: Vector2F, color: Color) {
	draw_triangle_f32_rot(convert_vector(v1), convert_vector(v2), convert_vector(v3), rotation, pivot, color)
}

@(private = "file")
draw_triangle_f32 :: #force_inline proc(v1, v2, v3: Vector2F, color: Color) {
	draw_triangle_f32_rot(v1, v2, v3, 0.0, normalized_pivot_in_bounds(min(v1.x, min(v2.x, v3.x)), min(v1.y, min(v2.y, v3.y)), max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x)), max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y)), (v1.x + v2.x + v3.x) / 3.0, (v1.y + v2.y + v3.y) / 3.0), color)
}

@(private = "file")
draw_triangle_f32_rot :: #force_inline proc(v1, v2, v3: Vector2F, rotation: f32, pivot: Vector2F, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_TRIANGLE, 10)
	push_data_f32(v1.x)
	push_data_f32(v1.y)
	push_data_f32(v2.x)
	push_data_f32(v2.y)
	push_data_f32(v3.x)
	push_data_f32(v3.y)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_triangle :: proc {
	draw_triangle_f32,
	draw_triangle_f32_rot,
	draw_triangle_i32,
	draw_triangle_i32_rot,
}

@(private = "file")
draw_line_i32 :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	draw_line_i32_rot(start, end, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_line_i32_rot :: #force_inline proc(start, end: Vector2I, thickness: f32, rotation: f32, pivot: Vector2F, color: Color) {
	draw_line_f32_rot(
		Vector2F{f32(start.x), f32(start.y)},
		Vector2F{f32(end.x), f32(end.y)},
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_line_f32 :: #force_inline proc(start, end: Vector2F, thickness: f32, color: Color) {
	draw_line_f32_rot(start, end, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_line_f32_rot :: #force_inline proc(start, end: Vector2F, thickness: f32, rotation: f32, pivot: Vector2F, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_LINE, 9)
	push_data_f32(start.x)
	push_data_f32(start.y)
	push_data_f32(end.x)
	push_data_f32(end.y)
	push_data_f32(thickness)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_line :: proc {
	draw_line_f32,
	draw_line_f32_rot,
	draw_line_i32,
	draw_line_i32_rot,
}

@(private = "file")
draw_rectangle_line_i32 :: #force_inline proc(rect: RectangleI, thickness: f32, color: Color) {
	draw_rectangle_line_i32_rot(rect, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_line_i32_rot :: #force_inline proc(rect: RectangleI, thickness: f32, rotation: f32, pivot: Vector2F, color: Color) {
	draw_rectangle_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_line_f32 :: #force_inline proc(rect: RectangleF, thickness: f32, color: Color) {
	draw_rectangle_line_f32_rot(rect, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_line_f32_rot :: #force_inline proc(rect: RectangleF, thickness: f32, rotation: f32, pivot: Vector2F, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_RECTANGLE_LINE, 9)
	push_data_f32(rect.x)
	push_data_f32(rect.y)
	push_data_f32(rect.width)
	push_data_f32(rect.height)
	push_data_f32(thickness)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_rectangle_line :: proc {
	draw_rectangle_line_f32,
	draw_rectangle_line_f32_rot,
	draw_rectangle_line_i32,
	draw_rectangle_line_i32_rot,
}

@(private = "file")
draw_rectangle_rounded_line_i32 :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_i32_rot(rect, corner_radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_line_i32_rot :: #force_inline proc(
	rect: RectangleI,
	corner_radius: f32,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(
		RectangleF{f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)},
		corner_radius,
		thickness,
		rotation,
		pivot,
		color,
	)
}

@(private = "file")
draw_rectangle_rounded_line_f32 :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	thickness: f32,
	color: Color,
) {
	draw_rectangle_rounded_line_f32_rot(rect, corner_radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_rectangle_rounded_line_f32_rot :: #force_inline proc(
	rect: RectangleF,
	corner_radius: f32,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_RECT_ROUNDED_LINE, 10)
	push_data_f32(rect.x)
	push_data_f32(rect.y)
	push_data_f32(rect.width)
	push_data_f32(rect.height)
	push_data_f32(corner_radius)
	push_data_f32(thickness)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_rectangle_rounded_line :: proc {
	draw_rectangle_rounded_line_f32,
	draw_rectangle_rounded_line_f32_rot,
	draw_rectangle_rounded_line_i32,
	draw_rectangle_rounded_line_i32_rot,
}

@(private = "file")
draw_circle_line_i32 :: #force_inline proc(
	center: Vector2I,
	radius: f32,
	thickness: f32,
	color: Color,
) {
	draw_circle_line_i32_rot(center, radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_line_i32_rot :: #force_inline proc(
	center: Vector2I,
	radius: f32,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_circle_line_f32_rot(Vector2F{f32(center.x), f32(center.y)}, radius, thickness, rotation, pivot, color)
}

@(private = "file")
draw_circle_line_f32 :: #force_inline proc(
	center: Vector2F,
	radius: f32,
	thickness: f32,
	color: Color,
) {
	draw_circle_line_f32_rot(center, radius, thickness, 0.0, PIVOT_TOP_LEFT, color)
}

@(private = "file")
draw_circle_line_f32_rot :: #force_inline proc(
	center: Vector2F,
	radius: f32,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_CIRCLE_LINE, 8)
	push_data_f32(center.x)
	push_data_f32(center.y)
	push_data_f32(radius)
	push_data_f32(thickness)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_circle_line :: proc {
	draw_circle_line_f32,
	draw_circle_line_f32_rot,
	draw_circle_line_i32,
	draw_circle_line_i32_rot,
}

@(private = "file")
draw_triangle_line_i32 :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	color: Color,
) {
	draw_triangle_line_i32_rot(v1, v2, v3, thickness, 0.0, normalized_pivot_in_bounds(f32(min(v1.x, min(v2.x, v3.x))), f32(min(v1.y, min(v2.y, v3.y))), f32(max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x))), f32(max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y))), f32(v1.x + v2.x + v3.x) / 3.0, f32(v1.y + v2.y + v3.y) / 3.0), color)
}

@(private = "file")
draw_triangle_line_i32_rot :: #force_inline proc(
	v1, v2, v3: Vector2I,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	draw_triangle_line_f32_rot(convert_vector(v1), convert_vector(v2), convert_vector(v3), thickness, rotation, pivot, color)
}

@(private = "file")
draw_triangle_line_f32 :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	color: Color,
) {
	draw_triangle_line_f32_rot(v1, v2, v3, thickness, 0.0, normalized_pivot_in_bounds(min(v1.x, min(v2.x, v3.x)), min(v1.y, min(v2.y, v3.y)), max(v1.x, max(v2.x, v3.x)) - min(v1.x, min(v2.x, v3.x)), max(v1.y, max(v2.y, v3.y)) - min(v1.y, min(v2.y, v3.y)), (v1.x + v2.x + v3.x) / 3.0, (v1.y + v2.y + v3.y) / 3.0), color)
}

@(private = "file")
draw_triangle_line_f32_rot :: #force_inline proc(
	v1, v2, v3: Vector2F,
	thickness: f32,
	rotation: f32,
	pivot: Vector2F,
	color: Color,
) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_TRIANGLE_LINE, 11)
	push_data_f32(v1.x)
	push_data_f32(v1.y)
	push_data_f32(v2.x)
	push_data_f32(v2.y)
	push_data_f32(v3.x)
	push_data_f32(v3.y)
	push_data_f32(thickness)
	push_data_f32(rotation)
	push_data_f32(pivot.x)
	push_data_f32(pivot.y)
	push_data_u32(packed_rgba)
}

draw_triangle_line :: proc {
	draw_triangle_line_f32,
	draw_triangle_line_f32_rot,
	draw_triangle_line_i32,
	draw_triangle_line_i32_rot,
}
