extends Node3D
## Fondale primordiale isometrico - roccia, sedimento, sorgenti termiche,
## fessure MINERALI con bolle innocue. Niente vegetazione o organismi superiori.
## Sono mesh Godot e particelle 3D reali: la camera puo spostarsi liberamente.
const SEABED = preload("res://shaders/seafloor.gdshader")
const VENTS: Array[Vector3] = [Vector3(-11.0,-.22,3.0),Vector3(16.0,-.22,-14.0)]
const FISSURES: Array[Vector3] = [
    Vector3(-4.9,-.21,-3.7),Vector3(4.6,-.21,5.0),
    Vector3(-7.4,-.21,10.2),Vector3(9.0,-.21,-3.4)
]
var mineral_mats: Array[StandardMaterial3D] = []
var bubble_mat: StandardMaterial3D
var dark_crack: StandardMaterial3D
var crack_rim: StandardMaterial3D
var molten: StandardMaterial3D
var dust_root: MultiMeshInstance3D
var bubbles: MultiMeshInstance3D
var bubble_sources: Array[Dictionary] = []
# CPU world state is readable even when headless Godot disables GPU readback.
var bubble_positions: Array[Vector3] = []
var bubble_time: float = 0.0

func setup(rng: RandomNumberGenerator) -> void:
    for tint in [
        Color(.19,.29,.34),Color(.22,.32,.38),Color(.17,.25,.31),
        Color(.26,.36,.40),Color(.19,.29,.33)
    ]:
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = .94
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        mineral_mats.append(material)
    dark_crack = _mat(Color(.018,.084,.12))
    crack_rim = _mat(Color(.19,.55,.51),.62)
    molten = _mat(Color(.98,.30,.065),1.45)
    bubble_mat = _mat(Color(.56,.88,.98,.59),.38,.59)
    bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bubble_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _sediment()
    # Lasciare libera la zona centrale, dove comincia la cellula: lettura chiara
    # dei nutrienti anche con HUD mobile e zoom isometrico.
    for i in range(104):
        var x: float = rng.randf_range(-32.0,32.0)
        var z: float = rng.randf_range(-32.0,32.0)
        if Vector2(x,z).length() < 4.0:
            continue
        var radius: float = rng.randf_range(.16,.76)
        if i%19 == 0:
            radius *= 1.85
        _stone(Vector3(x,-.22,z),radius,rng)
    for where in [
        Vector3(-4.3,-.22,-1.4),Vector3(5.7,-.22,3.1),
        Vector3(-6.0,-.22,5.5),Vector3(4.8,-.22,-4.5)
    ]:
        _stone(where,rng.randf_range(.29,.63),rng)
    # Pochi vulcani in tutto il mondo, dove il gradiente del gameplay e' caldo.
    _volcano(VENTS[0],2.9,2.05,rng)
    _volcano(VENTS[1],2.1,1.42,rng)
    # Fessure sul fondale: emettono gas e piccole bolle ma NON danno danno.
    _fissure([
        Vector3(-4.9,-.20,-3.7),Vector3(-3.6,-.20,-3.0),
        Vector3(-2.8,-.20,-3.3),Vector3(-1.65,-.20,-2.4)
    ],rng)
    _fissure([
        Vector3(4.6,-.20,5.0),Vector3(3.7,-.20,5.8),
        Vector3(2.6,-.20,5.4),Vector3(1.8,-.20,6.2)
    ],rng)
    _fissure([
        Vector3(-7.4,-.20,10.2),Vector3(-6.6,-.20,10.7),
        Vector3(-5.9,-.20,9.9),Vector3(-5.1,-.20,10.4)
    ],rng)
    _fissure([
        Vector3(9.0,-.20,-3.4),Vector3(9.8,-.20,-2.7),
        Vector3(10.4,-.20,-3.2),Vector3(11.4,-.20,-2.0)
    ],rng)
    # Bolle dinamiche che salgono davvero (asse Y del mondo 3D).
    _register_bubbles(VENTS[0]+Vector3(0,1.92,0),18,5.8,.61,1)
    _register_bubbles(VENTS[1]+Vector3(0,1.32,0),13,4.3,.48,1)
    for fissure in FISSURES:
        _register_bubbles(fissure+Vector3(0,.18,0),11,3.5,.39,0)
    _build_bubbles()
    _dust(rng)

func _mat(color: Color, emission: float = 0.0, opacity: float = 1.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    color.a = opacity
    material.albedo_color = color
    material.roughness = .83
    material.metallic = 0.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if emission > 0.0:
        material.emission_enabled = true
        material.emission = Color(color.r,color.g,color.b)
        material.emission_energy_multiplier = emission
    if opacity < .99:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

func _sediment() -> void:
    var ground := MeshInstance3D.new()
    ground.name = "Fondo_sabbioso_roccioso"
    var plane := PlaneMesh.new()
    plane.size = Vector2(120,120)
    plane.subdivide_width = 72
    plane.subdivide_depth = 72
    ground.mesh = plane
    var shader_mat := ShaderMaterial.new()
    shader_mat.shader = SEABED
    ground.material_override = shader_mat
    ground.position.y = -.265
    ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ground)

func _stone(at: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
    # Mesh low-poly nativa: facce coerenti e leggibili nella vista dall'alto,
    # anche sul renderer Android Compatibility.
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 8
    mesh.rings = 4
    var rock := MeshInstance3D.new()
    rock.mesh = mesh
    rock.position = at+Vector3(0,radius*.34,0)
    rock.scale = Vector3(radius*rng.randf_range(.79,1.12),
        radius*rng.randf_range(.48,.79),radius*rng.randf_range(.83,1.15))
    rock.rotation.y = rng.randf()*TAU
    rock.material_override = mineral_mats[rng.randi_range(0,mineral_mats.size()-1)]
    rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(rock)

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

func _volcano(at: Vector3, radius: float, height: float, rng: RandomNumberGenerator) -> void:
    # Frustoconical volcanic cone with reliable outward-facing normals and
    # faceted top-down 3D silhouette, unlike hand-wound surface strips.
    var cone := CylinderMesh.new()
    cone.top_radius = radius*.315
    cone.bottom_radius = radius
    cone.height = height
    cone.radial_segments = 14
    cone.rings = 3
    var volcano := MeshInstance3D.new()
    volcano.name = "Camino_vulcanico_minerale"
    volcano.add_to_group("primordial_volcano")
    volcano.mesh = cone
    volcano.position = at+Vector3(0,height*.50,0)
    volcano.material_override = mineral_mats[3]
    volcano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(volcano)
    var crater := CylinderMesh.new()
    crater.top_radius = radius*.285
    crater.bottom_radius = radius*.285
    crater.height = .036
    crater.radial_segments = 24
    var glow := MeshInstance3D.new()
    glow.name = "Crater_calorico"
    glow.mesh = crater
    glow.material_override = molten
    glow.position = at+Vector3(0,height-.075,0)
    glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(glow)
    for i in range(9):
        var a: float = TAU*float(i)/9.0
        _stone(at+Vector3(cos(a)*radius*.86,0,sin(a)*radius*.86),
            rng.randf_range(.29,.58),rng)
    # Poche linee di materiali incandescenti sul cono: leggibili in alto,
    # non una superficie di lava continua o una foresta di vulcani.
    for i in range(3):
        var a: float = TAU*(float(i)+.19)/3.0
        _strip([
            at+Vector3(cos(a)*radius*.35,height-.08,sin(a)*radius*.35),
            at+Vector3(cos(a+.08)*radius*.61,height*.55,sin(a+.08)*radius*.61),
            at+Vector3(cos(a-.06)*radius*.92,.13,sin(a-.06)*radius*.92)
        ],.088,molten)
    var light := OmniLight3D.new()
    light.name = "Termico_luce_arancio"
    light.add_to_group("thermal_source")
    light.light_color = Color(1.0,.40,.13)
    light.light_energy = .92
    light.omni_range = radius*2.25
    light.shadow_enabled = false
    light.position = at+Vector3(0,height*.85,0)
    add_child(light)

func _fissure(path: Array[Vector3], rng: RandomNumberGenerator) -> void:
    # La spaccatura rimane neutra in gioco: fessura molto scura con due
    # bordi azzurro-verdi, gas visibile che non riscalda la cellula.
    _strip(path,.37,dark_crack)
    _edge_strip(path,.21,crack_rim,1.0)
    _edge_strip(path,.21,crack_rim,-1.0)
    for i in range(3):
        var start: Vector3 = path[i]
        _stone(start+Vector3(rng.randf_range(-.6,.6),0,rng.randf_range(-.6,.6)),
            rng.randf_range(.19,.40),rng)

func _strip(path: Array[Vector3], width: float, material: Material) -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(path.size()-1):
        var a: Vector3 = path[i]
        var b: Vector3 = path[i+1]
        var side: Vector3 = Vector3(-(b.z-a.z),0,b.x-a.x).normalized()
        _triangle(surface,a-side*width*.5,a+side*width*.5,b+side*width*.5)
        _triangle(surface,a-side*width*.5,b+side*width*.5,b-side*width*.5)
    surface.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.mesh = surface.commit()
    if material == dark_crack:
        mesh.add_to_group("harmless_gas_fissure")
    mesh.material_override = material
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(mesh)

func _edge_strip(path: Array[Vector3], offset: float, material: Material, side_sign: float) -> void:
    var shifted: Array[Vector3] = []
    for i in range(path.size()):
        var prev: Vector3 = path[maxi(0,i-1)]
        var nxt: Vector3 = path[mini(path.size()-1,i+1)]
        var tangent: Vector3 = nxt-prev
        var side: Vector3 = Vector3(-tangent.z,0,tangent.x).normalized()
        shifted.append(path[i]+side*offset*side_sign+Vector3(0,.009,0))
    _strip(shifted,.028,material)

func _register_bubbles(at: Vector3, count: int, height: float,
        speed: float, hazard_kind: int) -> void:
    for i in range(count):
        var f: float = float(i)/float(count)
        bubble_sources.append({
            "origin":at, "height":height, "speed":speed,
            "phase":f,"seed":float(i*17%19)*.51,
            "radius":(.048+.030*float(i%4))*(1.07 if hazard_kind == 1 else .92),
            "hazard":hazard_kind
        })

func _build_bubbles() -> void:
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 8
    sphere.rings = 5
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = sphere
    multimesh.instance_count = bubble_sources.size()
    bubbles = MultiMeshInstance3D.new()
    bubbles.name = "Bolle_che_risalgo"
    bubbles.multimesh = multimesh
    bubble_positions.resize(bubble_sources.size())
    bubbles.material_override = bubble_mat
    bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(bubbles)
    _animate_bubbles()

func _process(delta: float) -> void:
    bubble_time += minf(delta,.08)
    _animate_bubbles()

func _animate_bubbles() -> void:
    if not is_instance_valid(bubbles):
        return
    var mesh: MultiMesh = bubbles.multimesh
    for i in range(bubble_sources.size()):
        var b: Dictionary = bubble_sources[i]
        var rise: float = fposmod(float(b["phase"])+bubble_time*float(b["speed"])/float(b["height"]),1.0)
        var h: float = rise*float(b["height"])
        var seed: float = float(b["seed"])
        var sway: float = .14+rise*.21
        var pos: Vector3 = b["origin"]+Vector3(
            sin(seed+bubble_time*.48+rise*6.0)*sway,h,
            cos(seed*1.72+bubble_time*.37+rise*5.0)*sway)
        var radius: float = float(b["radius"])*(1.0+.20*sin(bubble_time*.6+seed))
        bubble_positions[i] = pos
        var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*radius),pos)
        mesh.set_instance_transform(i,transform)

func _dust(rng: RandomNumberGenerator) -> void:
    var grain := SphereMesh.new()
    grain.radius = .009
    grain.height = .018
    grain.radial_segments = 5
    grain.rings = 3
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = grain
    mm.instance_count = 130
    for i in range(130):
        var pos := Vector3(rng.randf_range(-30,30),rng.randf_range(.1,3.6),
            rng.randf_range(-30,30))
        mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))
    dust_root = MultiMeshInstance3D.new()
    dust_root.multimesh = mm
    dust_root.material_override = _mat(Color(.35,.68,.73,.55),.0,.55)
    dust_root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(dust_root)
