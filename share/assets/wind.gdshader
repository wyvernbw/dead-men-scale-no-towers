shader_type canvas_item;

uniform sampler2D wind_tex: repeat_enable;

void fragment() {
	float wind = texture(wind_tex, vec2(UV.y + TIME)).r;
	COLOR = texture(TEXTURE, UV + vec2(wind, 0.0) * 0.2 * UV.y);
}
