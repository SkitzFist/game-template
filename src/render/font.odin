package render

import tt "vendor:stb/truetype"

import "core:fmt"
import "core:math"
import "core:strings"

import "../platform"

/*
	| texture_index | baked_chars
*/

Font_Index :: u8
FONT_DEFAULT: Font_Index : 0

MAX_FONTS :: 10
texture_index: [MAX_FONTS]Texture_Index
atlas_heights: [MAX_FONTS]i32

NUM_CHAR: i32 : 96
baked_chars: [MAX_FONTS][NUM_CHAR]tt.bakedchar

START_CHAR: i32 : 32


@(private = "file")
occupied: [MAX_FONTS]bool

@(private = "file")
get_next_free_index :: proc() -> Font_Index {
	for i in 0 ..< MAX_FONTS {
		if occupied[i] == false {
			return Font_Index(i)
		}
	}

	panic("No unnoccupied font slot, time to implement membuffer")
}

load_font :: proc(path: string) -> Font_Index {
	font_index := get_next_free_index()

	font_data := platform.load_file(path, context.temp_allocator)

	atlas_size: i32 = 512
	bitmap := make([]u8, atlas_size * atlas_size)
	defer delete(bitmap)

	result := tt.BakeFontBitmap(
		raw_data(font_data[:]),
		0,
		32,
		raw_data(bitmap[:]),
		atlas_size,
		atlas_size,
		START_CHAR,
		NUM_CHAR,
		raw_data(baked_chars[font_index][:]),
	)

	if result <= 0 {
		panic(fmt.aprint("Could not bake font", path, "Result:", result))
	}

	texture_index[font_index] = load_texture_file(
		raw_data(bitmap[:]),
		atlas_size,
		atlas_size,
		.GRAY,
	)

	atlas_heights[font_index] = atlas_size
	occupied[font_index] = true

	return font_index
}

get_glyph :: proc(font_index: Font_Index, char: rune) -> tt.bakedchar {
	return baked_chars[font_index][char - 32]
}

font_get_texture :: proc(font_index: Font_Index) -> Texture_Index {
	return texture_index[font_index]
}

text_width :: proc(font_index: Font_Index, text: string) -> f32 {
	has_multi_line, indexes := text_is_multiline(text)
	width: f32

	if has_multi_line {
		lines := text_get_multilines(text, indexes)
		widths := make([]f32, len(lines), context.temp_allocator)

		for &line, i in lines {
			for r in line {
				glyph := get_glyph(font_index, r)
				widths[i] += glyph.xadvance
			}
		}

		for w in widths {
			width = math.max(width, w)
		}

	} else {
		for r in text {
			glyph := get_glyph(font_index, r)
			width += glyph.xadvance
		}
	}


	return width
}

text_height :: proc(font_index: Font_Index, text: string) -> f32 {
	has_multi_line, indexes := text_is_multiline(text)
	height: f32

	if has_multi_line {
		lines := text_get_multilines(text, indexes)
		heights := make([]f32, len(lines), context.temp_allocator)

		for &line, i in lines {
			for r in line {
				glyph := get_glyph(font_index, r)
				heights[i] = math.max(heights[i], f32(glyph.y1 - glyph.y0))
			}
		}

		for h in heights {
			height += h
		}

	} else {
		for r in text {
			glyph := get_glyph(font_index, r)
			height = math.max(height, f32(glyph.y1 - glyph.y0))
		}
	}

	return height
}

text_is_multiline :: proc(text: string) -> (bool, []int) {
	count := strings.count(text, "\n")
	// fmt.println("count:", count)

	if count == 0 {
		return false, {}
	}

	// temp allocator is arena backed by a stack buffer
	indexes := make([]int, count, context.temp_allocator)

	start := 0

	for i in 0 ..< count {
		idx := strings.index(text[start:], "\n")
		indexes[i] = start + idx
		start = indexes[i] + 1
	}

	return true, indexes
}

text_get_multilines :: proc(text: string, indexes: []int) -> []string {
	lines := make([]string, len(indexes) + 1, context.temp_allocator)[:]

	prev := 0

	for i in 0 ..< len(indexes) {
		next := indexes[i]
		lines[i] = text[prev:next]
		prev = next + 1
	}

	lines[len(indexes)] = text[prev:]

	return lines
}

