package gfx_context

API :: enum {
	OPENGL,
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

Set_Proc_Address :: #type proc(p: rawptr, name: cstring)
