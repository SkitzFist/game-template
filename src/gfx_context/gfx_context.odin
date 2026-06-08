package gfx_context
wall, tex2: u32

API :: enum {
	OPENGL,
	WEBGL,
}

Profile :: enum {
	NONE,
	CORE,
}

Config :: struct {
	api:           API,
	major_version: i32,
	minor_version: i32,
	profile:       Profile,
	samples:       i32,
}

Framebuffer_Resize_Callback :: #type proc(width, height: i32)

Set_Proc_Address :: #type proc(p: rawptr, name: cstring)

