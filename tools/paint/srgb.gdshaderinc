// The viewport stores colour sRGB-encoded; writing srgb_to_linear(v) as ALBEDO reads back as v.
float srgb_to_linear(float c) {
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}
