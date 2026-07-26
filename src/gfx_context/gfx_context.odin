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

Profile :: enum {
	NONE,
	CORE,
}

Version :: struct {
	major, minor: int,
}

Config :: struct {
	api:                Api,
	supported_versions: []Version,
	profile:            Profile,
	samples:            i32,
}

Framebuffer_Resize_Callback :: #type proc(width, height: i32)

Set_Proc_Address :: #type proc(p: rawptr, name: cstring)

// --- PLATFORM --- /
Platform :: enum {
	DESKTOP,
	WEB,
}

@(private)
PLATFORM_STR :: #config(PLATFORM, "DESKTOP")

when PLATFORM_STR == "DESKTOP" {
	PLATFORM :: Platform.DESKTOP
} else when PLATFORM_STR == "WEB" {
	PLATFORM :: Platform.WEB
} else {
	//fallback
	PLATFORM :: Platform.DESKTOP
}

