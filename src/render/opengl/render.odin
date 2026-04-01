package opengl

import gl "vendor:OpenGL"

clear :: proc() {
	gl.ClearColor(0, 0, 0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

