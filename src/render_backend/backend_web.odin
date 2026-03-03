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
	CLEAR_BACKGROUND = 1,
	DRAW_RECTANGLE   = 2,
	DRAW_CIRCLE      = 3,
	DRAW_LINE        = 4,
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

draw_rectangle :: #force_inline proc(rect: Rectangle, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_RECTANGLE, 5)
	push_data_i32(rect.x)
	push_data_i32(rect.y)
	push_data_i32(rect.width)
	push_data_i32(rect.height)
	push_data_u32(packed_rgba)
}

draw_circle :: #force_inline proc(center: Vector2I, radius: f32, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_CIRCLE, 4)
	push_data_i32(center.x)
	push_data_i32(center.y)
	push_data_f32(radius)
	push_data_u32(packed_rgba)
}

draw_line :: #force_inline proc(start, end: Vector2I, thickness: f32, color: Color) {
	packed_rgba := pack_rgba(color)
	push_command_header(.DRAW_LINE, 6)
	push_data_i32(start.x)
	push_data_i32(start.y)
	push_data_i32(end.x)
	push_data_i32(end.y)
	push_data_f32(thickness)
	push_data_u32(packed_rgba)
}
