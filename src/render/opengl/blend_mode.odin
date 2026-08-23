package opengl

import gl "vendor:OpenGL"

import gfx "../../gfx_context"

set_blend_mode :: proc(blend_mode: gfx.Blend_Mode) {
	switch blend_mode {
	case .NONE:
		gl.Disable(gl.BLEND)
	case .ALPHA:
		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.FUNC_ADD)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	case .ADDITIVE:
		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.FUNC_ADD)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	case .MULTIPLY:
		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.FUNC_ADD)
		gl.BlendFunc(gl.DST_COLOR, gl.ZERO)
	case .PREMULTIPLIED:
		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.FUNC_ADD)
		gl.BlendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
	case .SUBTRACT:
		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.FUNC_REVERSE_SUBTRACT)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	}

}

