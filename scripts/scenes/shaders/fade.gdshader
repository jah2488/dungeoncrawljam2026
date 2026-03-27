// Fade transition shader.
// Fades the screen to a solid color by increasing alpha from 0 to 1.
// progress = 0.0: fully transparent (scene visible)
// progress = 1.0: fully opaque (scene covered)
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.1, 0.1, 0.1, 1.0);

void fragment() {
    COLOR = vec4(color.rgb, progress);
}
