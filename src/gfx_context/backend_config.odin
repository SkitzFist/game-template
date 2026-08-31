package gfx_context

Config :: struct {
	api:            Api,
	samples:        i32,
	backend_config: Backend_Config,
}

Backend_Config :: union #no_nil {
	OpenGl_Config,
	WebGl_Config,
}

Window_Response :: union {
	Window_OpenGl_Response,
	Window_WebGl_Response,
}

// ---- OPENGL ---- //
Version :: struct {
	major, minor: int,
}

OpenGl_Config :: struct {
	supported_versions: []Version,
}

Set_Proc_Address :: #type proc(p: rawptr, name: cstring)
Window_OpenGl_Response :: struct {
	accepted_version: Version,
	set_proc_address: Set_Proc_Address,
}

// ---- WEB GL ---- //
WebGl_Config :: struct {}
Window_WebGl_Response :: struct {}
