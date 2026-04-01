package window

import "core:log"
import "vendor:glfw"

import "../render"

@(private)
window_handle: glfw.WindowHandle

create :: proc(width, height: i32, title: cstring) -> (success: bool) {
	if !bool(glfw.Init()) {
		log.info("[WINDOW] GLFW Failed to init")
		return false
	}

	render.pre_window_create()
	window_handle = glfw.CreateWindow(width, height, title, nil, nil)

	if window_handle == nil {
		log.info("[WINDOW] GLFW failed to create window handle")
		return false
	}

	render.attach_to_window(window_handle)

	// awaits one frame before swapping buffers, helps against tearing
	glfw.SwapInterval(1)

	log.info("[WINDOW] created")

	return true
}

destroy :: proc() {
	glfw.DestroyWindow(window_handle)
	glfw.Terminate()
	log.info("[WINDOW] destroyed")
}

poll_events :: proc() {
	glfw.PollEvents()
}

should_close :: proc() -> b32 {
	return glfw.WindowShouldClose(window_handle)
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

