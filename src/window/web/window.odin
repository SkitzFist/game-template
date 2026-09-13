#+build js wasm32, js wasm64p32
package web

import "base:runtime"
import "core:fmt"
import "core:sys/wasm/js"
import "core:time"
import gl "vendor:wasm/WebGL"

import gfx "../../gfx_context"
import "../../input"

import "core:unicode/utf8"

time_start: time.Time
canvas_id: string

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
	canvas_id = web_config.canvas_name

	on_framebuffer_resized_callback = on_framebuffer_resized

	set_title(title)

	gl.CreateCurrentContextById(canvas_id, gl.DEFAULT_CONTEXT_ATTRIBUTES)
	gl.SetCurrentContextById(canvas_id)

	if !gl.IsWebGL2Supported() {
		panic("Webgl2 is not supported")
	}

	// debug border
	js.set_element_style(canvas_id, "outline", "1px solid white")

	calculate_layout()

	// add callbacks
	js.add_window_event_listener(.Resize, nil, on_resize, false)
	js.add_window_event_listener(.Key_Down, nil, key_down_callback)
	js.add_window_event_listener(.Key_Up, nil, key_up_callback)
	js.add_window_event_listener(.Pointer_Move, nil, pointer_move_callback)
	js.add_window_event_listener(.Pointer_Down, nil, pointer_down_callbac)
	js.add_window_event_listener(.Pointer_Up, nil, pointer_up_callback)
	js.add_window_event_listener(
		.Context_Menu,
		nil,
		proc(event: js.Event) {if is_mouse_inside_canvas(event) {js.event_prevent_default()}},
	)

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
		js.set_element_style(canvas_id, "width", "100%")
		js.set_element_style(canvas_id, "height", "100%")
	case .FIXED:
		js.set_element_style(canvas_id, "width", fmt.tprintf("%.2fpx", web_config.width))
		js.set_element_style(canvas_id, "height", fmt.tprintf("%.2fpx", web_config.height))
	case .ASPECT_FIT:
		window_rect := js.window_get_rect()
		w, h := fit_aspect(
			f32(window_rect.width),
			f32(window_rect.height),
			web_config.aspect_ratio,
		)
		js.set_element_style(canvas_id, "width", fmt.tprintf("%.2fpx", w))
		js.set_element_style(canvas_id, "height", fmt.tprintf("%.2fpx", h))
	case .ASPECT_FILL:
		window_rect := js.window_get_rect()
		w, h := fill_aspect(
			f32(window_rect.width),
			f32(window_rect.height),
			web_config.aspect_ratio,
		)
		js.set_element_style(canvas_id, "width", fmt.tprintf("%.2fpx", w))
		js.set_element_style(canvas_id, "height", fmt.tprintf("%.2fpx", h))
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
	js.set_element_key_f64(canvas_id, "width", f64(w))
	js.set_element_key_f64(canvas_id, "height", f64(h))
}

get_time :: proc() -> f64 {
	return time.duration_seconds(time.diff(time_start, time.now()))
}

// returns framebuffer size
get_frame_buffer_size :: proc() -> (render_width, render_height: i32) {
	dpi := js.device_pixel_ratio()

	rect := js.get_bounding_client_rect(canvas_id)

	return i32(rect.width * dpi), i32(rect.height * dpi)
}

get_window_size :: proc() -> (width, height: i32) {
	rect := js.get_bounding_client_rect(canvas_id)

	return i32(rect.width), i32(rect.height)
}

// callbacks
on_resize :: proc(event: js.Event) {
	context = DEFAULT_CONTEXT

	w, h := calculate_layout()
	on_framebuffer_resized_callback(w, h)
}

@(private = "file")
KEY_BUF: [32]u8

@(private = "file")
get_decoded_rune :: proc(event: js.Event) -> (rune, int) {
	length := 0
	for b in event.key._key_buf {
		if b == 0 {break}
		length += 1
	}

	for i in 0 ..< length {
		KEY_BUF[i] = u8(event.key._key_buf[i])
	}

	count := utf8.rune_count(KEY_BUF[:length])
	char, _ := utf8.decode_rune(KEY_BUF[:length])
	return char, count
}

// ---- KEYBOARD ---- //

key_down_callback :: proc(event: js.Event) {
	context = DEFAULT_CONTEXT

	// js.Event.key.key can for instance be "shift",
	// by making sure the rune count is 1 (even if byte array is larger in size)
	// we make sure we don't end up with modifier key in char input
	char, count := get_decoded_rune(event)
	if count == 1 {
		input.on_char(char)
	}

	if event.key.repeat {return}
	if event.key.code not_in key_lookup {return}

	input.handle_on_press(key_lookup[event.key.code])
}

key_up_callback :: proc(event: js.Event) {
	context = DEFAULT_CONTEXT

	if event.key.code not_in key_lookup {return}

	input.handle_on_release(key_lookup[event.key.code])
}

// ---- MOUSE ---- //

is_mouse_inside_canvas :: proc(event: js.Event) -> bool {
	rect := js.get_bounding_client_rect(canvas_id)
	mouse_x, mouse_y := f64(event.mouse.client.x), f64(event.mouse.client.y)

	return(
		!(mouse_x < rect.x ||
			mouse_x > rect.x + rect.width ||
			mouse_y < rect.y ||
			mouse_y > rect.y + rect.height) \
	)
}

/*
	NOTE: When implementing touch, can use to event.mouse.pointer.pointer_type
		  to differentiate between mouse, touch and pen.
*/
pointer_move_callback :: proc(event: js.Event) {
	context = DEFAULT_CONTEXT

	rect := js.get_bounding_client_rect(canvas_id)
	x, y := f32(f64(event.mouse.client.x) - rect.x), f32(f64(event.mouse.client.y) - rect.y)

	input.handle_mouse_pos(x, y)
}

pointer_down_callbac :: proc(event: js.Event) {
	if event.mouse.button < 0 || event.mouse.button >= len(input.Mouse_Button) {
		panic("Button not supported")
	}

	input.handle_mouse_button_pressed(button_map[event.mouse.button])
}

pointer_up_callback :: proc(event: js.Event) {
	if event.mouse.button < 0 || event.mouse.button >= len(input.Mouse_Button) {
		panic("Button not supported")
	}

	input.handle_mouse_button_released(button_map[event.mouse.button])
}
