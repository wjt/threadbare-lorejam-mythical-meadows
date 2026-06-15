shader_type canvas_item;

uniform vec4  aura_color    : source_color = vec4(0.6, 0.3, 1.0, 1.0);
uniform vec4  core_color    : source_color = vec4(0.9, 0.7, 1.0, 1.0);
uniform float pulse_speed   : hint_range(0.1, 5.0) = 2.0;
uniform float rim_intensity : hint_range(0.0, 3.0) = 1.8;
uniform float particle_amt  : hint_range(0.0, 1.0) = 0.6;
uniform float aura_radius   : hint_range(0.1, 0.5) = 0.35;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV - vec2(0.5);         // centrar UV en 0,0
    float dist = length(uv);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    float angle = atan(uv.y, uv.x);

    // Aura circular principal
    float aura = smoothstep(aura_radius + 0.05, aura_radius, dist);
    aura *= smoothstep(0.0, aura_radius * 0.3, dist); // hueco en el centro
    aura *= (0.7 + 0.3 * pulse);

    // Anillo pulsante
    float ring_dist = abs(dist - aura_radius * (0.85 + 0.08 * pulse));
    float ring = smoothstep(0.03, 0.0, ring_dist) * (0.5 + 0.5 * pulse);

    // Rayos giratorios
    float ray_angle = mod(angle + TIME * 0.6, TAU / 4.0);
    float ray = smoothstep(0.12, 0.0, abs(ray_angle - TAU / 8.0));
    ray *= smoothstep(aura_radius, aura_radius * 0.2, dist) * pulse;

    // Chispas orbitales
    vec2 uv_spark = UV * 6.0 + vec2(TIME * 0.3, TIME * 0.25);
    float s1 = hash(floor(uv_spark));
    float s2 = hash(floor(uv_spark + vec2(4.1, 2.3)));
    float sparks = smoothstep(0.93, 1.0, s1) * smoothstep(0.90, 1.0, s2);
    sparks *= step(dist, aura_radius + 0.05) * particle_amt * pulse;

    // Mezcla
    vec3 col = aura_color.rgb * aura * rim_intensity;
    col += core_color.rgb * ring * 2.0;
    col += aura_color.rgb * ray * 0.8;
    col += core_color.rgb * sparks * 3.0;

    float alpha = max(aura * aura_color.a, max(ring, max(ray * 0.6, sparks)));
    alpha = clamp(alpha, 0.0, 1.0);

    COLOR = vec4(col, alpha);
}