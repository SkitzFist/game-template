package game

import str "stride:api"

PROJECT_NAME: cstring : "game_template"

MEM_TRACK :: #config(MEM_TRACK, true)

when str.RENDER_BACKEND == .OPENGL {
	CONFIG: str.Config : {api = .OPENGL, backend_config = str.OpenGl_Config{samples = 8}}
} else when str.RENDER_BACKEND == .WEBGL {

	CONFIG: str.Config : {
		api = .OPENGL,
		backend_config = str.WebGl_Config {
			canvas_id = "canvas",
			web_window_mode = .STRETCH,
			width = 1920,
			height = 1080,
			aspect_ratio = 1920 / 1080,
		},
	}
}
