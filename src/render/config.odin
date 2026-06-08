package render

Backend :: enum {
	OPENGL,
	WEBGL,
}


BACKEND_STR :: #config(RENDER_BACKEND, "OPENGL")

when BACKEND_STR == "OPENGL" {
	BACKEND :: Backend.OPENGL
} else when BACKEND_STR == "WEBGL" {
	BACKEND :: Backend.WEBGL
} else {
	//fallback to openGL
	BACKEND :: Backend.OPENGL
}

