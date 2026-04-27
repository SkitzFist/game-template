package render

// ---- COLOR ----

Color :: [4]u8

rgba8 :: proc(r, g, b, a: u8) -> Color {
	return {r, g, b, a}
}

channel_u8 :: proc(value: f32) -> u8 {
	clamped := value
	if clamped < 0 {
		clamped = 0
	} else if clamped > 1 {
		clamped = 1
	}

	return u8(clamped * 255.0 + 0.5)
}

BLACK: Color : {0, 0, 0, 255}
WHITE: Color : {255, 255, 255, 255}
RED: Color : {255, 0, 0, 255}
GREEN: Color : {0, 255, 0, 255}
BLUE: Color : {0, 0, 255, 255}
