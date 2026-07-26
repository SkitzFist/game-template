#+build js wasm32
package util

import "core:mem"

load_file :: proc(path: string, allocator: mem.Allocator = context.allocator) -> []byte {
	return {}
}

