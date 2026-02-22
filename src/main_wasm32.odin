package game

import "base:runtime"

web_context: runtime.Context

@(export)
web_init :: proc "c" () {
	context = init()
	web_context = context

	init_window()
}

@(export)
web_tick :: proc "c" (dt: f32) {
	context = web_context
	// tick(dt)
}

@(export)
web_shutdown :: proc "c" () {
	context = web_context
	shutdown()
}

