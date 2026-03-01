#+build wasm32
package render_backend

import "core:log"

// WINDOW
init_window :: #force_inline proc(width, height: i32, window_title: cstring) {
}

should_close :: #force_inline proc() -> bool {
	return false
}

// DRAWING
begin_drawing :: #force_inline proc() {
}

end_drawing :: #force_inline proc() {
}

clear_background :: #force_inline proc(r, g, b, a: u8) {
}

