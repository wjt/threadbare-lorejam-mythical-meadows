shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5, 0.5);
uniform float force = 0.0;
uniform float wave_frequency = 20.0;
uniform float chroma_split = 0.008;

void fragment() {
    vec2 delta = UV - center;
    float dist = length(delta);
    vec2 dir = normalize(delta);

    // Onda en anillo que se expande desde el centro
    float wave = sin(dist * wave_frequency - force * 30.0) * force;
    vec2 disp = dir * wave;

    // Chromatic aberration: cada canal se desplaza distinto
    float r = texture(screen_texture, SCREEN_UV + disp + dir * chroma_split * force * 10.0).r;
    float g = texture(screen_texture, SCREEN_UV + disp).g;
    float b = texture(screen_texture, SCREEN_UV + disp - dir * chroma_split * force * 10.0).b;

    COLOR = vec4(r, g, b, 1.0);
}