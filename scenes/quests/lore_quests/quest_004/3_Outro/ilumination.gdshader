shader_type canvas_item;
render_mode unshaded; // Mantiene al personaje brillante e ignora la oscuridad ambiental

// --- Parámetros de la iluminación total (interior) ---
uniform vec4 illumination_tint : source_color = vec4(1.0, 1.0, 0.9, 1.0); // Tinte crema/amarillo pálido para el interior
uniform float illumination_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec4 rim_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec2 light_direction = vec2(1.0, 0.0);
uniform float rim_thickness : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec4 sprite_pixel = texture(TEXTURE, UV);
    if (sprite_pixel.a > 0.0) {
        vec2 size = TEXTURE_PIXEL_SIZE * rim_thickness;
        float alpha_ahead = texture(TEXTURE, UV + (light_direction * size)).a;
        if (alpha_ahead == 0.0) {
            COLOR = vec4(rim_color.rgb, sprite_pixel.a * rim_color.a);
        } else {
            vec3 illuminated_rgb = sprite_pixel.rgb * illumination_tint.rgb * illumination_strength;
            COLOR = vec4(illuminated_rgb, sprite_pixel.a);
        }
    } else {
        COLOR = vec4(0.0);
    }
}