package opengl

import "core:log"
import gl "vendor:OpenGL"

BUF_SIZE :: 2048
ERROR_BUFFER: [BUF_SIZE]u8
LENGTH: i32

@(private)
create_shader_u8 :: proc(vert: []u8, frag: []u8) -> u32 {
	vs := gl.CreateShader(gl.VERTEX_SHADER)
	src := cstring(raw_data(vert[:]))
	compile_shader(vs, &src, i32(len(src)))
	defer gl.DeleteShader(vs)

	fs := gl.CreateShader(gl.FRAGMENT_SHADER)
	src = cstring(raw_data(frag[:]))
	compile_shader(fs, &src, i32(len(src)))
	defer gl.DeleteShader(fs)

	program := gl.CreateProgram()
	gl.AttachShader(program, vs)
	gl.AttachShader(program, fs)
	gl.LinkProgram(program)

	status: i32

	gl.GetProgramiv(program, gl.LINK_STATUS, &status)

	if status == 0 {
		gl.GetProgramInfoLog(program, BUF_SIZE, &LENGTH, raw_data(ERROR_BUFFER[:]))
		log.error(TAG, "Failed compiling shader:", string(ERROR_BUFFER[:LENGTH]))
		panic("Failed to link shader")
	}

	return program
}

@(private = "file")
compile_shader :: proc(shader: u32, src: [^]cstring, size: i32) {
	size: i32 = size
	gl.ShaderSource(shader, 1, src, &size)
	gl.CompileShader(shader)

	status: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status)
	if status == 0 {
		gl.GetShaderInfoLog(shader, BUF_SIZE, &LENGTH, raw_data(ERROR_BUFFER[:]))
		log.error(TAG, "Failed compiling shader:", string(ERROR_BUFFER[:LENGTH]))
	}
}
