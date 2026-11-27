// A playing card (#1294; PlayingCards): its face from the deck's atlas (tools/textures/draw_cards.py,
// assets/textures/cards/deck.png, 8 x 7 cards: the 52 faces at Poker's index, the back at 52) on its
// top (+Y), the back on its underside, plain paper on its edges. Which face: the MultiMesh's custom
// data (red channel: the card's index) or, on a single card, the instance uniform `card` (>= 0).
shader_type spatial;
render_mode cull_back;

uniform sampler2D deck : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 paper : source_color = vec3(0.86, 0.83, 0.74);
instance uniform float card = -1.0;
instance uniform float shade = 1.0;

varying flat float face;

void vertex() {
	float c = card >= 0.0 ? card : INSTANCE_CUSTOM.r;
	face = NORMAL.y > 0.5 ? floor(c + 0.5) : (NORMAL.y < -0.5 ? 52.0 : -1.0);
}

void fragment() {
	vec3 col = paper;
	if (face >= 0.0) {
		vec2 cell = vec2(mod(face, 8.0), floor(face / 8.0));
		col = texture(deck, (cell + clamp(UV, vec2(0.004), vec2(0.996))) / vec2(8.0, 7.0)).rgb;
	}
	ALBEDO = col * shade;
	ROUGHNESS = 0.62;
	SPECULAR = 0.35;
}
