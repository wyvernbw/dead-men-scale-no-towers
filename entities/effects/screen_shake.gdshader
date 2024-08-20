shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float strength = 4.0;
uniform float speed = 8.0;

void fragment() {
	float deviation = strength * sin(TIME * speed);
	vec2 offset = vec2(deviation, 0.0) * SCREEN_PIXEL_SIZE;
	vec4 color = texture(SCREEN_TEXTURE, UV + offset);
	
	COLOR = color;
}