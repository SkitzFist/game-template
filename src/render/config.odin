package render

Backend :: enum {
	OPENGL,
}


BACKEND_STR :: #config(RENDER_BACKEND, "OPENGL")

when BACKEND_STR == "OPENGL" {
	BACKEND :: Backend.OPENGL
}

