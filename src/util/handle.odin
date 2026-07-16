package util

import "base:intrinsics"

Bit_Field :: struct($T: typeid) where intrinsics.type_is_unsigned(T) {
	bits:  T,
	shift: T,
}

@(private = "file")
field_mask :: #force_inline proc($T: typeid, field: Bit_Field(T)) -> T {
	return (T(1) << field.bits) - T(1)
}

// set field, will return a new handle T
set_field :: #force_inline proc(handle: $T, field: Bit_Field(T), value: $V) -> T {
	mask := field_mask(T, field)
	handle := handle

	handle &= ~(mask << field.shift)
	handle |= (T(value) & mask) << field.shift

	return handle
}

// returns given field in value: V
get_field :: #force_inline proc(handle: $T, field: Bit_Field(T), $V: typeid) -> V {
	mask := field_mask(T, field)
	return V((handle >> field.shift) & mask)
}

