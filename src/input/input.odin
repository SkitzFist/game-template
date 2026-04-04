package input

import "base:runtime"

DEFAULT_CONTEXT: runtime.Context

init :: proc() {
	DEFAULT_CONTEXT = context
}

post_frame :: proc() {
	keyboard_post_frame()
	mouse_post_frame()
}

is_pressed :: proc {
	is_key_pressed,
	is_mouse_button_pressed,
}

is_held :: proc {
	is_key_held,
	is_mouse_button_held,
}

is_released :: proc {
	is_key_released,
	is_mouse_button_released,
}

