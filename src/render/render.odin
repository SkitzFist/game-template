package render

import gl "opengl"

clear :: proc() {
	when BACKEND == .OPENGL {
		gl.clear()
	}
}

