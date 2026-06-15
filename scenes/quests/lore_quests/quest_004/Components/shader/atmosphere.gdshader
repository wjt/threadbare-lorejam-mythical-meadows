shader_type canvas_item;

uniform float grain_strength  : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_str    : hint_range(0.0, 1.0) = 0.55;
uniform float vignette_radius : hint_range(0.1, 1.0) = 0.7;
uniform float wave_speed      : hint_range(0.0, 3.0) = 0.8;
uniform float wave_strength   : hint_range(0.0, 1.0) = 0.3;
uniform vec4  tint_color      : source_color = vec4(0.1, 0.05, 0.2, 1.0);
uniform float tint_strength   : hint_range(0.0, 1.0) = 0.15;

float hash(vec2 p, float t) {
    return fract(sin(dot(p + t, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 center = uv - vec2(0.5);
    vec4 col = vec4(0.0);

    // --- Tinte de color ambiental ---
    col.rgb = tint_color.rgb * tint_strength;
    col.a   = tint_strength * 0.5;

    // --- Viñeta ---
    float vig = smoothstep(vignette_radius - 0.3, vignette_radius + 0.3, length(center));
    vig *= vignette_str;
    col.rgb = mix(col.rgb, vec3(0.0), vig);
    col.a   = max(col.a, vig * vignette_str);

    // --- Ondas de luz (simula reflejos mágicos) ---
    float wave1 = sin(uv.x * 8.0 + TIME * wave_speed) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 6.0 + TIME * wave_speed * 0.7) * 0.5 + 0.5;
    float waves = wave1 * wave2 * wave_strength * 0.04;
    col.rgb += tint_color.rgb * waves;
    col.a   += waves * 0.5;

    // --- Film grain ---
    vec2 grain_uv = floor(uv * 200.0);
    float noise = hash(grain_uv, floor(TIME * 20.0));
    float grain = (noise - 0.5) * grain_strength * 0.06;
    col.rgb += vec3(grain);
    col.a   += abs(grain) * 0.3;

    col = clamp(col, 0.0, 1.0);
    COLOR = col;
}