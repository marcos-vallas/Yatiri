shader_type canvas_item;

// 🔹 Export para manejar desde el inspector de Godot
uniform bool effect_enabled = false;
uniform vec3 flash_color : source_color = vec3(1.0,0.0,0.0);
uniform vec3 base_color : source_color = vec3(1.0,1.0,1.0); // color base de tu sprite

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // 🔹 Aplicar el color base del sprite (por ejemplo, tu tono oscuro)
    vec4 colored_tex = tex * vec4(base_color, 1.0);

    if (effect_enabled) {
        // 🔹 Mezcla con el color del flash
        COLOR = mix(colored_tex, vec4(flash_color, tex.a), 0.7);
    } else {
        COLOR = colored_tex;
    }
}
