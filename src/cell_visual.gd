extends Node3D
class_name CellVisual
## ORIGINI: renderer biologico parametrico, senza asset fittizi precostituiti.
## All'inizio: una membrana, un filamento di ssRNA, pochi complessi autocatalitici.
const MEMBRANE_SHADER = preload("res://shaders/cell_membrane.gdshader")
const SHADOW_SHADER = preload("res://shaders/cell_contact_shadow.gdshader")
const BLENDER_CORE: String = "res://assets/models/primordial_core.glb"
const BLENDER_MODULES: Dictionary = {
    "pili": "res://assets/models/pili_module.glb",
    "receptor": "res://assets/models/receptor_module.glb",
    "protease": "res://assets/models/protease_module.glb",
    "transporter": "res://assets/models/transporter_module.glb",
    "vesicle": "res://assets/models/vesicle_module.glb"
}
var traits: Dictionary = {}
var branch: String = "pre_luca"
var is_player: bool = false
var age: float = 0.0
var growth: float = .72
var filament_roots: Array = []
var selection_ring: MeshInstance3D
var membrane: MeshInstance3D
var interior: Node3D
var material_cache: Dictionary = {}
var body_radii: Vector3 = Vector3(.79,.72,.79)
var blender_interior: bool = false
var use_blender_assets: bool = false

func setup(value: Dictionary, cell_branch: String, selected: bool = false) -> void:
    traits = value.duplicate(true)
    branch = cell_branch
    is_player = selected
    for child in get_children():
        remove_child(child)
        child.queue_free()
    filament_roots.clear()
    material_cache.clear()
    age = 0.0
    blender_interior = false
    use_blender_assets = false
    _build()

func set_growth(value: float) -> void:
    growth = clampf(value,.58,1.24)

func set_selected(value: bool) -> void:
    is_player = value
    if is_instance_valid(selection_ring):
        selection_ring.visible = value

func _mat(tint: Color, alpha: float = 1.0, rough: float = .71) -> StandardMaterial3D:
    var key: String = tint.to_html()+"_"+str(snappedf(alpha,.01))+"_"+str(rough)
    if material_cache.has(key):
        return material_cache[key]
    var m := StandardMaterial3D.new()
    tint.a = alpha
    m.albedo_color = tint
    m.roughness = rough
    m.metallic = 0.0
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    if alpha < .99:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    material_cache[key] = m
    return m

func _ellipsoid(host: Node3D, point: Vector3, radii: Vector3, tint: Color, alpha: float = 1.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 16
    mesh.rings = 10
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = point
    node.scale = radii
    node.material_override = _mat(tint,alpha)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    host.add_child(node)
    return node

func _tube(host: Node3D, coords: PackedVector3Array, radius: float, tint: Color, opacity: float = 1.0) -> void:
    if coords.size() < 2:
        return
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(coords.size()-1):
        var p: Vector3 = coords[i]
        var q: Vector3 = coords[i+1]
        var along: Vector3 = (q-p).normalized()
        if along.length_squared() < .0001:
            continue
        var guide: Vector3 = Vector3.UP if absf(along.dot(Vector3.UP)) < .9 else Vector3.RIGHT
        var a: Vector3 = along.cross(guide).normalized()*radius
        var b: Vector3 = along.cross(a).normalized()*radius
        for j in range(7):
            var phi: float = TAU*float(j)/7.0
            var phi2: float = TAU*float(j+1)/7.0
            var v: Vector3 = a*cos(phi)+b*sin(phi)
            var w: Vector3 = a*cos(phi2)+b*sin(phi2)
            surface.add_vertex(p+v)
            surface.add_vertex(q+v)
            surface.add_vertex(p+w)
            surface.add_vertex(q+v)
            surface.add_vertex(q+w)
            surface.add_vertex(p+w)
    surface.generate_normals()
    var node := MeshInstance3D.new()
    node.mesh = surface.commit()
    node.material_override = _mat(tint,opacity,.48)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    host.add_child(node)

func _color() -> Color:
    if branch == "bacteria":
        return Color(.49,.65,.55)
    if branch == "archaea":
        return Color(.47,.65,.61)
    if branch == "luca":
        return Color(.59,.70,.73)
    return Color(.42,.63,.59)

func _try_blender_core(primitive: bool, tint: Color, thermal: float) -> bool:
    if not ResourceLoader.exists(BLENDER_CORE):
        return false
    var packed: PackedScene = ResourceLoader.load(BLENDER_CORE) as PackedScene
    if packed == null:
        return false
    var core: Node3D = packed.instantiate() as Node3D
    if core == null:
        return false
    core.name = "BlenderCellCore"
    core.position = Vector3(0,.81,0)
    core.scale = body_radii
    add_child(core)
    var shell: Node = core.find_child("Membrane_Outer",true,false)
    if not (shell is MeshInstance3D):
        remove_child(core)
        core.queue_free()
        return false
    membrane = shell as MeshInstance3D
    var shell_mat := ShaderMaterial.new()
    shell_mat.shader = MEMBRANE_SHADER
    shell_mat.set_shader_parameter("membrane_tint",tint.lerp(Color(.62,.69,.61),clampf(thermal*.06,0,.35)))
    shell_mat.set_shader_parameter("rim_tint",tint.lightened(.18))
    shell_mat.set_shader_parameter("opacity",.11 if primitive else .16)
    shell_mat.set_shader_parameter("membrane_motion",.009)
    shell_mat.set_shader_parameter("internal_scattering",.28 if primitive else .36)
    membrane.material_override = shell_mat
    membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    # GlTF source keeps geometric form; Godot controls all gameplay optical values.
    # Overriding imported opaque materials ensures the RNA remains legible.
    var cytosol_mesh: MeshInstance3D = core.find_child("Cytosol",true,false) as MeshInstance3D
    if cytosol_mesh != null:
        cytosol_mesh.material_override = _mat(tint.darkened(.26),.045,.95)
        cytosol_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var rna_mesh: MeshInstance3D = core.find_child("SingleStrand_RNA",true,false) as MeshInstance3D
    if rna_mesh != null:
        rna_mesh.material_override = _mat(Color(.82,.43,.31),1.0,.63)
    for index in range(1,4):
        var prefix: String = "Autocatalytic_%02d_" % index
        for sub in range(1,4):
            var enzyme_mesh: MeshInstance3D = core.find_child(prefix+("%02d" % sub),true,false) as MeshInstance3D
            if enzyme_mesh != null:
                enzyme_mesh.material_override = _mat(Color(.77,.65,.38) if sub == 1 else Color(.58,.65,.48),1.0,.76)
    interior = core.find_child("InteriorAssembly",true,false) as Node3D
    if interior == null:
        interior = Node3D.new()
        core.add_child(interior)
    blender_interior = true
    use_blender_assets = true
    return true

func _blender_module(id: String, at: Vector3, normal: Vector3, size: float = 1.0) -> bool:
    if not use_blender_assets or not BLENDER_MODULES.has(id):
        return false
    var path: String = str(BLENDER_MODULES[id])
    if not ResourceLoader.exists(path):
        return false
    var packed: PackedScene = ResourceLoader.load(path) as PackedScene
    if packed == null:
        return false
    var piece: Node3D = packed.instantiate() as Node3D
    if piece == null:
        return false
    piece.name = "GeneModule_" + id
    piece.position = at
    piece.quaternion = Quaternion(Vector3.UP,normal.normalized())
    piece.scale = Vector3.ONE * size
    add_child(piece)
    return true

func _build() -> void:
    var primitive: bool = branch == "pre_luca"
    # Solo un locus morfogenetico MAGGIORE modifica la forma.
    var shape: float = clampf(float(traits.get("elongation",0.0))*.48,0.0,.40)
    var elongated: bool = shape > .24
    body_radii = Vector3(.77+shape,.69,.77-shape*.24)
    if primitive:
        body_radii *= .90
    if elongated:
        body_radii.x += .16
        body_radii.z -= .085
    var tint: Color = _color()
    var globe := SphereMesh.new()
    globe.radius = 1.0
    globe.height = 2.0
    globe.radial_segments = 48
    globe.rings = 28

    var thermal: float = float(traits.get("thermotolerance",0.0))
    var imported_blender_core: bool = _try_blender_core(primitive,tint,thermal)
    if not imported_blender_core:
        # Un solo involucro traslucido organico, senza vetro/specchi o sfera opaca.
        membrane = MeshInstance3D.new()
        membrane.mesh = globe
        membrane.position = Vector3(0,.81,0)
        membrane.scale = body_radii
        var shell_mat := ShaderMaterial.new()
        shell_mat.shader = MEMBRANE_SHADER
        # Membrane genes already resolved in outer thermal variable.
        shell_mat.set_shader_parameter("membrane_tint",tint.lerp(Color(.62,.69,.61),clampf(thermal*.06,0,.35)))
        shell_mat.set_shader_parameter("rim_tint",tint.lightened(.18))
        shell_mat.set_shader_parameter("opacity",.21 if primitive else .26)
        shell_mat.set_shader_parameter("membrane_motion",.008)
        shell_mat.set_shader_parameter("internal_scattering",.46 if primitive else .54)
        membrane.material_override = shell_mat
        membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(membrane)

        # Volume del citoplasma: scattering molto lieve, non un organello.
        _ellipsoid(self,Vector3(0,.81,0),body_radii*.963,tint.darkened(.13),.055)
        # Contenuto citoplasmatico mobile, ma nessun organello moderno iniziale.
        interior = Node3D.new()
        interior.position = Vector3(0,.81,0)
        add_child(interior)
        var dna: bool = bool(traits.get("dna",false))
        var strand_count: int = 2 if dna else 1
        for strand in range(strand_count):
            var poly := PackedVector3Array()
            for i in range(61):
                var t: float = float(i)/60.0
                var p: Vector3
                if dna:
                    # DNA solo dopo il locus di stabilizzazione: due filamenti distinti.
                    var u: float = (t-.5)*1.13
                    var phase: float = t*TAU*1.9+float(strand)*PI
                    p = Vector3(u,sin(phase)*.17,cos(phase)*.17)
                else:
                    # Un unico ssRNA ripiegato in 3D: curve non complanari.
                    p = Vector3(
                        (t-.5)*.72 + sin(t*TAU*3.1)*.14,
                        sin(t*TAU*1.85)*.16 + cos(t*TAU*3.4)*.075,
                        cos(t*TAU*1.43)*.22 + sin(t*TAU*2.5)*.065
                    )
                poly.append(p)
            _tube(interior,poly,.018 if primitive else .020,Color(.92,.60,.47) if not dna else Color(.76,.72,.59))
        if dna:
            # Segmenti aggiuntivi sono visibili solo dopo la stabilizzazione del DNA.
            for i in range(9):
                var u: float = float(i)/8.0
                var x: float = (u-.5)*1.12
                var phase: float = u*TAU*1.3
                _tube(interior,PackedVector3Array([
                    Vector3(x,sin(phase)*.18,cos(phase)*.18),
                    Vector3(x,-sin(phase)*.18,-cos(phase)*.18)
                ]),.008,Color(.63,.78,.73))
        var complexes: int = 3 if primitive else 5
        for i in range(complexes):
            var phi: float = float(i)*TAU/float(complexes)+.5
            var center := Vector3(cos(phi)*.28, sin(phi*2.0)*.22, sin(phi)*.30)
            var protein_color := Color(.80,.76,.59) if primitive else Color(.73,.76,.66)
            _ellipsoid(interior,center,Vector3(.075,.047,.06),protein_color)
            _ellipsoid(interior,center+Vector3(.044,.026,-.03),Vector3(.042,.033,.039),protein_color.darkened(.11))
            _ellipsoid(interior,center+Vector3(-.035,-.021,.034),Vector3(.035,.03,.042),protein_color.lightened(.12))

    # Trasportatori: pori incastonati nella membrana; solo locus maggiore.
    var transporters: int = clampi(int(traits.get("transporters",0)),0,9)
    for i in range(transporters):
        var phi: float = TAU*(float(i)+.43)/float(maxi(1,transporters))
        var n := Vector3(cos(phi),.24*sin(phi*1.75),sin(phi)).normalized()
        var pos := Vector3(n.x*body_radii.x,.81+n.y*body_radii.y,n.z*body_radii.z)
        if not _blender_module("transporter",pos,n,.85):
            _ellipsoid(self,pos,Vector3(.048,.038,.048),Color(.40,.59,.60),.90)
            _ellipsoid(self,pos+n*.026,Vector3(.024,.018,.024),Color(.20,.35,.37),.86)
    # Moduli di adesione, riconoscimento e lisi emergono per mutazione.
    var receptors: int = clampi(int(traits.get("receptors",0)),0,8)
    for i in range(receptors):
        var a: float = TAU*(float(i)+.3)/float(maxi(1,receptors))
        var n: Vector3 = Vector3(cos(a),.22*sin(a*1.8),sin(a)).normalized()
        var anchor: Vector3 = Vector3(n.x*body_radii.x,n.y*body_radii.y,n.z*body_radii.z)+Vector3(0,.81,0)
        if not _blender_module("receptor",anchor,n,1.0):
            _tube(self,PackedVector3Array([anchor,anchor+n*.11]),.018,Color(.74,.84,.72))
            _ellipsoid(self,anchor+n*.12,Vector3.ONE*.04,Color(.82,.85,.74))
    var pili: int = clampi(int(traits.get("pili",0)),0,9)
    for i in range(pili):
        var a: float = TAU*float(i)/float(maxi(1,pili))
        var n: Vector3 = Vector3(cos(a),.15,sin(a)).normalized()
        var anchor := Vector3(n.x*body_radii.x,.81+n.y*body_radii.y,n.z*body_radii.z)
        if not _blender_module("pili",anchor,n,1.0):
            var path := PackedVector3Array()
            for j in range(7):
                var distance: float = float(j)*.15
                path.append(anchor+n*distance+Vector3(0,sin(float(j)*.82+float(i))*.027,0))
            _tube(self,path,.012,Color(.72,.79,.66))
    var proteases: int = clampi(int(traits.get("protease",0)),0,6)
    for i in range(proteases):
        var a: float = TAU*(float(i)+.5)/float(maxi(1,proteases))
        var n := Vector3(cos(a),0,sin(a))
        var loc := Vector3(n.x*body_radii.x,.81,n.z*body_radii.z)
        if not _blender_module("protease",loc,n,1.0):
            _ellipsoid(self,loc,Vector3(.045,.025,.043),Color(.80,.64,.52))
            _ellipsoid(self,loc+n*.11,Vector3.ONE*.02,Color(.85,.68,.52),.65)
    var vesicles: int = clampi(int(traits.get("vesicles",0)),0,5)
    for i in range(vesicles):
        var a: float = TAU*(float(i)+.2)/float(maxi(1,vesicles))
        var point := Vector3(cos(a)*body_radii.x*1.23,.81+sin(a*2.0)*.12,sin(a)*body_radii.z*1.23)
        if not _blender_module("vesicle",point,Vector3.UP,1.0):
            _ellipsoid(self,point,Vector3.ONE*.065,tint.lightened(.15),.27)
    if bool(traits.get("adhesion",false)):
        for i in range(4):
            var a: float = TAU*float(i)/4.0
            var n := Vector3(cos(a),.09,sin(a)).normalized()
            var anchor := Vector3(n.x*body_radii.x,.81+n.y*body_radii.y,n.z*body_radii.z)
            _tube(self,PackedVector3Array([anchor,anchor+n*.13,anchor+n*.20]),.017,Color(.69,.81,.74))
    if bool(traits.get("eps",false)):
        _ellipsoid(self,Vector3(0,.81,0),body_radii*1.13,Color(.54,.69,.67),.075)
    # Involucri diversi compaiono solo con loci codificati.
    var envelope: String = str(traits.get("envelope","none"))
    if envelope == "monoderm":
        _ellipsoid(self,Vector3(0,.81,0),body_radii*1.025,Color(.62,.73,.65),.14)
    elif envelope == "diderm":
        _ellipsoid(self,Vector3(0,.81,0),body_radii*1.026,Color(.65,.75,.66),.13)
        _ellipsoid(self,Vector3(0,.81,0),body_radii*1.085,Color(.53,.71,.70),.14)
    elif envelope == "archaeal":
        _ellipsoid(self,Vector3(0,.81,0),body_radii*1.026,Color(.58,.74,.68),.11)
    if thermal > .01:
        for i in range(mini(5,ceili(thermal))):
            var a: float = TAU*float(i)/float(maxi(1,mini(5,ceili(thermal))))
            _ellipsoid(interior,Vector3(cos(a)*.30,-.22,sin(a)*.30),Vector3(.055,.033,.045),Color(.81,.78,.62))
    var motors: int = int(traits.get("archaella",0)) if branch == "archaea" else int(traits.get("flagella",0)) if branch == "bacteria" else 0
    for i in range(mini(4,motors)):
        var root := Node3D.new()
        root.position = Vector3(-body_radii.x,.81,float(i)*.12-.12)
        add_child(root)
        filament_roots.append(root)
        var path := PackedVector3Array()
        for j in range(23):
            var u: float = float(j)/22.0
            path.append(Vector3(-u*2.0,sin(u*TAU*3.0+float(i))*.095,cos(u*TAU*3.0+float(i))*.085))
        _tube(root,path,.015,Color(.71,.84,.74) if branch == "archaea" else Color(.85,.78,.62))

    # Ombra di contatto morbida: il fondo resta lontano dalla cellula,
    # ma l'osservatore percepisce l'altezza del corpo sopra il sedimento.
    var shadow_plane := PlaneMesh.new()
    shadow_plane.size = Vector2(2.35,2.35)
    var shadow := MeshInstance3D.new()
    shadow.mesh = shadow_plane
    shadow.position = Vector3(0,-.242,0)
    var shadow_mat := ShaderMaterial.new()
    shadow_mat.shader = SHADOW_SHADER
    shadow_mat.set_shader_parameter("strength",.31)
    shadow.material_override = shadow_mat
    shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shadow)

    var ring := TorusMesh.new()
    ring.inner_radius = .80
    ring.outer_radius = .812
    ring.rings = 56
    ring.ring_segments = 8
    selection_ring = MeshInstance3D.new()
    selection_ring.mesh = ring
    selection_ring.position.y = -.08
    selection_ring.material_override = _mat(Color(.41,.62,.61),.09)
    selection_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    selection_ring.visible = is_player
    add_child(selection_ring)

func _process(delta: float) -> void:
    age += delta
    var pulse: float = 1.0+sin(age*1.36)*.009
    scale = Vector3(growth*pulse,growth,growth*pulse)
    if is_instance_valid(interior):
        interior.rotation.y = sin(age*.32)*.09
        interior.position.y = sin(age*.83)*.015 if blender_interior else .81+sin(age*.83)*.015
    for i in range(filament_roots.size()):
        var root: Node3D = filament_roots[i]
        root.rotation.y = sin(age*2.1+float(i))*.17
        root.rotation.z = cos(age*1.7+float(i))*.08
