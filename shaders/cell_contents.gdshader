shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 pigment : source_color = vec4(0.9,0.5,0.95,1.0);
void fragment() {
    vec3 n=normalize(NORMAL);
    float key=max(dot(n,normalize(vec3(-0.5,0.7,0.8))),0.0);
    float spec=pow(max(dot(n,normalize(vec3(-0.3,0.4,0.9))),0.0),20.0);
    ALBEDO=pigment.rgb*(0.48+0.52*key)+vec3(1.0,0.9,0.8)*spec*0.16;
}
