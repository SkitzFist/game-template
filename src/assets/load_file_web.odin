#+build js wasm32
package assets

import "core:mem"

load_file :: proc(path: string, allocator: mem.Allocator = context.allocator) -> []byte {
	return {}
}
