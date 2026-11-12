extends Node3D
## Fondale primordiale isometrico - roccia, sedimento, sorgenti termiche,
## fessure MINERALI con bolle innocue. Niente vegetazione o organismi superiori.
## Sono mesh Godot e particelle 3D reali: la camera puo spostarsi liberamente.
const VolcanoVisual = preload("res://src/volcano_visual.gd")
const Terrain = preload("res://src/seabed_terrain.gd")
var terrain: Node3D
const VENTS: Array[Vector3] = [Vector3(-11.0,-.22,3.0),Vector3(16.0,-.22,-14.0)]
const FISSURES: Array[Vector3] = [
    Vector3(-4.9,-.21,-3.7),Vector3(4.6,-.21,5.0),
    Vector3(-7.4,-.21,10.2),Vector3(9.0,-.21,-3.4)
]
var bubble_mat: StandardMaterial3D
var dark_crack: StandardMaterial3D
var dust_root: MultiMeshInstance3D
var bubbles: MultiMeshInstance3D
var bubble_sources: Array[Dictionary] = []
# CPU world state is readable even when headless Godot disables GPU readback.
var bubble_positions: Array[Vector3] = []
var bubble_time: float = 0.0

func setup(_gameplay_rng: RandomNumberGenerator) -> void:
    # Reproducible environment: art changes must not consume the gameplay RNG
    # or change terrain appearance on loading a saved lineage.
    var rng := RandomNumberGenerator.new()
    rng.seed = 76076
    dark_crack = _mat(Color(.018,.084,.12))
    bubble_mat = _mat(Color(.56,.88,.98,.59),.38,.59)
    bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bubble_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _sediment()
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
        _register_bubbles(Vector3(fissure.x,terrain.surface_height(Vector2(fissure.x,fissure.z))+.12,fissure.z),11,3.5,.39,0)
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
    terrain = Terrain.new()
    terrain.name = "Fondo_sabbioso_roccioso"
    add_child(terrain)
    terrain.setup()

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

func _volcano(at: Vector3, radius: float, height: float, _rng: RandomNumberGenerator) -> void:
    var volcano := VolcanoVisual.new()
    volcano.name = "Camino_vulcanico_minerale"
    volcano.add_to_group("primordial_volcano")
    volcano.position = at
    add_child(volcano)
    volcano.setup(radius,height,76077 if radius > 2.5 else 76078)
    # Keep lights and hazard groups at ocean-root level for existing callers.
    var light := OmniLight3D.new()
    light.name = "Termico_luce_arancio"
    light.add_to_group("thermal_source")
    light.light_color = Color(1.0,.35,.08)
    light.light_energy = 1.15
    light.omni_range = radius*1.75
    light.shadow_enabled = false
    light.position = at+Vector3(0,height*.79,0)
    add_child(light)

func _fissure(path: Array[Vector3], _rng: RandomNumberGenerator) -> void:
    # The canyon is already carved into terrain; this seam marks its bottom.
    # Subdivide to follow relief, avoiding floating green ribbons.
    var bed: Array[Vector3] = []
    for i in range(path.size()-1):
        var steps: int = maxi(2,ceili(path[i].distance_to(path[i+1])/.18))
        for j in range(steps):
            var p: Vector3 = path[i].lerp(path[i+1],float(j)/steps)
            p.y = terrain.surface_height(Vector2(p.x,p.z))+.035
            bed.append(p)
    var end: Vector3 = path[-1]
    end.y = terrain.surface_height(Vector2(end.x,end.z))+.035
    bed.append(end)
    _strip(bed,.055,dark_crack)


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
