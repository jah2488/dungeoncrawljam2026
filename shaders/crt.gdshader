// =============================================================================
// CRT Monitor Emulation Shader
// Godot 4.x — canvas_item (full-screen post-process)
//
// FEATURES:
//   • Barrel / pincushion screen warp
//   • Rounded-rectangle bezel with soft edge glow
//   • Accurate scanlines with configurable width and sharpness
//   • Three RGB shadow-mask types:
//       0 = Aperture Grille  (Sony Trinitron — vertical R|G|B stripes)
//       1 = Slot Mask        (staggered rows, horizontal gaps)
//       2 = Dot Matrix       (circular phosphor dots, hex-offset grid)
//   • All color work done in linear light (gamma decode → process → re-encode)
//   • Brightness, contrast, gamma-in/out, saturation, phosphor tint
//   • Bloom / phosphor glow (threshold-based Gaussian)
//   • Vignette with configurable radius and softness
//   • Animated film-grain noise
//   • Chromatic aberration
// =============================================================================

shader_type canvas_item;

// ── Screen Geometry ──────────────────────────────────────────────────────────
group_uniforms Geometry;

uniform float warp_amount          : hint_range(0.0,  0.5,  0.005) = 0.04;
uniform float bevel_corner_radius  : hint_range(0.0,  0.30, 0.005) = 0.06;
uniform float bevel_edge_softness  : hint_range(0.0,  0.08, 0.001) = 0.015;

group_uniforms;

// ── Scanlines ─────────────────────────────────────────────────────────────────
group_uniforms Scanlines;

// Match source vertical resolution: 180 lines
uniform float scanline_count       : hint_range(50.0, 1200.0, 1.0)  = 180.0;
uniform float scanline_intensity   : hint_range(0.0,  1.0,  0.005) = 0.30;
uniform float scanline_sharpness   : hint_range(0.5,  8.0,  0.1)   = 2.0;
uniform float scanline_bright_width: hint_range(0.1,  0.9,  0.01)  = 0.60;

group_uniforms;

// ── RGB Shadow Mask ───────────────────────────────────────────────────────────
group_uniforms ShadowMask;

// 0 = Aperture Grille  |  1 = Slot Mask  |  2 = Dot Matrix
uniform int   mask_type            : hint_range(0, 2)               = 0;
uniform float mask_intensity       : hint_range(0.0,  1.0,  0.01)  = 0.20;
uniform float mask_pixel_size      : hint_range(0.5,  4.0,  0.1)   = 1.0;
// Number of RGB triplets across screen width (0 = use mask_pixel_size instead)
uniform float mask_line_count      : hint_range(0.0, 1200.0, 1.0)  = 0.0;
uniform float mask_dark_level      : hint_range(0.0,  0.9,  0.01)  = 0.35;

group_uniforms;

// ── Color Correction ─────────────────────────────────────────────────────────
group_uniforms ColorCorrection;

uniform float brightness           : hint_range(0.0,  3.0,  0.01)  = 1.0;
uniform float contrast             : hint_range(0.0,  3.0,  0.01)  = 1.05;
uniform float gamma_in             : hint_range(0.5,  4.0,  0.05)  = 2.2;
uniform float gamma_out            : hint_range(0.5,  4.0,  0.05)  = 2.2;
uniform float saturation           : hint_range(0.0,  2.0,  0.01)  = 1.1;
uniform vec3  phosphor_tint        : source_color                   = vec3(0.95, 1.0, 0.90);

group_uniforms;

// ── Bloom / Phosphor Glow ────────────────────────────────────────────────────
group_uniforms Bloom;

uniform float bloom_intensity      : hint_range(0.0,  1.0,  0.01)  = 0.08;
uniform float bloom_threshold      : hint_range(0.0,  1.0,  0.01)  = 0.65;
uniform float bloom_radius         : hint_range(0.5,  8.0,  0.1)   = 2.0;

group_uniforms;

// ── Vignette ─────────────────────────────────────────────────────────────────
group_uniforms Vignette;

uniform float vignette_intensity   : hint_range(0.0,  2.0,  0.01)  = 0.35;
uniform float vignette_radius      : hint_range(0.1,  1.5,  0.01)  = 0.80;
uniform float vignette_softness    : hint_range(0.0,  1.0,  0.01)  = 0.50;

group_uniforms;

// ── Chromatic Aberration ─────────────────────────────────────────────────────
group_uniforms ChromaticAberration;

uniform float chroma_amount        : hint_range(0.0,  0.02, 0.0005) = 0.003;

group_uniforms;

// ── Film Grain / Noise ───────────────────────────────────────────────────────
group_uniforms Noise;

uniform float noise_intensity      : hint_range(0.0,  0.5,  0.005) = 0.025;
uniform bool  noise_animated                                        = true;

group_uniforms;

// ── Built-ins ─────────────────────────────────────────────────────────────────
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// =============================================================================
// Utility
// =============================================================================

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

vec2 barrel_distort(vec2 uv, float amount) {
    vec2 d  = uv - 0.5;
    float r2 = dot(d, d);
    return d * (1.0 + r2 * amount * 2.5) + 0.5;
}

float rounded_rect_sdf(vec2 uv, float r) {
    vec2 d = abs(uv - 0.5) - (0.5 - r);
    return length(max(d, 0.0)) - r;
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 apply_saturation(vec3 c, float sat) {
    return mix(vec3(luma(c)), c, sat);
}

// =============================================================================
// Scanlines
// =============================================================================
float scanline_mod(float uv_y, float count, float intensity,
                   float sharpness, float bright_width) {
    float t    = fract(uv_y * count);
    float scan = smoothstep(0.0,          1.0 - bright_width, t)
               * (1.0 - smoothstep(bright_width, 1.0, t));
    scan = pow(max(scan, 0.0), 1.0 / max(sharpness, 0.01));
    return 1.0 - intensity * (1.0 - scan);
}

// =============================================================================
// RGB Shadow Mask
// =============================================================================
vec3 shadow_mask(vec2 frag_pos, vec2 uv, int mask, float px_size,
                 float line_count, float dark) {
    vec2 p;
    if (line_count > 0.5) {
        // UV-based: line_count RGB triplets across, proportional rows vertically
        p = vec2(uv.x * line_count * 3.0, uv.y * line_count * 3.0);
    } else {
        p = frag_pos / max(px_size, 0.25);
    }
    float x    = mod(p.x, 3.0);
    float y    = mod(p.y, 2.0);
    float row  = floor(p.y);

    float r = 0.0, g = 0.0, b = 0.0;

    if (mask == 0) {
        // Aperture Grille (Trinitron-style)
        float dx = abs(dFdx(p.x)) * 0.75;
        r = 1.0 - smoothstep(1.0 - dx, 1.0 + dx, x);
        g = smoothstep(1.0 - dx, 1.0 + dx, x)
          * (1.0 - smoothstep(2.0 - dx, 2.0 + dx, x));
        b = smoothstep(2.0 - dx, 2.0 + dx, x);

    } else if (mask == 1) {
        // Slot Mask
        float shift = (mod(row, 2.0) >= 1.0) ? 1.5 : 0.0;
        float px    = mod(x + shift, 3.0);
        float dx    = abs(dFdx(p.x)) * 0.75;
        r = 1.0 - smoothstep(1.0 - dx, 1.0 + dx, px);
        g = smoothstep(1.0 - dx, 1.0 + dx, px)
          * (1.0 - smoothstep(2.0 - dx, 2.0 + dx, px));
        b = smoothstep(2.0 - dx, 2.0 + dx, px);
        float y_frac = fract(p.y);
        float gap    = smoothstep(0.0, 0.15, y_frac)
                     * (1.0 - smoothstep(0.85, 1.0, y_frac));
        r *= gap; g *= gap; b *= gap;

    } else {
        // Dot Matrix
        float row_idx = floor(p.y / 2.0);
        float row_off = mod(row_idx, 2.0) * 1.5;
        float px2     = mod(p.x + row_off, 3.0);
        float py2     = mod(p.y, 2.0);

        r = clamp(1.0 - smoothstep(0.40, 0.55, length(vec2(px2 - 0.5,  py2 - 1.0))), 0.0, 1.0);
        g = clamp(1.0 - smoothstep(0.40, 0.55, length(vec2(px2 - 1.5,  py2 - 1.0))), 0.0, 1.0);
        b = clamp(1.0 - smoothstep(0.40, 0.55, length(vec2(px2 - 2.5,  py2 - 1.0))), 0.0, 1.0);
    }

    return dark + vec3(r, g, b) * (1.0 - dark);
}

// =============================================================================
// Vignette
// =============================================================================
float vignette(vec2 uv, float radius, float intensity, float softness) {
    float r     = length((uv - 0.5) * 2.0);
    float inner = radius * (1.0 - softness);
    return 1.0 - smoothstep(inner, radius, r) * intensity;
}

// =============================================================================
// Main fragment shader
// =============================================================================
void fragment() {
    vec2 texel = TEXTURE_PIXEL_SIZE;

    // 1. Screen warp
    vec2 warped = barrel_distort(UV, warp_amount);
    bool on_screen = (warped.x >= 0.0 && warped.x <= 1.0
                   && warped.y >= 0.0 && warped.y <= 1.0);

    // 2. Sample screen (chromatic aberration)
    vec3 col = vec3(0.0);
    if (on_screen) {
        if (chroma_amount > 0.0001) {
            vec2 dir = (warped - 0.5) * chroma_amount;
            col.r = texture(screen_texture, warped + dir).r;
            col.g = texture(screen_texture, warped).g;
            col.b = texture(screen_texture, warped - dir).b;
        } else {
            col = texture(screen_texture, warped).rgb;
        }
    }

    // 3. Bloom
    if (bloom_intensity > 0.001 && on_screen) {
        vec3  acc = vec3(0.0);
        float wt  = 0.0;
        float inv_r2 = 1.0 / max(2.0 * bloom_radius * bloom_radius, 0.001);
        for (int dy = -2; dy <= 2; dy++) {
            for (int dx = -2; dx <= 2; dx++) {
                float dist2 = float(dx * dx + dy * dy);
                float w = exp(-dist2 * inv_r2);
                vec3  s = texture(screen_texture,
                    warped + vec2(float(dx), float(dy)) * texel * bloom_radius).rgb;
                float bf = smoothstep(bloom_threshold, 1.0, luma(s));
                acc += s * w * bf;
                wt  += w;
            }
        }
        col += (acc / max(wt, 0.0001)) * bloom_intensity;
    }

    // 4. Gamma decode
    col = pow(max(col, vec3(0.001)), vec3(gamma_in));

    // 5. Scanlines
    if (scanline_intensity > 0.001) {
        col *= scanline_mod(warped.y, scanline_count,
                            scanline_intensity, scanline_sharpness,
                            scanline_bright_width);
    }

    // 6. RGB shadow mask
    if (mask_intensity > 0.001) {
        vec3 mask = shadow_mask(FRAGCOORD.xy, warped, mask_type,
                                mask_pixel_size, mask_line_count,
                                mask_dark_level);
        col *= mix(vec3(1.0), mask, mask_intensity);
    }

    // 7. Gamma re-encode
    col = pow(max(col, vec3(0.0)), vec3(1.0 / gamma_out));

    // 8. Contrast & brightness
    col = (col - 0.5) * contrast + 0.5;
    col *= brightness;

    // 9. Saturation & phosphor tint
    col = apply_saturation(col, saturation);
    col *= phosphor_tint;

    // 10. Vignette
    if (vignette_intensity > 0.001) {
        col *= vignette(UV, vignette_radius, vignette_intensity, vignette_softness);
    }

    // 11. Film grain
    if (noise_intensity > 0.001) {
        float t = noise_animated ? floor(TIME * 24.0) * 0.037 : 0.0;
        float n = hash(warped + vec2(t, t * 0.731)) * 2.0 - 1.0;
        col += n * noise_intensity;
    }

    // 12. Screen bezel
    if (bevel_corner_radius > 0.001 || bevel_edge_softness > 0.001) {
        float sdf   = rounded_rect_sdf(warped, max(bevel_corner_radius, 0.001));
        float bezel = 1.0 - smoothstep(-bevel_edge_softness,
                                        bevel_edge_softness, sdf);
        col *= bezel;
    }

    if (!on_screen) {
        col = vec3(0.0);
    }

    COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
