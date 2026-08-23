package render

import tt "vendor:stb/truetype"

import "core:fmt"
import "core:math"
import "core:strings"

import "../util"

/*
	TODO:
		* When adding more font types, should introduce type_handle. So Font_Handle will point toward a Font_Type_Handle and
		  the type handle will point towards resource arrays (if needed, look into it when we're there)

	TODO:
		Support larger sets then just ASCII, look into dynamic glyph caching.
		Also needs to safely handle missing glyphs.

	TODO:
		Split Font and Text responsibilities.

		    Font should represent the underlying font resource and glyph data.
		    Text should handle user-provided strings, layout, measurement, and rendering.

		    During the split, revisit:
		    - text_height
		    - text_width
		    - multiline detection/layout
*/

// ---- HANDLE ---- //

// All types deal with the same font handle.
Font_Handle :: u32

@(private = "file")
Font_Index :: u8

@(private = "file")
Generation :: u8

Font_Type :: enum u8 {
	BITMAP,
}

@(private = "file")
Bitmap_Fields :: enum {
	INDEX,
	TYPE,
	GENERATION,
}

@(private = "file")
handle_fields := util.create_handle_data(
	Font_Handle,
	[Bitmap_Fields]Font_Handle {
		.INDEX = size_of(Font_Index) * 8,
		.TYPE = size_of(Font_Type) * 8,
		.GENERATION = size_of(Generation) * 8,
	},
)


// ---- CONSTANTS ---- //
DEFAULT_FONT: Font_Handle
DEFAULT_FONT_SIZE :: 32
NUM_CHAR: i32 : 96
START_CHAR: i32 : 32


// ---- RESOURCE ---- //
Font_Resource :: struct {
	texture_index: Texture_Index,
	atlas_height:  i32,
	baked_chars:   [NUM_CHAR]tt.bakedchar,
	base_height:   i32,
}

// Font style. Will later add bold, italien etc, should be introduced as a bit_set maybe, or just a handle
// Alternatively split up in a more data-oriented way.
Font_Style :: struct {
	size:  f32,
	color: Color,
}
DEFAULT_FONT_STYLE: Font_Style : {DEFAULT_FONT_SIZE, WHITE}


// ---- DATA ---- //
font_handles: [dynamic]Font_Handle
font_resources: [dynamic]Font_Resource
@(private = "file")
removed: [dynamic]Font_Handle


// ---- IMPL ---- //


// inits font module & loads default font
font_init :: proc() {
	font_handles = make([dynamic]Font_Handle, 0, 5)
	font_resources = make([dynamic]Font_Resource, 0, 5)
	removed = make([dynamic]Font_Handle, 0, 0)

	DEFAULT_FONT = load_font("assets/fonts/roboto.ttf")
}

// delete font resources
font_shutdown :: proc() {
	delete(font_handles)
	delete(font_resources)
	delete(removed)
}

// creates a new Font_Handle with generation 0
create_handle :: proc "contextless" (index: Font_Index, type: Font_Type) -> Font_Handle {
	switch type {
	case .BITMAP:
		handle := util.set_field(Font_Handle{}, handle_fields.fields[.INDEX], index)
		handle = util.set_field(handle, handle_fields.fields[.GENERATION], 0)
		handle = util.set_field(handle, handle_fields.fields[.TYPE], type)
		return handle
	}

	panic_contextless("[FONT] could not create handle: Type is not in switch")
}

// Will return either a previously 'dead' handle or create a new handle & resource
prepare_a_handle :: proc(
	index_field: util.Bit_Field(Font_Handle),
	generation_field: util.Bit_Field(Font_Handle),
	type: Font_Type,
) -> (
	Font_Handle,
	Font_Index,
) {
	if len(removed) > 0 {
		handle := pop(&removed)
		index := font_get_index(handle)

		return handle, index
	}

	index := Font_Index(len(font_handles))
	handle := create_handle(index, type)
	append(&font_handles, handle)
	append(&font_resources, Font_Resource{})

	return handle, index
}

load_font :: proc(path: string, font_size: i32 = 32, type: Font_Type = .BITMAP) -> Font_Handle {
	assert(
		len(font_handles) < int(max(Font_Index)),
		"Max allowed fonts 255, please unload some or rethink your life choices",
	)
	handle: Font_Handle
	index: Font_Index

	switch type {
	case .BITMAP:
		handle, index = prepare_a_handle(
			handle_fields.fields[.INDEX],
			handle_fields.fields[.GENERATION],
			type,
		)
	}

	font_data := util.load_file(path, context.temp_allocator)
	atlas_size: i32 = 512
	bitmap := make([]u8, atlas_size * atlas_size, context.temp_allocator)

	result := tt.BakeFontBitmap(
		raw_data(font_data[:]),
		0,
		f32(font_size),
		raw_data(bitmap[:]),
		atlas_size,
		atlas_size,
		START_CHAR,
		NUM_CHAR,
		raw_data(font_resources[index].baked_chars[:]),
	)

	if result <= 0 {
		panic(fmt.aprint("Could not bake font", path, "Result:", result))
	}

	font_resources[index].atlas_height = atlas_size
	font_resources[index].base_height = font_size
	font_resources[index].texture_index = load_texture_file(
		raw_data(bitmap[:]),
		atlas_size,
		atlas_size,
		.GRAY,
	)

	return handle
}

unload_font :: proc(handle: Font_Handle) {
	if !font_is_handle_valid(handle) {return}

	index := font_get_index(handle)

	handle := util.increment_field(handle, handle_fields.fields[.GENERATION], u8)
	font_handles[index] = handle

	switch util.get_field(handle, handle_fields.fields[.TYPE], Font_Type) {
	case .BITMAP:
		texture_index := font_get_texture(handle)
		unload_texture(texture_index)
	}

	font_resources[index] = {}

	append(&removed, handle)
}

font_is_handle_valid :: #force_inline proc(handle: Font_Handle) -> bool {
	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)

	if int(index) >= len(font_handles) {
		return false
	}

	stored_handle := font_handles[index]

	return stored_handle == handle
}

get_glyph :: proc(index: Font_Index, char: rune) -> tt.bakedchar {
	return font_resources[index].baked_chars[char - 32]
}

font_get_index :: proc(handle: Font_Handle) -> Font_Index {
	return util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
}

font_get_texture :: proc(handle: Font_Handle) -> Texture_Index {
	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
	return font_resources[index].texture_index
}

font_get_atlas_height :: proc(handle: Font_Handle) -> i32 {
	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
	return font_resources[index].atlas_height
}

font_get_base_height :: proc(handle: Font_Handle) -> f32 {
	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
	return f32(font_resources[index].base_height)
}

text_width :: proc(
	handle: Font_Handle,
	text: string,
	style: Font_Style = DEFAULT_FONT_STYLE,
) -> f32 {
	if style.size <= 0 {
		return 0
	}

	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
	has_multi_line, indexes := text_is_multiline(text)
	width: f32
	size_scalar := style.size / font_get_base_height(handle)


	if has_multi_line {
		lines := text_get_multilines(text, indexes)
		widths := make([]f32, len(lines), context.temp_allocator)

		for &line, i in lines {
			for r in line {
				glyph := get_glyph(index, r)
				widths[i] += (glyph.xadvance * size_scalar)
			}
		}

		for w in widths {
			width = math.max(width, w)
		}

	} else {
		for r in text {
			glyph := get_glyph(index, r)
			width += glyph.xadvance * size_scalar
		}
	}


	return width
}

text_height :: proc(
	handle: Font_Handle,
	text: string,
	style: Font_Style = DEFAULT_FONT_STYLE,
) -> f32 {
	if style.size <= 0 {
		return 0
	}

	index := util.get_field(handle, handle_fields.fields[.INDEX], Font_Index)
	has_multi_line, indexes := text_is_multiline(text)
	height: f32
	size_scalar := style.size / font_get_base_height(handle)

	if has_multi_line {
		lines := text_get_multilines(text, indexes)
		heights := make([]f32, len(lines), context.temp_allocator)

		for &line, i in lines {
			for r in line {
				glyph := get_glyph(index, r)
				heights[i] = math.max(heights[i], f32(glyph.y1 - glyph.y0) * size_scalar)
			}
		}

		for h in heights {
			height += h
		}

	} else {
		for r in text {
			glyph := get_glyph(index, r)
			height = math.max(height, f32(glyph.y1 - glyph.y0) * size_scalar)
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

