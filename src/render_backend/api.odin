package render_backend

//-----COLOR-----//
Color :: struct {
	r, g, b, a: u8,
}

LIGHTGRAY :: Color{200, 200, 200, 255}
GRAY :: Color{130, 130, 130, 255}
DARKGRAY :: Color{80, 80, 80, 255}
YELLOW :: Color{253, 249, 0, 255}
GOLD :: Color{255, 203, 0, 255}
ORANGE :: Color{255, 161, 0, 255}
PINK :: Color{255, 109, 194, 255}
RED :: Color{230, 41, 55, 255}
MAROON :: Color{190, 33, 55, 255}
GREEN :: Color{0, 228, 48, 255}
LIME :: Color{0, 158, 47, 255}
DARKGREEN :: Color{0, 117, 44, 255}
SKYBLUE :: Color{102, 191, 255, 255}
BLUE :: Color{0, 121, 241, 255}
DARKBLUE :: Color{0, 82, 172, 255}
PURPLE :: Color{200, 122, 255, 255}
VIOLET :: Color{135, 60, 190, 255}
DARKPURPLE :: Color{112, 31, 126, 255}
BEIGE :: Color{211, 176, 131, 255}
BROWN :: Color{127, 106, 79, 255}
DARKBROWN :: Color{76, 63, 47, 255}
WHITE :: Color{255, 255, 255, 255}
BLACK :: Color{0, 0, 0, 255}
BLANK :: Color{0, 0, 0, 0}
MAGENTA :: Color{255, 0, 255, 255}
RAYWHITE :: Color{245, 245, 245, 255}


//-----STRUCTS-----//

Vector2F :: [2]f32
Vector2I :: [2]i32

PIVOT_TOP_LEFT :: Vector2F{0.0, 0.0}
PIVOT_CENTER :: Vector2F{0.5, 0.5}
PIVOT_BOTTOM_RIGHT :: Vector2F{1.0, 1.0}

@(private = "file")
convert_vector_i32_f32 :: #force_inline proc(vec: Vector2I) -> Vector2F {
	return {f32(vec.x), f32(vec.y)}
}

@(private = "file")
convert_vector_f32_i32 :: #force_inline proc(vec: Vector2F) -> Vector2I {
	return {i32(vec.x), i32(vec.y)}
}

convert_vector :: proc {
	convert_vector_i32_f32,
	convert_vector_f32_i32,
}

clamp_pivot :: #force_inline proc(pivot: Vector2F) -> Vector2F {
	clamped := pivot
	if clamped.x < 0.0 {
		clamped.x = 0.0
	} else if clamped.x > 1.0 {
		clamped.x = 1.0
	}
	if clamped.y < 0.0 {
		clamped.y = 0.0
	} else if clamped.y > 1.0 {
		clamped.y = 1.0
	}
	return clamped
}

resolve_rect_pivot :: #force_inline proc(width, height: f32, pivot: Vector2F) -> Vector2F {
	clamped := clamp_pivot(pivot)
	return {width * clamped.x, height * clamped.y}
}

normalized_pivot_in_bounds :: #force_inline proc(
	min_x, min_y, width, height, world_x, world_y: f32,
) -> Vector2F {
	pivot := Vector2F{0.5, 0.5}
	if width > 0 {
		pivot.x = (world_x - min_x) / width
	}
	if height > 0 {
		pivot.y = (world_y - min_y) / height
	}
	return clamp_pivot(pivot)
}

RectangleI :: struct {
	x, y, width, height: i32,
}

RectangleF :: struct {
	x, y, width, height: f32,
}

@(private = "file")
get_rect_center_i32 :: proc(rect: RectangleI) -> Vector2I {
	return {rect.x + (rect.width / 2), rect.y + (rect.height / 2)}
}

@(private = "file")
get_rect_center_f32 :: proc(rect: RectangleF) -> Vector2F {
	return {rect.x + (rect.width / 2), rect.y + (rect.height / 2)}
}

get_rect_center :: proc {
	get_rect_center_i32,
	get_rect_center_f32,
}

@(private = "file")
convert_rect_i32_f32 :: proc(rect: RectangleI) -> RectangleF {
	return {f32(rect.x), f32(rect.y), f32(rect.width), f32(rect.height)}
}

@(private = "file")
convert_rect_f32_i32 :: proc(rect: RectangleF) -> RectangleI {
	return {i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)}
}

convert_rect :: proc {
	convert_rect_i32_f32,
	convert_rect_f32_i32,
}
