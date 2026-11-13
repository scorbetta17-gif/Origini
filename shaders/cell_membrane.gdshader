shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;
uniform vec4 membrane_tint : source_color = vec4(0.43, 0.73, 0.69, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.62, 0.86, 0.81, 1.0);
uniform float opacity : hint_range(0.0,1.0) = .28;
uniform float membrane_motion : hint_range(0.0,0.04) = .010;
uniform float internal_scattering : hint_range(0.0,1.0) = .46;
uniform float membrane_time = 0.0;
uniform float surface_phase = 0.0;
uniform vec3 flow_axis = vec3(1.0,0.0,0.0);
uniform float flow_strain = 0.0;
uniform float flexibility = 1.0;
uniform float division_progress : hint_range(0.0,1.0) = 0.0;
varying vec3 sphere_p;

float hash3(vec3 p) {
    return fract(sin(dot(p,vec3(17.17,79.13,113.31)))*45321.37);
}
void vertex() {
    sphere_p = VERTEX;
    // Low-order smooth undulations, bounded amplitude; no particle/explosion mode.
    float wave = sin(VERTEX.x*3.1+membrane_time*.72)*sin(VERTEX.z*2.4-membrane_time*.53);
    float azimuth=atan(VERTEX.z,VERTEX.x);
    float lobes=sin(azimuth*3.0+membrane_time*.31)*.009+cos(azimuth*2.0-membrane_time*.23)*.006;
    float equator=clamp(length(VERTEX.xz),0.0,1.0);
    float organic = sin(azimuth*3.0+0.65)*0.012+cos(azimuth*5.0-0.7)*0.006;
    float pressure = -max(0.0,dot(normalize(VERTEX),flow_axis))*flow_strain*.22;
    VERTEX += NORMAL * (wave * membrane_motion+(lobes+organic)*equator*flexibility+pressure);
    float division = clamp(division_progress,0.0,1.0);
    float elongation = 1.0+0.48*smoothstep(0.0,0.7,division);
    float cleavage = 0.82*smoothstep(0.30,1.0,division);
    float waist = 1.0-cleavage*exp(-VERTEX.x*VERTEX.x*12.0);
    VERTEX.x *= elongation;
    VERTEX.yz *= waist;
}
void fragment() {
    vec3 n = normalize(NORMAL);
    float facing = clamp(dot(n,normalize(VIEW)),0.0,1.0);
    float rim = pow(1.0-facing,1.7);
    float shoulder = pow(1.0-facing,0.65);
    float highlight = pow(max(dot(n,normalize(vec3(-0.45,0.65,0.65))),0.0),18.0);
    float broad = pow(max(dot(n,normalize(vec3(-0.4,0.6,0.7))),0.0),3.0);
    vec3 cytoplasm = mix(membrane_tint.rgb*0.48,membrane_tint.rgb*0.85,broad);
    vec3 edge_color = mix(membrane_tint.rgb,rim_tint.rgb,rim);
    ALBEDO = mix(cytoplasm,edge_color,shoulder*0.75)+vec3(0.65,0.9,1.0)*highlight*0.38;
    ALPHA = clamp(0.025+opacity*0.12+rim*0.46+highlight*0.12,0.0,0.94);
}
