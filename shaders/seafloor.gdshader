shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_back;
// Static geological detail, with no moving light pattern.
uniform vec3 basalt : source_color = vec3(.12,.24,.28);
uniform vec3 sediment : source_color = vec3(.22,.33,.35);
varying vec3 seabed_pos;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
    vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
// Mineral plates form irregular patches, without luminous borders.
float plates(vec2 p) {
    vec2 cell=floor(p); vec2 f=fract(p); float nearest=10.0; float tone=0.0;
    for(int y=-1;y<=1;y++) { for(int x=-1;x<=1;x++) {
        vec2 tile=vec2(float(x),float(y));
        vec2 jitter=vec2(hash21(cell+tile),hash21(cell+tile+vec2(19.7,6.3)));
        vec2 v=tile+jitter-f; float d=dot(v,v);
        if(d<nearest) { nearest=d; tone=hash21(cell+tile+43.7); }
    }}
    return tone;
}
void vertex() { seabed_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p=seabed_pos.xz;
    float deposits=smoothstep(.65,.88,noise2(p*.025)+noise2(p*.17)*.12)*.65;
    float grain=noise2(p*13.0)-.5;
    float strata=sin(p.y*5.5+noise2(p*.32)*5.0)*.008;
    float depth=clamp((-seabed_pos.y-.8)*.10,0.0,.25);
    ALBEDO=mix(basalt,sediment,deposits)*(1.0-depth+grain*.025+strata+(plates(p*.35)-.5)*.22);
    ROUGHNESS=.98;
    SPECULAR=0.0;
}
