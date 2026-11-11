shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform vec3 sand_dark : source_color = vec3(0.087, 0.123, 0.129);
uniform vec3 sand_light : source_color = vec3(0.157, 0.190, 0.179);
varying vec3 seabed_pos;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash21(i), hash21(i+vec2(1,0)), f.x),
               mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
    seabed_pos = VERTEX;
    VERTEX.y += (sin(VERTEX.x*0.36+VERTEX.z*0.14)
               + cos(VERTEX.z*0.53-VERTEX.x*0.19)) * 0.035;
}
void fragment() {
    vec2 p = seabed_pos.xz;
    float n = noise2(p*1.25)*0.55+noise2(p*4.0)*0.25+noise2(p*11.0)*0.20;
    float s = sin(p.x*.32 + sin(p.y*.18)*2.3) * 0.045;
    vec3 base = mix(sand_dark,sand_light,clamp(n*0.85+s+0.1,0.0,1.0));
    float grain = hash21(floor(p*9.0));
    float ripple = sin(p.y*2.5 + noise2(p*.27)*3.0);
    base += (grain-.5)*.008 + ripple*.011;
    ALBEDO = base;
    ROUGHNESS = .96;
    SPECULAR = .13;
}
