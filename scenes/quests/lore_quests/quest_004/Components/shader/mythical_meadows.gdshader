shader_type canvas_item;

uniform vec4  color_a     : source_color = vec4(0.6, 0.3, 1.0, 1.0);
uniform vec4  color_b     : source_color = vec4(0.8, 0.5, 1.0, 1.0);
uniform float speed       : hint_range(0.05, 2.0) = 0.3;
uniform float amount      : hint_range(5.0, 200.0) = 30.0;
uniform float psize       : hint_range(0.001, 0.02) = 0.006;
uniform float opacity     : hint_range(0.0, 1.0)  = 0.45;
uniform float wobble      : hint_range(0.0, 2.0)  = 0.8;

float hash11(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec4 col = vec4(0.0);

    for (float i = 0.0; i < 80.0; i++) {
        if (i >= amount) break;

        // Propiedades únicas por partícula
        float seed       = i * 17.3;
        float life_speed = 0.04 + hash11(seed) * 0.06;
        float phase      = hash11(seed * 3.1);
        float life       = fract(TIME * life_speed * speed + phase);

        // Posición: sube suavemente con wobble horizontal
        float base_x  = hash11(seed * 5.7);
        float base_y  = 1.0 - life;                          // sube de abajo
        float wx      = sin(TIME * (0.5 + hash11(seed*2.3)) + seed) 
                        * wobble * 0.04 * life;
        vec2 ppos     = vec2(base_x + wx, base_y);

        // Alpha: fade in y fade out suave
        float alpha   = sin(life * PI) * opacity;
        alpha        *= 0.3 + hash11(seed * 7.9) * 0.7;     // variación por partícula

        // Tamaño variable
        float ps = psize * (0.5 + hash11(seed * 11.3) * 1.0);

        // Distancia al píxel actual
        float d = length(uv - ppos);

        // Halo suave + núcleo
        float halo  = smoothstep(ps * 4.0, 0.0, d);
        float core  = smoothstep(ps * 0.8, 0.0, d);

        // Color alternado entre color_a y color_b
        float t_col = hash11(seed * 13.7);
        vec3  pcol  = mix(color_a.rgb, color_b.rgb, t_col);

        col.rgb += pcol  * halo  * alpha;
        col.rgb += vec3(1.0) * core * alpha * 0.9;   // núcleo blanco
        col.a   += halo * alpha;
    }

    col.a   = clamp(col.a,   0.0, 1.0);
    col.rgb = clamp(col.rgb, 0.0, 1.0);
    COLOR   = col;
}