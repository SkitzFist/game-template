package window

import "core:log"

import gfx "../gfx_context"
import glfw "glfw"
import web "web"

/*

	TODO: move over to handle -> resource architecture
		  will also support multi window when that is done

*/

prev_width, prev_height: f32
width, height: f32

resize_callbacks: [dynamic]gfx.Framebuffer_Resize_Callback

init :: proc() {
	cache_line_fit := 64 / size_of(gfx.Framebuffer_Resize_Callback)
	resize_callbacks = make(
		[dynamic]gfx.Framebuffer_Resize_Callback,
		0,
		cache_line_fit,
		context.allocator,
	)
}

create :: proc(
	title: cstring,
	config: gfx.Config,
	fullscreen: bool = true,
) -> gfx.Window_Response {
	when gfx.PLATFORM == .DESKTOP {
		response, success := glfw.create(title, config, on_framebuffer_resized, fullscreen)
		if !success {
			panic("[WINDOW] could not create window")
		}
		w, h := glfw.get_size()
		width, height = f32(w), f32(h)
		return response
	} else when gfx.PLATFORM == .WEB {
		response := web.create(title, config, on_framebuffer_resized, fullscreen)
		w, h := web.get_frame_buffer_size()
		width, height = f32(w), f32(h)
		return response
	}

	panic("Platform not implemented")
}

shutdown :: proc() {
	when gfx.PLATFORM == .DESKTOP {
		glfw.destroy()
	} else when gfx.PLATFORM == .WEB {
		web.shutdown()
	}

	delete(resize_callbacks)
}

set_title :: proc(title: cstring) {
	when gfx.PLATFORM == .DESKTOP {
		glfw.set_title(title)
		return
	} else when gfx.PLATFORM == .WEB {
		web.set_title(title)
		return
	}
	panic("Platform not implemented")
}

poll_events :: proc() {
	when gfx.PLATFORM == .DESKTOP {
		glfw.poll_events()
		return
	} else when gfx.PLATFORM == .WEB {
		// no op
		return
	}
	panic("Platform not implemented")
}

get_time :: proc() -> f64 {
	when gfx.PLATFORM == .DESKTOP {
		return glfw.get_time()
	} else when gfx.PLATFORM == .WEB {
		return web.get_time()
	}

	panic("Platform not implemented")
}

should_close :: proc() -> b32 {
	when gfx.PLATFORM == .DESKTOP {
		return glfw.should_close()
	} else when gfx.PLATFORM == .WEB {
		// Does not apply to WEB
		return false
	}

	panic("Platform not implemented")
}

set_close :: proc(should_close: b32) {
	when gfx.PLATFORM == .DESKTOP {
		glfw.set_close(should_close)
		return
	} else when gfx.PLATFORM == .WEB {
		// no op
		return
	}
	panic("Platform not implemented")
}

// TODO: Swap buffer is glfw/opengl concept, but too son to abstract away.
// end of frame
swap_buffer :: proc() {
	when gfx.PLATFORM == .DESKTOP {
		glfw.swap_buffer()
		return
	} else when gfx.PLATFORM == .WEB {
		// no op
		return
	}
	panic("Platform not implemented")
}

/*
	returns actual window size instead of framebuffer size
	For web it returns canvas css size
*/
get_size :: proc() -> (width, height: i32) {
	when gfx.PLATFORM == .DESKTOP {
		return glfw.get_size()
	} else when gfx.PLATFORM == .WEB {
		return web.get_window_size()
	}

	panic("Platform not implemented")
}

@(private)
on_framebuffer_resized :: proc(w, h: i32) {
	prev_width, prev_height = width, height
	width, height = f32(w), f32(h)

	log.infof("[WINDOW] resized from %vx%v to %vx%v", prev_width, prev_height, width, height)

	for callback in resize_callbacks {
		callback(width, height, prev_width, prev_height)
	}
}
