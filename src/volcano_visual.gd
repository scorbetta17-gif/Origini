extends Node3D
## Reference-driven basalt vent. All features are world-space geometry.
## Incandescent basin and plume are an artistic abstraction, not a fluid model.
const LAVA = preload("res://shaders/volcanic_lava.gdshader")
const PLUME = preload("res://shaders/hydrothermal_plume.gdshader")
const CONTACT = preload("res://shaders/cell_contact_shadow.gdshader")
const SECTORS: int = 18
const PUFF_COUNT: int = 18
var basin_height: float
var rim_min_height: float
var crater_radius: float
var plume: MultiMeshInstance3D
var plume_positions: Array[Vector3] = []
var elapsed: float = 0.0
var vent_height: float
var vent_radius: float

func setup(radius: float, height: float, visual_seed: int) -> void:
    vent_radius = radius
    vent_height = height
    basin_height = height * .68
    crater_radius = radius * .32
    rim_min_height = height * .90
    var rng := RandomNumberGenerator.new()
    rng.seed = visual_seed
    var rock := SurfaceTool.new()
    rock.begin(Mesh.PRIMITIVE_TRIANGLES)
    rock.set_smooth_group(-1)
    var cracks := SurfaceTool.new()
    cracks.begin(Mesh.PRIMITIVE_TRIANGLES)
    cracks.set_smooth_group(-1)
    var rings: Array[PackedVector3Array] = []
    # The same profiles drive rock and cracks, so light cannot float off a slope.
    for i in range(SECTORS):
        var angle: float = TAU * float(i) / SECTORS
        var toe: float = radius * rng.randf_range(.92, 1.16)
        var top: float = height * rng.randf_range(.90, 1.09)
        var profile := PackedVector3Array()
        profile.append(_radial(angle, toe, .018))
        profile.append(_radial(angle + rng.randf_range(-.05, .05), toe * .82, height * rng.randf_range(.13, .23)))
        profile.append(_radial(angle + rng.randf_range(-.07, .07), radius * rng.randf_range(.57, .70), height * rng.randf_range(.40, .60)))
        profile.append(_radial(angle, radius * rng.randf_range(.43, .49), top))
        profile.append(_radial(angle, crater_radius * rng.randf_range(1.02, 1.12), top - .035))
        profile.append(_radial(angle, crater_radius * .87, basin_height - .045))
        rings.append(profile)
    for i in range(SECTORS):
        var next: int = (i + 1) % SECTORS
        var left: PackedVector3Array = rings[i]
        var right: PackedVector3Array = rings[next]
        var tint := Color(.105, .155, .23).lightened(rng.randf_range(.0, .075))
        for level in range(5):
            var face_color: Color = tint.darkened(.16 if level == 0 else .0)
            if level == 3:
                face_color = tint.lightened(.07)
            elif level == 4:
                face_color = tint.darkened(.24).lerp(Color(.36, .12, .055), .34)
            # Inset slab edges expose a narrow dark fracture between blocks.
            var a: Vector3 = left[level].lerp(right[level], .012)
            var b: Vector3 = right[level].lerp(left[level], .012)
            var c: Vector3 = right[level + 1].lerp(left[level + 1], .012)
            var d: Vector3 = left[level + 1].lerp(right[level + 1], .012)
            _quad(rock, a, b, c, d, face_color)
            # Only selected fractures are hot. Others retain dark basalt seams.
            if i % 3 == 1 and level < 4:
                var edge: Vector3 = left[level]
                var upper: Vector3 = left[level + 1]
                var tangent := Vector3(-sin(TAU * i / SECTORS), 0, cos(TAU * i / SECTORS))
                var width: float = radius * (.009 if level == 0 else .014)
                _quad(cracks, edge - tangent * width, edge + tangent * width,
                    upper + tangent * width, upper - tangent * width, Color.WHITE)
                if level == 1 and i % 2 == 1:
                    # Branch on the same planar triangle, slightly raised to
                    # avoid depth fighting (no disconnected floating ribbons).
                    var start: Vector3 = a.lerp(d, .58) + Vector3(0, .012, 0)
                    var finish: Vector3 = a.lerp(b, .62) + Vector3(0, .012, 0)
                    var offset: Vector3 = (finish - start).cross(Vector3.UP).normalized() * width * .5
                    _quad(cracks, start - offset, start + offset,
                        finish + offset, finish - offset, Color.WHITE)
            # Recessed joint walls give cracks thickness without extra nodes.
            var depth := Vector3(0, -.07, 0)
            _quad(rock, left[level], left[level + 1], left[level + 1] + depth,
                left[level] + depth, tint.darkened(.45))
        # A few angular talus blocks, baked into the same draw call.
        if i % 2 == 0:
            var angle: float = TAU * (float(i) + .4) / SECTORS
            _boulder(rock, _radial(angle, radius * rng.randf_range(.85, 1.10), .0),
                Vector3(radius * .22, height * .19, radius * .17), rng, tint)
        # Overlapping fractured slabs break the regular cone silhouette.
        # Their top faces are bevelled and uneven rather than smooth spheres.
        var ridge: Vector3 = left[1].lerp(right[1], .45)
        _boulder(rock, ridge - Vector3(0, height * .09, 0),
            Vector3(radius * .15, height * rng.randf_range(.18, .31), radius * .12), rng, tint)
        if i % 3 != 1:
            var upper_ridge: Vector3 = left[2].lerp(right[2], .52)
            _boulder(rock, upper_ridge - Vector3(0, height * .045, 0),
                Vector3(radius * .115, height * rng.randf_range(.18, .28), radius * .11), rng, tint)
    # Smaller broken fragments around the apron; same vertex-color material.
    for i in range(16):
        var angle: float = rng.randf() * TAU
        var size: float = radius * rng.randf_range(.045, .12)
        _boulder(rock, _radial(angle, radius * rng.randf_range(1.08, 1.35), .0),
            Vector3(size, size * .65, size * .83), rng, Color(.18, .27, .32))
    var basalt := StandardMaterial3D.new()
    basalt.vertex_color_use_as_albedo = true
    basalt.vertex_color_is_srgb = true
    basalt.roughness = .96
    _mesh(rock, "Basalto_stratificato", basalt)
    var heat := ShaderMaterial.new()
    heat.shader = LAVA
    _mesh(cracks, "Fratture_incandescenti", heat)
    var basin := SurfaceTool.new()
    basin.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(SECTORS):
        var angle: float = TAU * float(i) / SECTORS
        var next_angle: float = TAU * float(i + 1) / SECTORS
        _tri(basin, Vector3(0, basin_height, 0),
            _radial(angle, crater_radius, basin_height),
            _radial(next_angle, crater_radius, basin_height), Color.WHITE)
    _mesh(basin, "Bacino_incassato", heat)
    var shadow := MeshInstance3D.new()
    shadow.name = "Ombra_di_contatto"
    var plane := PlaneMesh.new()
    plane.size = Vector2.ONE * radius * 3.0
    shadow.mesh = plane
    shadow.position.y = .06
    var shadow_material := ShaderMaterial.new()
    shadow_material.shader = CONTACT
    shadow_material.set_shader_parameter("strength", .42)
    shadow.material_override = shadow_material
    shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shadow)
    _build_plume()

func _radial(angle: float, radius: float, y: float) -> Vector3:
    return Vector3(cos(angle) * radius, y, sin(angle) * radius)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, tint: Color) -> void:
    _tri(st, a, b, c, tint)
    _tri(st, a, c, d, tint)

func _mesh(st: SurfaceTool, label: String, material: Material) -> MeshInstance3D:
    st.generate_normals()
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = st.commit()
    node.material_override = material
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node)
    return node

func _boulder(st: SurfaceTool, center: Vector3, dimensions: Vector3,
        rng: RandomNumberGenerator, tint: Color) -> void:
    var bottom := PackedVector3Array()
    var top := PackedVector3Array()
    var rotation: float = rng.randf() * TAU
    for j in range(6):
        var angle: float = rotation + TAU * float(j) / 6.0
        var point := Vector3(cos(angle) * dimensions.x, 0, sin(angle) * dimensions.z)
        bottom.append(center + point)
        top.append(center + point * rng.randf_range(.55, .82) + Vector3(0, dimensions.y * rng.randf_range(.8, 1.2), 0))
    for j in range(6):
        var next: int = (j + 1) % 6
        _quad(st, bottom[j], bottom[next], top[next], top[j], tint.darkened(.08 if j % 2 == 0 else .0))
        _tri(st, center + Vector3(0, dimensions.y, 0), top[j], top[next], tint.lightened(.06))

func _build_plume() -> void:
    var puff := SphereMesh.new()
    puff.radius = 1.0
    puff.height = 2.0
    puff.radial_segments = 8
    puff.rings = 4
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.mesh = puff
    mm.instance_count = PUFF_COUNT
    plume = MultiMeshInstance3D.new()
    plume.name = "Pennacchio_idrotermale"
    plume.multimesh = mm
    plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := ShaderMaterial.new()
    material.shader = PLUME
    plume.material_override = material
    add_child(plume)
    plume_positions.resize(PUFF_COUNT)
    _animate_plume()

func _process(delta: float) -> void:
    elapsed += maxf(0.0, delta)
    _animate_plume()

func _animate_plume() -> void:
    if not is_instance_valid(plume):
        return
    for i in range(PUFF_COUNT):
        var rise: float = fposmod(float(i) / PUFF_COUNT + elapsed * .105, 1.0)
        var phase: float = float(i) * 2.39996
        var spread: float = vent_radius * (.025 + rise * .12)
        var position: Vector3 = Vector3(
            sin(phase + elapsed * .22) * spread + rise * rise * vent_radius * .5,
            basin_height + .15 + rise * vent_height * 2.35,
            cos(phase + elapsed * .19) * spread - rise * rise * vent_radius * .14)
        var scale: float = vent_radius * (.08 + rise * .18)
        var alpha: float = .34 * smoothstep(.0, .10, rise) * (1.0 - smoothstep(.62, 1.0, rise))
        var color: Color = Color(.59, .39, .27).lerp(Color(.30, .47, .53), minf(1.0, rise * 4.0))
        if RenderingServer.get_current_rendering_method() != "gl_compatibility":
            color = color.srgb_to_linear()
        color.a = alpha
        plume_positions[i] = position
        plume.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(scale, scale * 1.30, scale)), position))
        plume.multimesh.set_instance_color(i, color)
