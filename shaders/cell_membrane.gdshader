shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley;
uniform vec4 membrane_tint : source_color = vec4(0.43, 0.73, 0.69, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.62, 0.86, 0.81, 1.0);
uniform float opacity : hint_range(0.0,1.0) = .28;
uniform float membrane_motion : hint_range(0.0,0.04) = .010;
uniform float internal_scattering : hint_range(0.0,1.0) = .46;
uniform float membrane_time = 0.0;
uniform float surface_phase = 0.0;
uniform float flexibility = 1.0;
varying vec3 sphere_p;

float hash3(vec3 p) {
    return fract(sin(dot(p,vec3(17.17,79.13,113.31)))*45321.37);
}
void vertex() {
    sphere_p = VERTEX;
    // Low-order smooth undulations, bounded amplitude; no particle/explosion mode.
    float wave = sin(VERTEX.x*3.1+membrane_time*.72)*sin(VERTEX.z*2.4-membrane_time*.53);
    float azimuth=atan(VERTEX.z,VERTEX.x);
    float lobes=sin(azimuth*3.0+membrane_time*.31)*.035+cos(azimuth*2.0-membrane_time*.23)*.025;
    float equator=clamp(length(VERTEX.xz),0.0,1.0);
    VERTEX += NORMAL * (wave * membrane_motion+lobes*equator*flexibility);
}
void fragment() {
    float facing = abs(dot(normalize(NORMAL),normalize(VIEW)));
    float edge = pow(1.0-facing,2.4);
    float micro = hash3(floor(sphere_p*33.0));
    float top_light = smoothstep(-.65,.85,normalize(NORMAL).y);
    vec3 subsurface = membrane_tint.rgb*(.79+.16*top_light);
    vec3 base = mix(subsurface,rim_tint.rgb,edge*.63);
    // Tangential material flow gives the membrane a liquid surface identity.
    float surface_flow = sin(atan(sphere_p.z,sphere_p.x)*8.0+sphere_p.y*5.0-surface_phase);
    base += rim_tint.rgb*surface_flow*.025*edge*flexibility;
    base += (micro-.5)*.014;
    ALBEDO = base;
    ROUGHNESS = .42;
    SPECULAR = .36;
    RIM = .38;
    RIM_TINT = .57;
    ALPHA = clamp(opacity*(.72+internal_scattering*.27) + edge*.62, .08, .72);
    EMISSION = rim_tint.rgb * edge*.26;
}
