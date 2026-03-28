// =============================================================================
// VHS Tape Playback Emulation Shader
// Godot 4.x — canvas_item (full-screen post-process)
//
// FEATURES:
//   • Horizontal color bleeding / chroma smear
//   • Wavy horizontal distortion (tracking wobble)
//   • Rolling noise bands (tape head switching artifacts)
//   • Vertical jitter (unstable sync)
//   • Color channel offset (Y/C separation errors)
//   • Slight desaturation and warm color shift
//   • Static noise overlay
//   • Bottom-of-frame head-switch distortion
// =============================================================================

shader_type canvas_item;

// ── Tracking / Distortion ────────────────────────────────────────────────────
group_uniforms Tracking;

// Horizontal wobble amplitude (0 = stable, 0.01 = subtle, 0.05 = bad tracking)
uniform float wobble_amount        : hint_range(0.0,  0.1,  0.001) = 0.002;

// Wobble animation speed
uniform float wobble_speed         : hint_range(0.0,  20.0, 0.1)   = 3.0;

// Vertical jitter amplitude (sync instability)
uniform float jitter_amount        : hint_range(0.0,  0.02, 0.0005) = 0.001;

// Head-switch noise band at bottom of frame (0 = off, 1 = full)
uniform float head_switch_amount   : hint_range(0.0,  1.0,  0.01)  = 0.06;

group_uniforms;

// ── Color Bleeding ───────────────────────────────────────────────────────────
group_uniforms ColorBleed;

// Horizontal chroma smear width (in UV, 0 = off)
uniform float bleed_amount         : hint_range(0.0,  0.02, 0.0005) = 0.004;

// Number of blur taps for the smear (higher = smoother but heavier)
uniform int   bleed_taps           : hint_range(2, 12)              = 6;

group_uniforms;

// ── Color / Tone ─────────────────────────────────────────────────────────────
group_uniforms Color;

// Desaturation (1.0 = full color, 0.5 = washed out, 0.0 = greyscale)
uniform float saturation           : hint_range(0.0,  1.5,  0.01)  = 0.80;

// Warm VHS color tint (slightly yellow/magenta)
uniform vec3  tape_tint            : source_color                   = vec3(1.0, 0.95, 0.88);

// Brightness boost to compensate for desaturation
uniform float brightness           : hint_range(0.5,  1.5,  0.01)  = 1.02;

// Contrast
uniform float contrast             : hint_range(0.5,  1.5,  0.01)  = 0.95;

group_uniforms;

// ── Noise / Static ───────────────────────────────────────────────────────────
group_uniforms Noise;

// Overall static noise intensity
uniform float noise_intensity      : hint_range(0.0,  0.3,  0.005) = 0.04;

// Rolling noise band intensity
uniform float band_noise_intensity : hint_range(0.0,  0.5,  0.01)  = 0.08;

// Speed of the rolling noise bands
uniform float band_speed           : hint_range(0.0,  10.0, 0.1)   = 2.5;

group_uniforms;

// ── Channel Offset ───────────────────────────────────────────────────────────
group_uniforms ChannelOffset;

// Horizontal R/B channel separation (Y/C delay error)
uniform float channel_offset       : hint_range(0.0,  0.01, 0.0002) = 0.0015;

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

float hash1(float p) {
    return fract(sin(p * 78.233) * 43758.5453);
}

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Smooth noise for wobble
float smooth_noise(float x) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash1(i), hash1(i + 1.0), f);
}

// =============================================================================
// Main fragment shader
// =============================================================================
void fragment() {
    vec2 uv = UV;
    float time = TIME;

    // ── 1. Vertical jitter (sync instability) ───────────────────────────────
    if (jitter_amount > 0.0001) {
        float jit = (hash1(floor(time * 30.0)) * 2.0 - 1.0) * jitter_amount;
        uv.y += jit;
    }

    // ── 2. Horizontal wobble (tracking distortion) ──────────────────────────
    if (wobble_amount > 0.0001) {
        float wave1 = sin(uv.y * 40.0 + time * wobble_speed) * 0.5;
        float wave2 = sin(uv.y * 80.0 - time * wobble_speed * 1.3) * 0.3;
        float wave3 = smooth_noise(uv.y * 15.0 + time * 0.7) * 0.2;
        uv.x += (wave1 + wave2 + wave3) * wobble_amount;
    }

    // ── 3. Head-switch distortion at bottom of frame ────────────────────────
    if (head_switch_amount > 0.001) {
        float bottom = smoothstep(1.0 - head_switch_amount, 1.0, uv.y);
        float hs_noise = smooth_noise(time * 12.0 + uv.y * 50.0);
        uv.x += bottom * (hs_noise * 2.0 - 1.0) * 0.05;
    }

    // Clamp UV after distortion
    vec2 sample_uv = clamp(uv, vec2(0.0), vec2(1.0));

    // ── 4. Color channel offset (Y/C separation error) ──────────────────────
    vec3 col;
    if (channel_offset > 0.0001) {
        col.r = texture(screen_texture, sample_uv + vec2(channel_offset, 0.0)).r;
        col.g = texture(screen_texture, sample_uv).g;
        col.b = texture(screen_texture, sample_uv - vec2(channel_offset, 0.0)).b;
    } else {
        col = texture(screen_texture, sample_uv).rgb;
    }

    // ── 5. Horizontal color bleeding (chroma smear) ─────────────────────────
    if (bleed_amount > 0.0001) {
        vec3 bleed = vec3(0.0);
        float total_weight = 0.0;
        for (int i = 0; i < bleed_taps; i++) {
            float t = float(i) / float(bleed_taps - 1);
            float offset = t * bleed_amount;
            float w = 1.0 - t; // linear falloff
            bleed += texture(screen_texture, sample_uv + vec2(offset, 0.0)).rgb * w;
            total_weight += w;
        }
        bleed /= total_weight;
        // Only bleed chroma, keep luma from original sample
        float orig_luma = luma(col);
        vec3 bleed_chroma = bleed - vec3(luma(bleed));
        col = vec3(orig_luma) + bleed_chroma;
    }

    // ── 6. Desaturation & tone ──────────────────────────────────────────────
    float l = luma(col);
    col = mix(vec3(l), col, saturation);
    col = (col - 0.5) * contrast + 0.5;
    col *= brightness;
    col *= tape_tint;

    // ── 7. Rolling noise bands ──────────────────────────────────────────────
    if (band_noise_intensity > 0.001) {
        float band_pos = fract(uv.y * 3.0 - time * band_speed);
        float band = smoothstep(0.0, 0.05, band_pos) * (1.0 - smoothstep(0.05, 0.15, band_pos));
        float band_noise = hash(vec2(uv.x * 100.0, floor(time * 24.0))) * 2.0 - 1.0;
        col += band * band_noise * band_noise_intensity;
    }

    // ── 8. Static noise overlay ─────────────────────────────────────────────
    if (noise_intensity > 0.001) {
        float t = floor(time * 24.0) * 0.037;
        float n = hash(uv * vec2(320.0, 180.0) + vec2(t, t * 0.731)) * 2.0 - 1.0;
        col += n * noise_intensity;
    }

    COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
