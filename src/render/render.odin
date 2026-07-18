package render

import "../gfx_context"
import gl "opengl"

// ---- WINDOW ---- //
context_config :: proc() -> gfx_context.Config {
	when BACKEND == .OPENGL {
		return gl.context_config()
	} else when BACKEND == .WEBGL {
		//no impl yet
		return {}
	}
}

attach_context :: proc(width, height: i32, set_proc_address: gfx_context.Set_Proc_Address) {
	when BACKEND == .OPENGL {
		gl.attach_context(width, height, set_proc_address)
	}
}

init :: proc() {
	when BACKEND == .OPENGL {
		gl.init()
	} else when BACKEND == .WEBGL {
		//no impl yet
	}

	//debug
	load_font("assets/fonts/roboto.ttf")

	cmd_buffer_init()
}

on_frame_buffer_size_changed :: proc(width, height: i32) {
	when BACKEND == .OPENGL {
		gl.on_frame_buffer_size_changed(width, height)
	} else when BACKEND == .WEBGL {
		//no impl yet
	}
}

shutdown :: proc() {
	when BACKEND == .OPENGL {
		gl.shutdown()
	} else when BACKEND == .WEBGL {
		//no impl yet
	}

	cmd_buffer_shutdown()
}

// ---- FRAME ----

draw_begin :: proc(time: f64) {
	when BACKEND == .OPENGL {
		gl.draw_begin(f32(time))
	} else when BACKEND == .WEBGL {
		//no impl yet
	}
}

draw_end :: proc() {
	when BACKEND == .OPENGL {
		gl.draw_end()
	} else when BACKEND == .WEBGL {
		//no impl yet
	}
	draw_command_buffer()
}

clear_screen :: proc(color: Color) {
	when BACKEND == .OPENGL {
		gl.clear_screen(
			f32(color[0]) / 255.0,
			f32(color[1]) / 255.0,
			f32(color[2]) / 255.0,
			f32(color[3]) / 255.0,
		)
	} else when BACKEND == .WEBGL {
		//no impl yet
	}
}

