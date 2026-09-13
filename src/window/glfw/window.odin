package glfw_i

import "base:runtime"
import "core:log"
import "vendor:glfw"

import gfx "../../gfx_context"
import "../../input"

@(private)
window_handle: glfw.WindowHandle

@(private)
DEFAULT_CONTEXT: runtime.Context

@(private)
on_framebuffer_resized_callback: proc(width, height: i32)

create :: proc(
	title: cstring,
	config: gfx.Config,
	on_framebuffer_resized: proc(width, height: i32),
	fullscreen: bool = true,
) -> (
	version: gfx.Window_Response,
	success: bool,
) {
	//store odin context so we can use it in proc "c" functions
	DEFAULT_CONTEXT = context

	on_framebuffer_resized_callback = on_framebuffer_resized
	glfw.SetErrorCallback(error_callback)

	if !glfw.Init() {
		log.info("[GLFW] Failed to init")
		return {}, false
	}

	monitor := glfw.GetPrimaryMonitor()
	mode := glfw.GetVideoMode(monitor)
	glfw.WindowHint(glfw.RED_BITS, mode.red_bits)
	glfw.WindowHint(glfw.GREEN_BITS, mode.green_bits)
	glfw.WindowHint(glfw.BLUE_BITS, mode.blue_bits)
	glfw.WindowHint(glfw.REFRESH_RATE, mode.refresh_rate)

	if config.samples > 0 {
		glfw.WindowHint(glfw.SAMPLES, config.samples)
	}

	// REMINDER: this needs to change when vulkan support is added
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window_handle = nil
	accepted_version: gfx.Version = {0, 0}

	switch backend_config in config.backend_config {
	case gfx.WebGl_Config:
		panic("[GLFW] Does not support WebGl config")
	case gfx.OpenGl_Config:
		for version in backend_config.supported_versions {
			glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, i32(version.major))
			glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, i32(version.minor))
			window_handle = glfw.CreateWindow(mode.width, mode.height, title, nil, nil)

			if window_handle != nil {
				accepted_version = version
				break
			}

			log.infof("[GLFW] failed creating window with version: %v", version)
		}

	}

	if window_handle == nil {
		panic("[GLFW] failed to create window handle")
	}

	if fullscreen {
		glfw.SetWindowMonitor(
			window_handle,
			monitor,
			0,
			0,
			mode.width,
			mode.height,
			mode.refresh_rate,
		)
	} else {
		glfw.SetWindowMonitor(window_handle, nil, 0, 0, 1280, 720, mode.refresh_rate)
	}

	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)

	glfw.SetKeyCallback(window_handle, key_callback)
	glfw.SetCharCallback(window_handle, char_callback)

	glfw.SetCursorPosCallback(window_handle, cursor_pos_callback)
	glfw.SetMouseButtonCallback(window_handle, mouse_button_callback)
	glfw.SetScrollCallback(window_handle, mouse_scroll_callback)
	glfw.SetFramebufferSizeCallback(window_handle, frame_buffer_size_callback)

	log.info("[GLFW] created window with version:", accepted_version)

	response: gfx.Window_Response = gfx.Window_OpenGl_Response {
		accepted_version = accepted_version,
		set_proc_address = glfw.gl_set_proc_address,
	}

	return response, true
}

set_title :: proc(title: cstring) {
	glfw.SetWindowTitle(window_handle, title)
}

destroy :: proc() {
	glfw.DestroyWindow(window_handle)
	glfw.Terminate()
	log.info("[GLFW] destroyed & Terminated")
}

// TODO this is
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

get_frame_buffer_size :: proc() -> (width, height: i32) {
	return glfw.GetFramebufferSize(window_handle)
}

print_frame_size :: proc() {
	log.info("[GLFW] Frame size:", glfw.GetWindowFrameSize(window_handle))
}

@(private)
error_callback: glfw.ErrorProc = proc "c" (error: i32, description: cstring) {
	context = DEFAULT_CONTEXT
	log.error("[GLFW] error:", description)
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
		panic("[GLFW] Unsupported button")
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
	log.info("[GLFW](mouse_scroll_callback): xOffset:", xOffset, ", yOffset:", yOffset)
}

@(private)
frame_buffer_size_callback: glfw.FramebufferSizeProc : proc "c" (
	window: glfw.WindowHandle,
	width, height: i32,
) {
	context = DEFAULT_CONTEXT

	log.infof("[GLFW] frame buffer size changed: %vx%v", width, height)

	on_framebuffer_resized_callback(width, height)
}
