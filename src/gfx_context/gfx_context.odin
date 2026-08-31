package gfx_context
wall, tex2: u32

Api :: enum {
	OPENGL,
	WEBGL,
}

API_STR :: #config(RENDER_API, "OPENGL")

when API_STR == "OPENGL" {
	API :: Api.OPENGL
} else when API_STR == "WEBGL" {
	API :: Api.WEBGL
} else {
	//fallback to openGL
	API :: Api.OPENGL
}


Framebuffer_Resize_Callback :: #type proc(width, height, prev_width, prev_height: f32)


// ---- BLEND MODE ---- //
Blend_Mode :: enum u8 {
	NONE,
	ALPHA,
	ADDITIVE,
	// NOTE: Current OpenGL multiply blend ignores source alpha.
	MULTIPLY,
	PREMULTIPLIED,
	SUBTRACT,
}

DEFAULT_BLEND_MODE: Blend_Mode = .ALPHA
