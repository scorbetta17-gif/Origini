shader_type spatial;
render_mode cull_back;

// Stylized local heat, visible even in Android Compatibility without bloom.
uniform vec3 hot_dark : source_color = vec3(.95, .085, .008);
uniform vec3 hot_bright : source_color = vec3(1.0, .40, .035);
uniform vec3 crust_color : source_color = vec3(.19, .045, .018);
varying vec3 local_position;
void vertex() {
    local_position = VERTEX;
}
void fragment() {
    vec2 p = local_position.xz * 8.0;
    float waves = sin(p.x + sin(p.y * 1.3 + TIME * .35))
        * cos(p.y - sin(p.x * .9 - TIME * .28));
    float crust = smoothstep(.25, .68, waves);
    vec3 hot = mix(hot_dark, hot_bright,
        smoothstep(-.8, .2, waves));
    vec3 color = mix(hot, crust_color, crust * .84);
    ALBEDO = color * .45;
    EMISSION = color * 1.12;
    ROUGHNESS = .82;
}
