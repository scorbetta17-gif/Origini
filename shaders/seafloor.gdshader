shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

// Teal / blue sandy rock sediment seen from the TOP-DOWN isometric camera.
// Sparse shifting underwater caustics, not bright lava or magical terrain.
uniform vec3 sand_dark : source_color = vec3(0.050,0.174,0.212);
uniform vec3 sand_light : source_color = vec3(0.112,0.295,0.332);
varying vec3 seabed_pos;

float hash21(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453);
}
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),
               mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
    seabed_pos = VERTEX;
    VERTEX.y += (sin(VERTEX.x*0.37+VERTEX.z*0.16)
               + cos(VERTEX.z*0.49-VERTEX.x*0.17)) * 0.042;
}
void fragment() {
    vec2 p = seabed_pos.xz;
    float broad = noise2(p*.23)*.55 + noise2(p*.57)*.31 +
                  noise2(p*2.2)*.14;
    float sand_waves = sin(p.y*2.0 + noise2(p*.23)*3.0)*.018;
    vec3 base = mix(sand_dark,sand_light,clamp(.12+broad*.86+sand_waves,0.0,1.0));
    // Subtle bottom-of-sea color variation.
    float sediment = noise2(p*8.0);
    base += vec3(.008,.017,.015)*(sediment-.50);
    // Soft moving dappled highlights: intentionally low contrast so cell
    // silhouettes and molecular nutrients retain higher visual priority.
    float beam1 = sin((p.x+p.y*.32)*1.35 + TIME*.20 + noise2(p*.34)*2.4);
    float beam2 = sin((p.y-p.x*.50)*1.20 - TIME*.14);
    float caustic = pow(max(0.0,beam1*beam2),4.0);
    base += vec3(.025,.062,.065)*caustic;
    ALBEDO = base;
    ROUGHNESS = .92;
    SPECULAR = .18;
}
