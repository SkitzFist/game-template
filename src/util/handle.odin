package util

import "base:intrinsics"

Handle_Data :: struct(
	$T: typeid,
	$E: typeid,
) where intrinsics.type_is_unsigned(T) &&
	intrinsics.type_is_enum(E)
{
	fields: [E]Bit_Field(T),
}

Bit_Field :: struct($T: typeid) where intrinsics.type_is_unsigned(T) {
	bits:  T,
	shift: T,
}

create_handle_data :: proc "contextless" (
	$T: typeid,
	field_bits: [$E]T,
) -> Handle_Data(T, E) where intrinsics.type_is_unsigned(T) &&
	intrinsics.type_is_enum(E) {

	data: Handle_Data(T, E)
	total_bits: T = 0
	shift: T

	for field_type in E {
		bits := field_bits[field_type]
		data.fields[field_type] = {
			bits  = bits,
			shift = shift,
		}

		total_bits += bits
		shift += bits
	}

	if total_bits > T(size_of(T) * 8) {
		panic_contextless(
			"[UTIL] failed creating handle data: sum of bits is larger then handle type",
		)
	}

	return data
}

@(private = "file")
field_mask :: #force_inline proc "contextless" ($T: typeid, field: Bit_Field(T)) -> T {
	return (T(1) << field.bits) - T(1)
}

// set field, will return a new handle T
set_field :: #force_inline proc "contextless" (handle: $T, field: Bit_Field(T), value: $V) -> T {
	mask := field_mask(T, field)
	handle := handle

	handle &= ~(mask << field.shift)
	handle |= (T(value) & mask) << field.shift

	return handle
}

// returns given field in value: V
get_field :: #force_inline proc "contextless" (handle: $T, field: Bit_Field(T), $V: typeid) -> V {
	mask := field_mask(T, field)
	return V((handle >> field.shift) & mask)
}

increment_field :: #force_inline proc "contextless" (
	handle: $T,
	field: Bit_Field(T),
	$V: typeid,
) -> T {
	count := get_field(handle, field, V)
	count = (count + 1) % max(V)
	return set_field(handle, field, count)

}

