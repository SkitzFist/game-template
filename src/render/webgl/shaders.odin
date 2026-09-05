#+build js wasm32
package webgl_backend

import gl "vendor:wasm/WebGL"

BUF_SIZE :: 2048
ERROR_BUFFER: [BUF_SIZE]u8
LENGTH: i32

@(private)
create_shader_u8 :: proc(vert: []u8, frag: []u8) -> gl.Program {
	program :=
		gl.CreateProgramFromStrings([]string{string(vert)}, []string{string(frag)}) or_else panic(
			"Could not create shader",
		)

	globals := gl.GetUniformBlockIndex(program, "GlobalData")
	if globals >= 0 {
		gl.UniformBlockBinding(program, globals, 0)
	}

	return program
}

// @(private = "file")
// compile_shader :: proc(shader: u32, src: [^]cstring, size: i32) {
// 	size: i32 = size
// 	gl.ShaderSource(shader, 1, src, &size)
// 	gl.CompileShader(shader)

// 	status: i32
// 	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status)
// 	if status == 0 {
// 		gl.GetShaderInfoLog(shader, BUF_SIZE, &LENGTH, raw_data(ERROR_BUFFER[:]))
// 		log.error(TAG, "Failed compiling shader:", string(ERROR_BUFFER[:LENGTH]))
// 	}
// }
