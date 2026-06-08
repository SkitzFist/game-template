#+build js wasm32
package game

import "base:runtime"

import "core:sys/wasm/js"
import "vendor:wasm/WebGL"

import "core:fmt"
import "core:log"

web_context: runtime.Context

// main :: proc() {
// 	fmt.println("WEB")
// 	js.add_window_event_listener(.Resize, nil, resize_callback)

// }

// resize_callback :: proc(event: js.Event) {
// 	fmt.println("Resize")
// }

/*
	WEB IS CURRENTLY NOT IMPLEMENTED, THIS IS LEFTOVERS FROM CANVAS2D IMPL
*/

main :: proc() {
	fmt.println("Main proc")
}

@(export)
web_init :: proc "c" () {
	context = init()
	web_context = context

	fmt.println("Fmt print")
	log.info("Log print")
}

// @(export)
// web_tick :: proc "c" (dt: f32) {
// 	context = web_context
// 	tick(dt)
// }

// @(export)
// web_shutdown :: proc "c" () {
// 	context = web_context
// 	shutdown()
// }

