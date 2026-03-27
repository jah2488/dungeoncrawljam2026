// Vertical wipe transition shader.
// A clean edge wipes from top to bottom across the screen.
// progress = 0.0: scene fully visible
// progress = 1.0: scene fully covered
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
// Controls the softness of the wipe edge.
uniform float edge_softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
    // Wipe threshold moves from top (-softness) to bottom (1 + softness).
    float threshold = mix(-edge_softness, 1.0 + edge_softness, progress);

    // Smooth transition at the edge for a polished look.
    float mask = smoothstep(threshold - edge_softness, threshold + edge_softness, UV.y);

    // Invert: pixels ABOVE the threshold are covered.
    mask = 1.0 - mask;

    COLOR = vec4(color.rgb, mask);
}
