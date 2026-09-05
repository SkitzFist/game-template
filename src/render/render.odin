package render

import gfx "../gfx_context"
import gl "opengl"
import "webgl"

render_width, render_height: f32

context_config :: proc() -> gfx.Config {
	when gfx.API == .OPENGL {
		return gl.context_config()
	} else when gfx.API == .WEBGL {
		// no impl
		return {
			api = .WEBGL,
			samples = 8,
			backend_config = gfx.WebGl_Config {
				canvas_name = "canvas",
				web_window_mode = .ASPECT_FIT,
				width = 1920,
				height = 1080,
				aspect_ratio = 1920 / 1080,
			},
		}
	}


	panic("API not implemented")
}

attach_context :: proc(width, height: i32, window_response: gfx.Window_Response) {
	render_width, render_height = f32(width), f32(height)

	when gfx.API == .OPENGL {
		gl.attach_context(width, height, window_response)
	} else when gfx.API == .WEBGL {
		webgl.attach_context(width, height, window_response)
	}
}

init :: proc() {
	vertex_init()

	when gfx.API == .OPENGL {
		gl.init(Vertex)
	} else when gfx.API == .WEBGL {
		webgl.init(Vertex)
	}

	font_init()

	cmd_buffer_init()
}

on_frame_buffer_size_changed: gfx.Framebuffer_Resize_Callback : proc(
	width, height, prev_width, prev_height: f32,
) {
	render_width, render_height = width, height
	when gfx.API == .OPENGL {
		gl.on_frame_buffer_size_changed(i32(width), i32(height))
	} else when gfx.API == .WEBGL {
		webgl.on_frame_buffer_size_changed(i32(width), i32(height))
	}
}

shutdown :: proc() {
	cmd_buffer_shutdown()
	font_shutdown()
	vertex_shutdown()

	when gfx.API == .OPENGL {
		gl.shutdown()
	} else when gfx.API == .WEBGL {
		webgl.shutdown()
	}
}

// ---- FRAME ----

draw_begin :: proc(time: f64) {
	vertex_begin_frame()

	when gfx.API == .OPENGL {
		gl.draw_begin(f32(time))
	} else when gfx.API == .WEBGL {
		webgl.draw_begin(f32(time))
	}
}

draw_end :: proc() {
	vertex_upload()
	draw_command_buffer()
}

clear_screen :: proc(color: Color) {
	when gfx.API == .OPENGL {
		gl.clear_screen(
			f32(color[0]) / 255.0,
			f32(color[1]) / 255.0,
			f32(color[2]) / 255.0,
			f32(color[3]) / 255.0,
		)
	} else when gfx.API == .WEBGL {
		webgl.clear_screen(
			f32(color[0]) / 255.0,
			f32(color[1]) / 255.0,
			f32(color[2]) / 255.0,
			f32(color[3]) / 255.0,
		)
	}
}
