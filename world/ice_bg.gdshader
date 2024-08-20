shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform sampler2D strengthTex;

void fragment() {
	vec4 screenSample = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 colorSample = texture(TEXTURE, UV);
	float strength = texture(strengthTex, UV).r;
	COLOR = mix(screenSample * colorSample, screenSample, strength);
}
