package window

import "base:runtime"
import "core:log"
import "vendor:glfw"

import "../input"
import "../render"

//debug
import "core:fmt"

@(private)
window_handle: glfw.WindowHandle

@(private)
DEFAULT_CONTEXT: runtime.Context

create :: proc(width, height: i32, title: cstring) -> (success: bool) {
	//store odin context so we can use it in proc "c" functions
	DEFAULT_CONTEXT = context

	glfw.SetErrorCallback(error_callback)

	if !bool(glfw.Init()) {
		log.info("[WINDOW] GLFW Failed to init")
		return false
	}

	render.pre_window_create()

	// debug, send to my portrait mode monitor
	monitor := glfw.GetMonitors()[1]

	window_handle = glfw.CreateWindow(width, height, title, monitor, nil)
	if window_handle == nil {
		log.info("[WINDOW] GLFW failed to create window handle")
		return false
	}

	// glfw.SetWindowMonitor(window_handle, nil, 0, 0, width - 100, height - 100, 144)

	render.attach_to_window(window_handle)
	glfw.SwapInterval(1)

	//hook up input
	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetCharCallback(window_handle, char_callback)
	glfw.SetCursorPosCallback(window_handle, cursor_pos_callback)
	glfw.SetMouseButtonCallback(window_handle, mouse_button_callback)
	glfw.SetScrollCallback(window_handle, mouse_scroll_callback)

	log.info("[WINDOW] created")

	return true
}

set_title :: proc(title: cstring) {
	glfw.SetWindowTitle(window_handle, title)
}

destroy :: proc() {
	glfw.DestroyWindow(window_handle)
	glfw.Terminate()
	log.info("[WINDOW] destroyed")
}

poll_events :: proc() {
	glfw.PollEvents()
}

get_time :: proc() -> f64 {
	return glfw.GetTime()
}

should_close :: proc() -> b32 {
	return glfw.WindowShouldClose(window_handle)
}

set_close :: proc(should_close: b32) {
	glfw.SetWindowShouldClose(window_handle, should_close)
}

swap_buffer :: proc() {
	glfw.SwapBuffers(window_handle)
}

get_size :: proc() -> (width, height: i32) {
	return glfw.GetWindowSize(window_handle)
}

print_frame_size :: proc() {
	log.info("[WINDOW] Frame size:", glfw.GetWindowFrameSize(window_handle))
}

@(private)
error_callback: glfw.ErrorProc = proc "c" (error: i32, description: cstring) {
	context = DEFAULT_CONTEXT
	log.error("[WINDOW] error:", description)
}

// ---- KEYBOARD
@(private)
key_callback: glfw.KeyProc : proc "c" (
	window: glfw.WindowHandle,
	key, scancode, action, mods: i32,
) {
	context = DEFAULT_CONTEXT

	if key == glfw.KEY_UNKNOWN {
		return
	}

	// fmt.println("key:", key, "scancode:", scancode, "action:", action, "mods:", mods)

	switch action {
	case glfw.PRESS:
		input.handle_on_press(key_lookup[key])
	case glfw.RELEASE:
		input.handle_on_release(key_lookup[key])
	case glfw.REPEAT:
	// Repeat/held/down is handled internally in input/keyboard.odin
	// input.handle_on_held(key_lookup[key])
	}
}

@(private)
char_callback: glfw.CharProc : proc "c" (window: glfw.WindowHandle, codepoint: rune) {
	context = DEFAULT_CONTEXT

	input.on_char(codepoint)
}


// ---- MOUSE ---- //
@(private)
cursor_pos_callback: glfw.CursorPosProc : proc "c" (window: glfw.WindowHandle, x, y: f64) {
	context = DEFAULT_CONTEXT

	input.handle_mouse_pos(f32(x), f32(y))
}

@(private)
mouse_button_callback: glfw.MouseButtonProc : proc "c" (
	window: glfw.WindowHandle,
	button, action, mods: i32,
) {
	context = DEFAULT_CONTEXT
	fmt.println("button:", button, "action:", action, "mods:", mods)

	if button < 0 || button > 4 {
		panic("Unsupported button")
	}

	switch action {
	case glfw.PRESS:
		input.handle_mouse_button_pressed(mouse_button_lookup[button])
	case glfw.RELEASE:
		input.handle_mouse_button_released(mouse_button_lookup[button])

	}
}

@(private)
mouse_scroll_callback: glfw.ScrollProc : proc "c" (
	window: glfw.WindowHandle,
	xOffset, yOffset: f64,
) {
	context = DEFAULT_CONTEXT
	log.info("[Window](mouse_scroll_callback): xOffset:", xOffset, ", yOffset:", yOffset)
}

