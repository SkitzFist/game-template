package input

@(private = "file")
pressed: bit_set[Mouse_Button]

@(private = "file")
held: bit_set[Mouse_Button]

@(private = "file")
released: bit_set[Mouse_Button]

mouse_x, mouse_y: f32

handle_mouse_pos :: proc(x, y: f32) {
	mouse_x, mouse_y = x, y
}

get_mouse_pos :: proc() -> (f32, f32) {
	return mouse_x, mouse_y
}

handle_mouse_button_pressed :: proc(button: Mouse_Button) {
	pressed += {button}
	held += {button}
}

handle_mouse_button_released :: proc(button: Mouse_Button) {
	pressed -= {button}
	held -= {button}
	released += {button}
}

@(private)
is_mouse_button_pressed :: proc(button: Mouse_Button) -> bool {
	return button in pressed
}

@(private)
is_mouse_button_held :: proc(button: Mouse_Button) -> bool {
	return button in held
}

@(private)
is_mouse_button_released :: proc(button: Mouse_Button) -> bool {
	return button in released
}

@(private)
mouse_post_frame :: proc() {
	pressed = {}
	released = {}
}

