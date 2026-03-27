// Diamond dissolve transition shader (Undertale / retro RPG style).
// Diamond shapes grow from a grid pattern to cover the screen.
// progress = 0.0: scene fully visible
// progress = 1.0: scene fully covered
// Pixel-art friendly with hard edges.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
// Number of diamond cells across the screen width.
uniform float diamond_count : hint_range(2.0, 100.0) = 20.0;

void fragment() {
    // Scale UVs to create a grid of diamond_count cells.
    vec2 uv = UV * diamond_count;

    // Get the fractional position within each cell, centered at 0.
    vec2 cell = fract(uv) - 0.5;

    // Diamond distance: Manhattan distance from cell center.
    float dist = abs(cell.x) + abs(cell.y);

    // The diamond fills when dist < progress. At progress 0, nothing is filled.
    // At progress 1, everything is filled (dist maxes at 1.0 for the corners of a cell).
    // Scale progress so diamonds fully cover at progress = 1.
    float threshold = progress * 1.1;

    // Hard edge for pixel-art look.
    float mask = step(dist, threshold);

    COLOR = vec4(color.rgb, mask);
}
