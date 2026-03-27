// Pixelation transition shader.
// The scene pixelates into larger and larger blocks as progress increases.
// At progress 1.0, the entire screen becomes a single solid color.
// progress = 0.0: no pixelation (scene visible, fully transparent overlay)
// progress = 1.0: maximum pixelation, fully covered
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
// Minimum pixel block size at the start of the effect (in UV fraction).
uniform float min_block_size : hint_range(0.001, 0.01) = 0.005;
// Maximum pixel block size at full pixelation.
uniform float max_block_size : hint_range(0.01, 1.0) = 0.5;

void fragment() {
    // Compute block size that grows with progress.
    float block_size = mix(min_block_size, max_block_size, progress * progress);

    // Snap UVs to the grid to create the pixelation effect.
    vec2 snapped_uv = floor(UV / block_size) * block_size + block_size * 0.5;

    // Sample the screen texture at the snapped position.
    vec4 scene_color = texture(TEXTURE, snapped_uv);

    // Blend toward the solid color as progress increases.
    // The first half of progress mostly pixelates; the second half fades to solid.
    float fade = smoothstep(0.3, 1.0, progress);

    vec4 result = mix(scene_color, color, fade);

    // Also fade in the overall alpha so at progress 0 nothing is shown.
    float alpha = smoothstep(0.0, 0.15, progress);
    COLOR = vec4(result.rgb, alpha);
}
