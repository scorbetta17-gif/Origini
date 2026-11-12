shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 shadow_color : source_color = vec4(0.018,0.048,0.055,1.0);
uniform float strength : hint_range(0.0,1.0) = .35;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float d = length(p);
    float soft = 1.0-smoothstep(.22,.98,d);
    ALBEDO = shadow_color.rgb;
    ALPHA = soft*strength;
}
