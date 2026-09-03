#+build js wasm32
package game

import "base:runtime"
import "core:fmt"

import gfx "gfx_context"
import "window"

//Debug
import gl "vendor:wasm/WebGL"

web_context: runtime.Context
shader: gl.Program
buffer: gl.Buffer

Vertex :: struct {
	pos:   [3]f32,
	color: [4]u8,
}

triangle_vertices := [3]Vertex {
	{pos = {0.0, 0.5, 0.0}, color = {255, 0, 0, 255}},
	{pos = {0.5, -0.5, 0.0}, color = {0, 255, 0, 255}},
	{pos = {-0.5, -0.5, 0.0}, color = {0, 0, 255, 255}},
}

main :: proc() {

}

@(export)
web_init :: proc "c" () {
	context = init_default_context()
	web_context = context

	window.init()
	//input.init()

	window_response := window.create(
		"Game is the template",
		gfx.Config {
			api = .WEBGL,
			samples = 8,
			backend_config = gfx.WebGl_Config {
				canvas_name = "canvas",
				web_window_mode = .ASPECT_FILL,
				width = 1920,
				height = 1080,
				aspect_ratio = 1920 / 1080,
			},
		},
	)

	// REST HERE IS DEBUG should be refactored into render backened when window is done
	window_w, window_h := window.get_size()
	fmt.printfln(
		"Width: %v, Height: %v, window_w: %v, window_h: %v",
		window.width,
		window.height,
		window_w,
		window_h,
	)

	shader =
		gl.CreateProgramFromStrings({SHADER_VERT}, {SHADER_FRAG}) or_else panic(
			"Failed to load shader",
		)

	buffer = gl.CreateBuffer()
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(triangle_vertices),
		raw_data(&triangle_vertices),
		gl.DYNAMIC_DRAW,
	)

	attr_pos := gl.GetAttribLocation(shader, "in_position")
	gl.EnableVertexAttribArray(attr_pos)
	gl.VertexAttribPointer(attr_pos, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))

	attr_col := gl.GetAttribLocation(shader, "in_color")
	gl.EnableVertexAttribArray(attr_col)
	gl.VertexAttribPointer(
		attr_col,
		4,
		gl.UNSIGNED_BYTE,
		true,
		size_of(Vertex),
		offset_of(Vertex, color),
	)

	gl.Disable(gl.DEPTH_TEST)
	gl.Enable(gl.BLEND)
	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CW)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

}

@(export)
web_tick :: proc "c" (dt: f32) {
	context = web_context
	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(u32(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT))
	gl.UseProgram(shader)
	gl.DrawArrays(gl.TRIANGLES, 0, len(triangle_vertices))
}

@(export)
web_shutdown :: proc "c" () {
	context = web_context
	shutdown()
}


SHADER_VERT :: `
precision highp float;

attribute vec3 in_position;
attribute vec4 in_color;

varying vec4 color;

void main() {
	color = in_color;
	gl_Position = vec4(in_position, 1.0);
}
`

SHADER_FRAG :: `
precision highp float;

varying vec4 color;

void main() {
	gl_FragColor = color;
}
`
