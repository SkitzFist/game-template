package platform

Platform :: enum {
	DESKTOP,
	WEB,
}

@(private)
PLATFORM_STR :: #config(PLATFORM, "DESKTOP")

when PLATFORM_STR == "DESKTOP" {
	PLATFORM :: Platform.DESKTOP
} else when PLATFORM_STR == "WEB" {
	PLATFORM :: Platform.WEB
} else {
	//fallback
	PLATFORM :: Platform.DESKTOP
}

