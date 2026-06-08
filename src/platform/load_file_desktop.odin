#+build linux, windows
package platform

import "core:fmt"
import "core:mem"
import "core:os"

load_file :: proc(path: string, allocator: mem.Allocator = context.allocator) -> []byte {
	data, err := os.read_entire_file(path, allocator)

	if err != os.General_Error.None {
		panic(fmt.aprint("Could not load file:", path, "Error:", err))
	}

	return data
}

