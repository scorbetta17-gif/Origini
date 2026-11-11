extends Node3D
class_name CellVisual
## Fenotipo 3D deterministico: il materiale genetico e le strutture provengono dai tratti.
## La protocellula iniziale possiede solo una membrana, un filamento di RNA e poche molecole.

var traits: Dictionary = {}
var branch: String = "pre_luca"
var is_player: bool = false
var age: float = 0.0
var growth: float = .55
var filament_roots: Array = []
var selection_ring: MeshInstance3D
var membrane: MeshInstance3D
var material_cache: Dictionary = {}

func setup(value: Dictionary, cell_branch: String, selected: bool = false) -> void:
    traits = value.duplicate(true)
    branch = cell_branch
    is_player = selected
    for item in get_children():
        remove_child(item)
        item.queue_free()
    filament_roots.clear()
    age = 0.0
    _build()

func set_growth(value: float) -> void:
    growth = clampf(value,.52,1.04)

func set_selected(value: bool) -> void:
    is_player = value
    if is_instance_valid(selection_ring):
        selection_ring.visible = value

func _material(tint: Color, alpha: float = 1.0, emissive: float = 0.0, gloss: float = .3) -> StandardMaterial3D:
    var cache_key: String = "%s/%.2f/%.2f/%.2f" % [tint.to_html(),alpha,emissive,gloss]
    if material_cache.has(cache_key):
        return material_cache[cache_key]
    var m := StandardMaterial3D.new()
    tint.a = alpha
    m.albedo_color = tint
    m.roughness = gloss
    m.metallic = .02
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    if alpha < .99:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    if emissive > 0:
        m.emission_enabled = true
        m.emission = tint
        m.emission_energy_multiplier = emissive
    material_cache[cache_key] = m
    return m

func _ball(host: Node3D, pos: Vector3, dimensions: Vector3, tint: Color, alpha: float = 1.0, emissive: float = 0.0) -> MeshInstance3D:
    var surface := SphereMesh.new()
    surface.radius = 1.0
    surface.height = 2.0
    surface.radial_segments = 22
    surface.rings = 12
    var part := MeshInstance3D.new()
    part.mesh = surface
    part.position = pos
    part.scale = dimensions
    part.material_override = _material(tint,alpha,emissive)
    host.add_child(part)
    return part

func _segment(host: Node3D, start: Vector3, end: Vector3, thickness: float, tint: Color, glow: float = 0.0) -> void:
    var axis: Vector3 = end-start
    if axis.length() <= .0001:
        return
    var geometry := CylinderMesh.new()
    geometry.top_radius = thickness
    geometry.bottom_radius = thickness
    geometry.height = axis.length()
    geometry.radial_segments = 6
    var part := MeshInstance3D.new()
    part.mesh = geometry
    part.position = (start+end)*.5
    part.quaternion = Quaternion(Vector3.UP,axis.normalized())
    part.material_override = _material(tint,1.0,glow,.45)
    host.add_child(part)

func _base_tint() -> Color:
    var tint := Color(.35,.72,.78)
    if branch == "luca":
        tint = Color(.54,.55,.82)
    elif branch == "archaea":
        tint = Color(.32,.75,.67)
    elif branch == "bacteria":
        tint = Color(.86,.54,.32)
    var signature: float = float(traits.get("signature",0.0))
    return tint.lerp(Color(.64,.47,.79),clampf(signature*.38,0,.38))

func _build() -> void:
    var is_pre: bool = branch == "pre_luca"
    var armored: float = float(traits.get("defense",1.0))
    var speed: float = float(traits.get("motility",1.0))
    var attack: float = float(traits.get("attack",1.0))
    var uptake: float = float(traits.get("uptake",1.0))
    var dna: bool = bool(traits.get("dna",false))
    var eps: bool = bool(traits.get("eps",false))
    var adhesion: bool = bool(traits.get("adhesion",false))
    var motor_count: int = int(traits.get("archaella",0)) if branch == "archaea" else int(traits.get("flagella",0)) if branch == "bacteria" else 0
    var tint: Color = _base_tint()
    var aspect: float = clampf(1.0+(speed-1.0)*.35,.88,1.38)
    var is_rod: bool = branch == "bacteria" or speed > 1.24
    var body_size := Vector3(.72*aspect,.58,.69/aspect)
    if is_pre:
        body_size *= .81
    if is_rod:
        body_size = Vector3(.91,.59,.63) * (1.0+clampf((speed-1.0)*.12,-.04,.20))
    var body_shape: Mesh
    if is_rod:
        var capsule := CapsuleMesh.new()
        capsule.radius = .65
        capsule.height = 2.30
        capsule.radial_segments = 22
        capsule.rings = 9
        body_shape = capsule
    else:
        var sphere := SphereMesh.new()
        sphere.radius = 1.0
        sphere.height = 2.0
        sphere.radial_segments = 26
        sphere.rings = 14
        body_shape = sphere
    # Protoplasma lievemente opaco con una vera membrana traslucida sovrapposta.
    var core := MeshInstance3D.new()
    core.mesh = body_shape
    core.position = Vector3(0,.74,0)
    core.scale = body_size * .95
    core.material_override = _material(tint.darkened(.46),.76,.06,.60)
    add_child(core)
    if is_rod:
        core.rotation.z = PI*.5
    membrane = MeshInstance3D.new()
    membrane.mesh = body_shape
    membrane.position = core.position
    membrane.scale = body_size * (1.035+clampf((armored-1.0)*.075,0,.20))
    membrane.material_override = _material(tint.lightened(.24),.29,.12,.18)
    add_child(membrane)
    if is_rod:
        membrane.rotation.z = PI*.5
    # Differenze di involucro batterico (monoderma/diderma) non imposte agli Archaea.
    var envelope: String = str(traits.get("envelope","none"))
    if branch == "bacteria":
        var wall := MeshInstance3D.new()
        wall.mesh = body_shape
        wall.position = Vector3(0,.74,0)
        wall.scale = body_size * 1.09
        wall.material_override = _material(Color(.95,.70,.38),.20 if envelope != "diderm" else .13,.05)
        add_child(wall)
        if is_rod:
            wall.rotation.z = PI*.5
        if envelope == "diderm":
            var exterior := MeshInstance3D.new()
            exterior.mesh = body_shape
            exterior.position = Vector3(0,.74,0)
            exterior.scale = body_size*1.17
            exterior.material_override = _material(Color(.51,.84,.69),.12,.06)
            add_child(exterior)
            if is_rod:
                exterior.rotation.z = PI*.5
    if eps:
        _ball(self,Vector3(0,.74,0),body_size*1.26,Color(.48,.91,.79),.09,.12)
    # Solo 2 granuli nella protocellula pre-LUCA; non sono organelli.
    var granules: int = 2 if is_pre else 7
    for i in range(granules):
        var angle: float = float(i)*2.399
        var r: float = .12+float(i%3)*.075
        _ball(self,Vector3(cos(angle)*r,.72+sin(angle*1.8)*.12,sin(angle)*r),Vector3.ONE*(.036 if is_pre else .048),Color(1.0,.69,.33),1.0,.1)
    # RNA monofilamento iniziale, solo in seguito doppia elica DNA.
    var strands: int = 2 if dna else 1
    for helix in range(strands):
        var last := Vector3.ZERO
        for index in range(18):
            var u: float = float(index)/17.0
            var x: float = (u-.5)*(.62 if is_pre else .90)
            var a: float = u*TAU*1.65+float(helix)*PI
            var point := Vector3(x,.74+sin(a)*.095,cos(a)*.12)
            if index > 0:
                _segment(self,last,point,.013,Color(.96,.53,.77) if not dna else Color(.60,.78,1.0),.20)
            last = point
    if dna:
        for index in range(12):
            var u: float = float(index)/11.0
            var x: float = (u-.5)*.9
            var a: float = u*TAU*1.65
            _segment(self,Vector3(x,.74+sin(a)*.095,cos(a)*.12),Vector3(x,.74-sin(a)*.095,-cos(a)*.12),.009,Color(.86,.90,.70))
    # Recettori, proteasi e adesine sono visibili soltanto se associati ai tratti.
    var pores: int = clampi(int(maxf(0.0,uptake-1.0)*13.0),0,12)
    for i in range(pores):
        var a: float = TAU*float(i)/float(maxi(1,pores))
        _ball(self,Vector3(cos(a)*body_size.x*.95,.74+sin(a*3.0)*.09,sin(a)*body_size.z*.93),Vector3.ONE*.045,Color(.65,1.0,.87),1.0,.24)
    var enzyme_nodes: int = clampi(int(maxf(0.0,attack-1.0)*11.0),0,11)
    for i in range(enzyme_nodes):
        var a: float = TAU*float(i)/float(maxi(1,enzyme_nodes))
        var start := Vector3(cos(a)*body_size.x,.74,sin(a)*body_size.z)
        _segment(self,start,start+Vector3(cos(a)*.15,.04,sin(a)*.14),.026,Color(1.0,.57,.44),.10)
    if adhesion:
        for i in range(5):
            var a: float = TAU*float(i)/5.0
            var start := Vector3(cos(a)*body_size.x*.87,.80,sin(a)*body_size.z*.87)
            var end := start+Vector3(cos(a)*.20,.07,sin(a)*.19)
            _segment(self,start,end,.020,Color(.77,.86,.78),.06)
    # Ereditarieta' grafica: firme superficiali delle mutazioni, non organelli fittizi.
    var history: Array = traits.get("mutations",[])
    for index in range(mini(14,history.size())):
        var name: String = str(history[index])
        var code: int = absi(name.hash())
        var a: float = float(code%359)*PI/180.0
        var point := Vector3(cos(a)*body_size.x*.97,.72+sin(float(code%53))*.15,sin(a)*body_size.z*.97)
        _ball(self,point,Vector3.ONE*(.027+float(code%4)*.006),Color(.57,.81,.90),1.0,.17)
    # Motori: nel protagonista iniziale assenti. Archaella e flagelli batterici distinti.
    for i in range(mini(7,motor_count)):
        var root := Node3D.new()
        add_child(root)
        root.position = Vector3(-body_size.x*.93,.74,float(i-(motor_count/2))*.12)
        filament_roots.append(root)
        var prev := Vector3.ZERO
        for j in range(1,8):
            var point := Vector3(-float(j)*.19,sin(float(j)*.53+float(i))*.08,cos(float(j)*.63+float(i))*.07)
            _segment(root,prev,point,.013,Color(.59,.91,.93) if branch == "archaea" else Color(.96,.84,.62),.18)
            prev = point
    # Indicatore 3D di controllo; non modifica il fenotipo.
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = .96
    ring_mesh.outer_radius = 1.01
    ring_mesh.rings = 8
    ring_mesh.ring_segments = 48
    selection_ring = MeshInstance3D.new()
    selection_ring.mesh = ring_mesh
    selection_ring.position = Vector3(0,.06,0)
    selection_ring.material_override = _material(Color(.42,1.0,.80),1.0,.65)
    selection_ring.visible = is_player
    add_child(selection_ring)

func _process(delta: float) -> void:
    age += delta
    var breath: float = 1.0+sin(age*2.1)*.013
    scale = Vector3(growth,growth*breath,growth)
    for i in range(filament_roots.size()):
        var root: Node3D = filament_roots[i]
        root.rotation.y = sin(age*3.8+float(i))*.21
        root.rotation.z = cos(age*2.9+float(i))*.11
    if is_instance_valid(selection_ring) and is_player:
        selection_ring.rotation.y += delta*.22
