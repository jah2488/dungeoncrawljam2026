// Circle wipe transition shader (Celeste-style).
// A circle contracts from the edges toward the center as progress increases.
// progress = 0.0: circle fully open (scene visible)
// progress = 1.0: circle fully closed (scene covered)
// Uses screen-space coordinates corrected for aspect ratio.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.1, 0.1, 0.1, 1.0);

void fragment() {
    // Center of the screen in UV space.
    vec2 center = vec2(0.5, 0.5);

    // Correct for aspect ratio so the circle is round, not oval.
    // TEXTURE_PIXEL_SIZE is (1/width, 1/height).
    float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    vec2 uv = UV;
    uv.x = (uv.x - 0.5) * aspect + 0.5;
    float center_x = (center.x - 0.5) * aspect + 0.5;
    vec2 adjusted_center = vec2(center_x, center.y);

    // Distance from the current pixel to the center.
    float dist = distance(uv, adjusted_center);

    // Maximum possible radius (corner distance) so the circle covers the full screen.
    float max_radius = distance(vec2(0.0, 0.0), adjusted_center);

    // Invert progress: at progress 0 the radius is max (open), at 1 the radius is 0 (closed).
    float radius = max_radius * (1.0 - progress);

    // Smooth edge for anti-aliasing. The smoothstep width is relative to a pixel.
    float edge_softness = fwidth(dist) * 1.5;
    float mask = smoothstep(radius - edge_softness, radius + edge_softness, dist);

    COLOR = vec4(color.rgb, mask);
}
