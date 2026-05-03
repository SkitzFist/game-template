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
TRANSPARENT: Color : {0, 0, 0, 0}

GRAY: Color : {128, 128, 128, 255}
LIGHT_GRAY: Color : {192, 192, 192, 255}
DARK_GRAY: Color : {64, 64, 64, 255}

RED: Color : {255, 0, 0, 255}
GREEN: Color : {0, 255, 0, 255}
BLUE: Color : {0, 0, 255, 255}
YELLOW: Color : {255, 255, 0, 255}
CYAN: Color : {0, 255, 255, 255}
MAGENTA: Color : {255, 0, 255, 255}

ORANGE: Color : {255, 165, 0, 255}
GOLD: Color : {255, 215, 0, 255}
SILVER: Color : {192, 192, 192, 255}
PURPLE: Color : {128, 0, 128, 255}
PINK: Color : {255, 192, 203, 255}
BROWN: Color : {165, 42, 42, 255}

