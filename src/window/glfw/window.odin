package glfw_i

import "base:runtime"
import "core:log"
import "vendor:glfw"

import gfx "../../gfx_context"
import "../../input"

//debug
import "core:fmt"

@(private)
window_handle: glfw.WindowHandle

@(private)
DEFAULT_CONTEXT: runtime.Context

width, height: i32

@(private)
framebuffer_resize_callback: gfx.Framebuffer_Resize_Callback

create_fullscreen :: proc(title: cstring, config: gfx.Config) -> (success: bool) {
	//store odin context so we can use it in proc "c" functions
	DEFAULT_CONTEXT = context

	glfw.SetErrorCallback(error_callback)

	if !bool(glfw.Init()) {
		log.info("[WINDOW] GLFW Failed to init")
		return false
	}

	apply_context_config(config)

	monitor := glfw.GetPrimaryMonitor()
	mode := glfw.GetVideoMode(monitor)
	glfw.WindowHint(glfw.RED_BITS, mode.red_bits)
	glfw.WindowHint(glfw.GREEN_BITS, mode.green_bits)
	glfw.WindowHint(glfw.BLUE_BITS, mode.blue_bits)
	glfw.WindowHint(glfw.REFRESH_RATE, mode.refresh_rate)

	window_handle = glfw.CreateWindow(mode.width, mode.height, title, monitor, nil)
	if window_handle == nil {
		log.info("[WINDOW] GLFW failed to create window handle")
		return false
	}

	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)

	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetCharCallback(window_handle, char_callback)
	glfw.SetCursorPosCallback(window_handle, cursor_pos_callback)
	glfw.SetMouseButtonCallback(window_handle, mouse_button_callback)
	glfw.SetScrollCallback(window_handle, mouse_scroll_callback)
	glfw.SetFramebufferSizeCallback(window_handle, frame_buffer_size_callback)

	width, height = glfw.GetFramebufferSize(window_handle)

	log.info("[WINDOW] created")

	return true
}

set_framebuffer_resize_callback :: proc(callback: gfx.Framebuffer_Resize_Callback) {
	framebuffer_resize_callback = callback
}

gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	glfw.gl_set_proc_address(p, name)
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
	return width, height
}

@(private)
apply_context_config :: proc(config: gfx.Config) {
	switch config.api {
	case .OPENGL:
		glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, config.major_version)
		glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, config.minor_version)

		if config.profile == .CORE {
			glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
		}
	case .WEBGL:
	//no impl yet
	}

	if config.samples > 0 {
		glfw.WindowHint(glfw.SAMPLES, config.samples)
	}
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
	// fmt.println("button:", button, "action:", action, "mods:", mods)

	if button < 0 || button >= len(input.Mouse_Button) {
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

@(private)
frame_buffer_size_callback: glfw.FramebufferSizeProc : proc "c" (
	window: glfw.WindowHandle,
	w, h: i32,
) {
	context = DEFAULT_CONTEXT

	log.info("frame buffer size changed:", width, ",", height)
	width, height = w, h
	if framebuffer_resize_callback != nil {
		framebuffer_resize_callback(width, height)
	}
}

