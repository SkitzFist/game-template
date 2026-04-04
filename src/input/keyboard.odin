package input

@(private = "file")
pressed: bit_set[Key]
@(private = "file")
held: bit_set[Key]
@(private = "file")
released: bit_set[Key]

char: rune
has_char: bool

handle_on_press :: proc(key: Key) {
	pressed += {key}
	held += {key}
}

handle_on_release :: proc(key: Key) {
	pressed -= {key}
	held -= {key}
	released += {key}
}

@(private)
is_key_pressed :: proc(key: Key) -> bool {
	return key in pressed
}

@(private)
is_key_released :: proc(key: Key) -> bool {
	return key in released
}

@(private)
is_key_held :: proc(key: Key) -> bool {
	return key in held
}

on_char :: proc(codepoint: rune) {
	char = codepoint
	has_char = true
}

keyboard_post_frame :: proc() {
	pressed = {}
	released = {}
	has_char = false
}

