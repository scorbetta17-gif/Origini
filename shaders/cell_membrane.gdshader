shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley;
uniform vec4 membrane_tint : source_color = vec4(0.43, 0.73, 0.69, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.62, 0.86, 0.81, 1.0);
uniform float opacity : hint_range(0.0,1.0) = .28;
uniform float membrane_motion : hint_range(0.0,0.04) = .010;
varying vec3 sphere_p;

float hash3(vec3 p) {
    return fract(sin(dot(p,vec3(17.17,79.13,113.31)))*45321.37);
}
void vertex() {
    sphere_p = VERTEX;
    float wave = sin(VERTEX.x*12.0+TIME*.6)*sin(VERTEX.z*9.0-TIME*.41);
    VERTEX += NORMAL * (wave * membrane_motion);
}
void fragment() {
    float edge = pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.9);
    float micro = hash3(floor(sphere_p*39.0));
    vec3 base = mix(membrane_tint.rgb,rim_tint.rgb,edge*.85);
    base += (micro-.5)*.036;
    ALBEDO = base;
    ROUGHNESS = .58;
    SPECULAR = .34;
    ALPHA = clamp(opacity + edge*.32 + (micro-.5)*.03, .05, .75);
    EMISSION = rim_tint.rgb * edge*.09;
}
