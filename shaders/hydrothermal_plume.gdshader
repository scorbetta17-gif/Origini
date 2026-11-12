shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

// One low-poly instanced mesh, no textures or screen/depth buffer dependency.
varying vec4 puff_color;
void vertex() {
    puff_color = COLOR;
}
void fragment() {
    float facing = max(0.0, dot(normalize(NORMAL), normalize(VIEW)));
    ALBEDO = puff_color.rgb;
    ROUGHNESS = 1.0;
    ALPHA = puff_color.a * smoothstep(.0, .65, facing);
}
