package assets

import "base:runtime"

// debug
import "core:fmt"

@(private)
SPRITES := #load_directory("../../assets/sprites")

@(private)
FONTS := #load_directory("../../assets/fonts")

Asset_Map :: map[string][]byte
sprites: Asset_Map
fonts: Asset_Map

init :: proc() {
	// asset maps
	sprites = make(Asset_Map)
	build_asset_map(SPRITES, &sprites)

	fonts = make(Asset_Map)
	build_asset_map(FONTS, &fonts)
}

destroy :: proc() {
	delete(sprites)
	delete(fonts)
}

build_asset_map :: proc(assets: []runtime.Load_Directory_File, asset_map: ^Asset_Map) {
	for asset, i in assets {
		asset_map[asset.name] = asset.data

		fmt.printfln("[ASSETS] Added file: %v as index %v", asset.name, i)
	}
}
