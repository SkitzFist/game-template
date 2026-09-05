#+build js wasm32
package web

import "base:runtime"
import "core:fmt"
import "core:sys/wasm/js"
import "core:time"
import gl "vendor:wasm/WebGL"

import gfx "../../gfx_context"
import "../../input"


time_start: time.Time
canvas_name: string

web_config: gfx.WebGl_Config
on_framebuffer_resized_callback: proc(width, height: i32)

DEFAULT_CONTEXT: runtime.Context

create :: proc(
	title: cstring,
	config: gfx.Config,
	on_framebuffer_resized: proc(width, height: i32),
	fullscreen: bool = true,
) -> gfx.Window_Response {
	DEFAULT_CONTEXT = context

	web_config = config.backend_config.(gfx.WebGl_Config)
	canvas_name = web_config.canvas_name

	on_framebuffer_resized_callback = on_framebuffer_resized

	set_title(title)

	gl.CreateCurrentContextById(canvas_name, gl.DEFAULT_CONTEXT_ATTRIBUTES)
	gl.SetCurrentContextById(canvas_name)

	if !gl.IsWebGL2Supported() {
		panic("Webgl2 is not supported")
	}

	// debug border
	js.set_element_style(canvas_name, "outline", "1px solid white")

	calculate_layout()

	// add callbacks
	js.add_window_event_listener(.Resize, nil, on_resize, false)

	time_start = time.now()
	return gfx.Window_WebGl_Response{}
}

shutdown :: proc() {
	js.remove_window_event_listener(.Resize, nil, on_resize)
}

set_title :: proc(title: cstring) {
	js.set_document_title(string(title))
}

/*
	Calculates css layout of canvas,
	also sets the framebuffer size and correct webgl viewport

	returns framebuffer size out of convenience, even if it would
	be more correct to return layout size
*/
calculate_layout :: proc() -> (width, height: i32) {
	switch (web_config.web_window_mode) {
	case .STRETCH:
		js.set_element_style(canvas_name, "width", "100%")
		js.set_element_style(canvas_name, "height", "100%")
	case .FIXED:
		js.set_element_style(canvas_name, "width", fmt.tprintf("%.2fpx", web_config.width))
		js.set_element_style(canvas_name, "height", fmt.tprintf("%.2fpx", web_config.height))
	case .ASPECT_FIT:
		window_rect := js.window_get_rect()
		w, h := fit_aspect(
			f32(window_rect.width),
			f32(window_rect.height),
			web_config.aspect_ratio,
		)
		js.set_element_style(canvas_name, "width", fmt.tprintf("%.2fpx", w))
		js.set_element_style(canvas_name, "height", fmt.tprintf("%.2fpx", h))
	case .ASPECT_FILL:
		window_rect := js.window_get_rect()
		w, h := fill_aspect(
			f32(window_rect.width),
			f32(window_rect.height),
			web_config.aspect_ratio,
		)
		js.set_element_style(canvas_name, "width", fmt.tprintf("%.2fpx", w))
		js.set_element_style(canvas_name, "height", fmt.tprintf("%.2fpx", h))
	}

	w, h := get_frame_buffer_size()
	resize_frame_buffer(w, h)

	return w, h
}

fit_aspect :: proc(container_width, container_height, aspect_ratio: f32) -> (width, height: f32) {
	container_aspect := container_width / container_height

	if container_aspect > aspect_ratio {
		height = container_height
		width = height * aspect_ratio
	} else {
		width = container_width
		height = width / aspect_ratio
	}

	return width, height
}

fill_aspect :: proc(container_width, container_height, aspect_ratio: f32) -> (width, height: f32) {
	container_aspect := container_width / container_height

	if container_aspect > aspect_ratio {
		width = container_width
		height = width / aspect_ratio
	} else {
		height = container_height
		width = height * aspect_ratio
	}

	return width, height
}

resize_frame_buffer :: proc(w, h: i32) {
	js.set_element_key_f64(canvas_name, "width", f64(w))
	js.set_element_key_f64(canvas_name, "height", f64(h))
}

get_time :: proc() -> f64 {
	return time.duration_seconds(time.diff(time_start, time.now()))
}

// returns framebuffer size
get_frame_buffer_size :: proc() -> (render_width, render_height: i32) {
	dpi := js.device_pixel_ratio()

	rect := js.get_bounding_client_rect(canvas_name)

	return i32(rect.width * dpi), i32(rect.height * dpi)
}

get_window_size :: proc() -> (width, height: i32) {
	rect := js.get_bounding_client_rect(canvas_name)

	return i32(rect.width), i32(rect.height)
}

// callbacks
on_resize :: proc(event: js.Event) {
	context = DEFAULT_CONTEXT

	w, h := calculate_layout()
	on_framebuffer_resized_callback(w, h)
}
