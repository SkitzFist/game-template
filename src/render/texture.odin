package render

import "vendor:stb/image"

import gl "opengl"

//debug
import "core:log"

Texture_Format :: enum u32 {
	GRAY,
	GRAY_ALPHA,
	RGB,
	RGBA,
}

texture_format_from_stb_channels :: proc(channels: i32) -> (format: Texture_Format) {
	switch channels {
	case 1:
		return .GRAY
	case 2:
		return .GRAY_ALPHA
	case 3:
		return .RGB
	case 4:
		return .RGBA
	}

	panic("[RENDER] Unsuported pixel format")
}

// Pixel_Buffer_Entry :: struct {
// 	start, end: u32,
// }

/*
	Textures
	+----+-------+--------+--------+--------------------+
	| ID | width | height | format | pixel_buffer_entry |
	+----+-------+--------+--------+--------------------+

	Pixel_Buffer
*/

// TODO this is just tmp until my custom buffer is implemented
MAX_TEXTURES :: 10
texture_ids: [MAX_TEXTURES]u32
texture_widths: [MAX_TEXTURES]i32
texture_heights: [MAX_TEXTURES]i32
texture_formats: [MAX_TEXTURES]Texture_Format
// texture_pixels: [MAX_TEXTURES]Pixel_Buffer_Entry
occupied: [MAX_TEXTURES]bool

get_next_free_index :: proc() -> u32 {
	for i in 0 ..< MAX_TEXTURES {
		if occupied[i] == false {
			return u32(i)
		}
	}

	panic("No unnoccupied texture slot, time to implement membuffer")
}

load_texture :: proc(path: cstring) -> u32 {
	when BACKEND == .OPENGL {
		width, height, channels: i32
		image.set_flip_vertically_on_load(1)
		img_data := image.load(path, &width, &height, &channels, 0)
		if img_data == nil {
			log.error("Failed to load image:", path, image.failure_reason())
			panic("failed image load")
		}
		defer image.image_free(img_data)

		format := texture_format_from_stb_channels(channels)
		log.info("Image loaded:", path, width, height, format)

		index := get_next_free_index()
		occupied[index] = true

		texture_ids[index] = gl.load_texture(img_data, width, height, u32(format))
		texture_widths[index] = width
		texture_heights[index] = height
		texture_formats[index] = format

		return index
	}
}

unload_texture :: proc(index: u32) {
	when BACKEND == .OPENGL {
		gl.unload_texture(&texture_ids[index])
	}

	occupied[index] = false
}

texture_id :: proc(index: u32) -> u32 {
	return texture_ids[index]
}

texture_width :: proc(index: u32) -> f32 {
	return f32(texture_widths[index])
}

texture_height :: proc(index: u32) -> f32 {
	return f32(texture_heights[index])
}

