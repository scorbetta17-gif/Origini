shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley;
uniform vec4 membrane_tint : source_color = vec4(0.43, 0.73, 0.69, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.62, 0.86, 0.81, 1.0);
uniform float opacity : hint_range(0.0,1.0) = .28;
uniform float membrane_motion : hint_range(0.0,0.04) = .010;
uniform float internal_scattering : hint_range(0.0,1.0) = .46;
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
    float facing = abs(dot(normalize(NORMAL),normalize(VIEW)));
    float edge = pow(1.0-facing,2.4);
    float micro = hash3(floor(sphere_p*33.0));
    float top_light = smoothstep(-.65,.85,normalize(NORMAL).y);
    vec3 subsurface = membrane_tint.rgb*(.79+.16*top_light);
    vec3 base = mix(subsurface,rim_tint.rgb,edge*.63);
    base += (micro-.5)*.014;
    ALBEDO = base;
    ROUGHNESS = .42;
    SPECULAR = .36;
    RIM = .28;
    RIM_TINT = .40;
    ALPHA = clamp(opacity*(.72+internal_scattering*.27) + edge*.37, .08, .64);
    EMISSION = rim_tint.rgb * edge*.025;
}
