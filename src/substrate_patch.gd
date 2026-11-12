extends MeshInstance3D
## An organic aggregate, visibly distinct from freely absorbable molecules.
var portions: int = 3
var caption: Label3D

func setup(seed_value: int, remaining: int = 3) -> void:
    portions = clampi(remaining,1,3)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    for i in range(13):
        var center := Vector3(rng.randf_range(-.5,.5),rng.randf_range(.05,.22),rng.randf_range(-.5,.5))
        var radius: float = rng.randf_range(.14,.25)
        for j in range(6):
            var a: float = TAU*j/6.0
            var b: float = TAU*(j+1)/6.0
            st.set_color(Color(.62,.42,.18).lightened(rng.randf_range(0,.18)))
            st.add_vertex(center+Vector3(cos(a),0,sin(a))*radius)
            st.add_vertex(center+Vector3(cos(b),0,sin(b))*radius)
            st.add_vertex(center+Vector3(0,radius,0))
    st.generate_normals()
    mesh = st.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.vertex_color_is_srgb = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.roughness = .86
    material_override = material
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    caption = Label3D.new()
    caption.text = "SUBSTRATO"
    caption.position.y = .65
    caption.font_size = 28
    caption.pixel_size = .007
    caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(caption)
    set_portions(portions)

func set_portions(value: int) -> void:
    portions = value
    if is_instance_valid(caption):
        caption.text = "SUBSTRATO · %d" % maxi(0,value)
    scale = Vector3.ONE*(.55+.15*portions)
