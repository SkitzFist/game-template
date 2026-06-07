package window

import gfx "../gfx_context"
import "../platform"

import glfw "glfw"

width, height: f32

@(private)
framebuffer_resize_callback: gfx.Framebuffer_Resize_Callback

create_fullscreen :: proc(title: cstring, config: gfx.Config) {
	when platform.PLATFORM == .DESKTOP {
		success := glfw.create_fullscreen(title, config)
		if !success {
			panic("[WINDOW] could not create fullscreen")
		}
		w, h := glfw.get_size()
		width, height = f32(w), f32(h)
		return
	}

	panic("Platform not implemented")
}

destroy :: proc() {
	when platform.PLATFORM == .DESKTOP {
		glfw.destroy()
		return
	}
	panic("Platform not implemented")
}

set_framebuffer_resize_callback :: proc(callback: gfx.Framebuffer_Resize_Callback) {
	when platform.PLATFORM == .DESKTOP {
		framebuffer_resize_callback = callback
		glfw.set_framebuffer_resize_callback(on_framebuffer_resized)
		return
	}
	panic("Platform not implemented")
}

gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	when platform.PLATFORM == .DESKTOP {
		glfw.gl_set_proc_address(p, name)
		return
	}
	panic("Platform not implemented")
}

set_title :: proc(title: cstring) {
	when platform.PLATFORM == .DESKTOP {
		glfw.set_title(title)
		return
	}
	panic("Platform not implemented")
}

poll_events :: proc() {
	when platform.PLATFORM == .DESKTOP {
		glfw.poll_events()
		return
	}
	panic("Platform not implemented")
}

get_time :: proc() -> f64 {
	when platform.PLATFORM == .DESKTOP {
		return glfw.get_time()
	}

	panic("Platform not implemented")
}

should_close :: proc() -> b32 {
	when platform.PLATFORM == .DESKTOP {
		return glfw.should_close()
	}

	panic("Platform not implemented")
}

set_close :: proc(should_close: b32) {
	when platform.PLATFORM == .DESKTOP {
		glfw.set_close(should_close)
		return
	}
	panic("Platform not implemented")
}

// end of frame
swap_buffer :: proc() {
	when platform.PLATFORM == .DESKTOP {
		glfw.swap_buffer()
		return
	}
	panic("Platform not implemented")
}

get_size :: proc() -> (width, height: i32) {
	when platform.PLATFORM == .DESKTOP {
		return glfw.get_size()
	}

	panic("Platform not implemented")
}

@(private)
on_framebuffer_resized :: proc(w, h: i32) {
	width, height = f32(w), f32(h)
	if framebuffer_resize_callback != nil {
		framebuffer_resize_callback(w, h)
	}
}

