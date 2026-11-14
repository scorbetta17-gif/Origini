extends Node3D
class_name CellVisual
## ORIGINI: renderer biologico parametrico, senza asset fittizi precostituiti.
## All'inizio: una membrana, un filamento di ssRNA, pochi complessi autocatalitici.
const Genome = preload("res://src/cell_genome.gd")
const RNA_COLOR := Color(1.0,.48,.12)
const DNA_COLOR := Color(.69,.35,.95)
const CATALYST_COLOR := Color(1.0,.68,.23)
const MEMBRANE_SHADER = preload("res://shaders/cell_membrane.gdshader")
const CONTENTS_SHADER = preload("res://shaders/cell_contents.gdshader")
const SHADOW_SHADER = preload("res://shaders/cell_contact_shadow.gdshader")
const BLENDER_CORE: String = "res://assets/models/primordial_core.glb"
const BLENDER_MODULES: Dictionary = {
    "pili": "res://assets/models/pili_module.glb",
    "receptor": "res://assets/models/receptor_module.glb",
    "protease": "res://assets/models/protease_module.glb",
    "transporter": "res://assets/models/transporter_module.glb",
    "vesicle": "res://assets/models/vesicle_module.glb"
}
var feature_nodes: Dictionary = {}
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
var division_progress: float = 0.0
var replication_source: Node3D
var replication_copy: Node3D
var replication_origin: Vector3 = Vector3.ZERO

func setup(value: Dictionary, cell_branch: String, selected: bool = false) -> void:
    traits = Genome.normalize(value,cell_branch)
    branch = cell_branch
    is_player = selected
    for child in get_children():
        remove_child(child)
        child.queue_free()
    filament_roots.clear()
    material_cache.clear()
    feature_nodes.clear()
    age = 0.0
    blender_interior = false
    use_blender_assets = false
    division_progress = 0.0
    replication_source = null
    replication_copy = null
    _build()
    var motion = preload("res://src/cell_fluid_motion.gd").new()
    motion.name = "FluidMotion"
    add_child(motion)
    motion.setup(self)

func set_growth(value: float) -> void:
    growth = clampf(value,.72,.864)

func set_division_progress(value: float) -> void:
    division_progress = clampf(value,0.0,1.0)
    if is_instance_valid(membrane) and membrane.material_override is ShaderMaterial:
        membrane.material_override.set_shader_parameter("division_progress",division_progress)
    if is_instance_valid(replication_source):
        var separation: float = smoothstep(.15,.95,division_progress)*.34
        replication_source.position = replication_origin+Vector3(-separation,0,0)
        if is_instance_valid(replication_copy):
            replication_copy.visible = division_progress > .12
            replication_copy.position = replication_origin+Vector3(separation,0,0)
            replication_copy.scale = replication_source.scale*lerpf(.35,1.0,smoothstep(.12,.65,division_progress))

func set_selected(value: bool) -> void:
    is_player = value
    if is_instance_valid(selection_ring):
        selection_ring.visible = value

func _mat(tint: Color, alpha: float = 1.0, rough: float = .71) -> Material:
    var key: String = tint.to_html()+"_"+str(snappedf(alpha,.01))+"_"+str(rough)
    if material_cache.has(key):
        return material_cache[key]
    if alpha>=.99:
        var pigment := ShaderMaterial.new()
        pigment.shader = CONTENTS_SHADER
        pigment.set_shader_parameter("pigment",tint)
        material_cache[key] = pigment
        return pigment
    var m := StandardMaterial3D.new()
    tint.a = alpha
    m.albedo_color = tint
    m.roughness = rough
    m.metallic = 0.0
    m.emission_enabled = true
    m.emission = Color(tint.r,tint.g,tint.b)*.32
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
    var frames: Array = []
    for i in range(coords.size()):
        var tangent: Vector3 = (coords[mini(i+1,coords.size()-1)]-coords[maxi(i-1,0)]).normalized()
        var guide: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP))<.9 else Vector3.RIGHT
        var axis: Vector3 = tangent.cross(guide).normalized()
        var second: Vector3 = tangent.cross(axis).normalized()
        var normals := PackedVector3Array()
        for j in range(10):
            var angle: float = TAU*float(j)/10.0
            normals.append(axis*cos(angle)+second*sin(angle))
        frames.append(normals)
    for i in range(coords.size()-1):
        for j in range(10):
            var k: int = (j+1)%10
            for sample in [[i,j],[i+1,j],[i,k],[i+1,j],[i+1,k],[i,k]]:
                var normal: Vector3 = frames[sample[0]][sample[1]]
                surface.set_normal(normal)
                surface.add_vertex(coords[sample[0]]+normal*radius)
    var node := MeshInstance3D.new()
    node.mesh = surface.commit()
    node.material_override = _mat(tint,opacity,.48)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    host.add_child(node)

func _color() -> Color:
    if branch == "bacteria":
        return Color(.38,.77,.64)
    if branch == "archaea":
        return Color(.43,.66,.91)
    if branch == "luca":
        return Color(.48,.65,.86)
    return Color(.34,.75,.85)

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
    # The shared imported interior remains, but the outline is a true ovoid.
    var smooth_shell := SphereMesh.new()
    smooth_shell.radius = 1.0
    smooth_shell.height = 2.0
    smooth_shell.radial_segments = 48
    smooth_shell.rings = 28
    membrane.mesh = smooth_shell
    membrane.transform = Transform3D.IDENTITY
    var shell_mat := ShaderMaterial.new()
    shell_mat.shader = MEMBRANE_SHADER
    shell_mat.set_shader_parameter("membrane_tint",tint.lerp(Color(.62,.69,.61),clampf(thermal*.06,0,.35)))
    shell_mat.set_shader_parameter("rim_tint",Color(.58,.98,.96))
    shell_mat.set_shader_parameter("opacity",.16 if primitive else .19)
    shell_mat.set_shader_parameter("membrane_motion",.009)
    shell_mat.set_shader_parameter("internal_scattering",.28 if primitive else .36)
    membrane.material_override = shell_mat
    membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    # Imported internal complexes remain; the shell uses the common ovoid profile.
    # Overriding imported opaque materials ensures the RNA remains legible.
    var cytosol_mesh: MeshInstance3D = core.find_child("Cytosol",true,false) as MeshInstance3D
    if cytosol_mesh != null:
        cytosol_mesh.hide()
        cytosol_mesh.material_override = _mat(tint.darkened(.26),.045,.95)
        cytosol_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var rna_mesh: MeshInstance3D = core.find_child("SingleStrand_RNA",true,false) as MeshInstance3D
    if rna_mesh != null:
        rna_mesh.material_override = _mat(RNA_COLOR,1.0,.63)
    for index in range(1,4):
        var prefix: String = "Autocatalytic_%02d_" % index
        for sub in range(1,4):
            var enzyme_mesh: MeshInstance3D = core.find_child(prefix+("%02d" % sub),true,false) as MeshInstance3D
            if enzyme_mesh != null:
                enzyme_mesh.material_override = _mat(CATALYST_COLOR if sub == 1 else CATALYST_COLOR.darkened(.12),1.0,.76)
    interior = core.find_child("InteriorAssembly",true,false) as Node3D
    if interior == null:
        interior = Node3D.new()
        core.add_child(interior)
    if rna_mesh != null:
        rna_mesh.name = "Legacy_RNA"
        rna_mesh.hide()
    _build_rna(interior)
    # Redistribute the three imported catalytic complexes around the polymer.
    var centers: Array[Vector3] = [Vector3(-.46,.18,-.41),Vector3(.46,.12,-.22),Vector3(.21,.12,.53)]
    for index in range(1,4):
        for sub in range(1,4):
            var enzyme: MeshInstance3D = core.find_child("Autocatalytic_%02d_%02d" % [index,sub],true,false) as MeshInstance3D
            if enzyme!=null:
                enzyme.position=centers[index-1]+Vector3((sub-2)*.08,(sub%2)*.025,(sub-2)*.035)
                enzyme.hide() # Replaced by folded catalytic RNA, not premature protein complexes.
    if bool(traits.get("dna",false)):
        interior.get_node("SingleStrand_RNA").hide()
        _build_imported_dna(interior)
    blender_interior = true
    use_blender_assets = true
    return true

func _build_rna(host: Node3D) -> void:
    var strand := Node3D.new()
    strand.name = "SingleStrand_RNA"
    host.add_child(strand)
    var points := PackedVector3Array()
    for i in range(97):
        var u: float = float(i)/96.0
        var phi: float = u*TAU*1.65
        var r: float = .12+.21*u
        points.append(Vector3(cos(phi)*r,.17+sin(phi*1.7)*.065,sin(phi)*r*.76))
    _tube(strand,points,.022,RNA_COLOR)

func _build_imported_dna(host: Node3D) -> void:
    var dna_root := Node3D.new()
    # Stable node identifier for save-independent phenotype inspection.
    dna_root.name = "DNA_DoubleStrand"
    dna_root.set_meta("display","compact coiled genetic material; unconfined in cytoplasm")
    host.add_child(dna_root)
    var points := PackedVector3Array()
    # One continuous purple polymer wound over a compact three-dimensional
    # ball. This is a readable nucleoid symbol, not a literal molecular scale.
    for i in range(721):
        var u: float = float(i)/720.0*TAU*23.5
        var latitude: float = sin(u*.381966)*1.42
        var radius: float = .25*(.82+.18*sin(u*.271))
        points.append(Vector3(cos(u)*cos(latitude)*radius,
            .12+sin(latitude)*radius,sin(u)*cos(latitude)*radius))
    _tube(dna_root,points,.017,DNA_COLOR)

func _bilayer() -> void:
    # Two leaflets of ONE amphiphile bilayer, not two independent membranes.
    var inner := MeshInstance3D.new()
    inner.name = "Membrane_InnerLeaflet"
    inner.mesh = membrane.mesh
    inner.transform = membrane.transform
    inner.scale *= .94
    inner.material_override = membrane.material_override
    inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    membrane.get_parent().add_child(inner)
    inner.set_meta("display","inner leaflet of lipid bilayer; molecular scale exaggerated")
    if Genome.has(traits,"hydrolase_secretion"):
        var enzymes := Node3D.new()
        enzymes.name = "CytoplasmicEnzymes"
        interior.add_child(enzymes)
        for i in range(12):
            var phi: float = i*2.39996
            var r: float = .36+.025*(i%4)
            _tube(enzymes,PackedVector3Array([Vector3(cos(phi)*r,.10,sin(phi)*r),Vector3(cos(phi)*r+.035,.115,sin(phi)*r+.02)]),.009,Color(.65,.91,.80))

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
    for mesh_node in piece.find_children("*","MeshInstance3D",true,false):
        var color: Color = Color(.53,.92,.87)
        if id=="protease": color=CATALYST_COLOR
        elif id=="pili": color=Color(.66,.80,.97)
        elif id=="receptor": color=Color(.94,.76,.42)
        mesh_node.material_override=_mat(color,.46 if id=="vesicle" else 1.0,.42)
    return true

func _build() -> void:
    var primitive: bool = branch == "pre_luca"
    # Solo un locus morfogenetico MAGGIORE modifica la forma.
    var shape: float = clampf(float(traits.get("elongation",0.0))*.38,0.0,.24)
    var elongated: bool = shape > .18
    body_radii = Vector3(1.03+shape,.56,.69-shape*.16)
    if primitive:
        body_radii *= .90
    if elongated:
        body_radii.x += .04
        body_radii.z -= .015
    var tint: Color = _color()
    var globe := SphereMesh.new()
    globe.radius = 1.0
    globe.height = 2.0
    globe.radial_segments = 48
    globe.rings = 28

    var thermal: float = float(_level("thermal_membrane"))*.8
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
        shell_mat.set_shader_parameter("rim_tint",Color(.58,.98,.96))
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
        if dna:
            _build_imported_dna(interior)
        if not dna:
            var poly := PackedVector3Array()
            for i in range(61):
                var t: float = float(i)/60.0
                poly.append(Vector3((t-.5)*.72+sin(t*TAU*3.1)*.14,
                    sin(t*TAU*1.85)*.16+cos(t*TAU*3.4)*.075,
                    cos(t*TAU*1.43)*.22+sin(t*TAU*2.5)*.065))
            _tube(interior,poly,.018 if primitive else .020,RNA_COLOR)
            interior.get_child(0).name = "SingleStrand_RNA"

    var ribozymes := Node3D.new()
    ribozymes.name = "Catalytic_RNA_Folds"
    interior.add_child(ribozymes)
    for i in range(3):
        var a: float = TAU*float(i)/3.0
        var at := Vector3(cos(a)*.45,.12,sin(a)*.35)
        var fold := PackedVector3Array()
        for j in range(25):
            var t: float = float(j)/24.0
            fold.append(at+Vector3(cos(t*TAU)*.055,sin(t*PI)*.035,(t-.5)*.12))
        _tube(ribozymes,fold,.010,RNA_COLOR)
    _bilayer()

    # Trasportatori: pori incastonati nella membrana; solo locus maggiore.
    var feature_start: int = get_child_count()
    var transporters: int = clampi(int(traits.get("transporters",0)),0,9)
    for i in range(transporters):
        var phi: float = TAU*(float(i)+.43)/float(maxi(1,transporters))
        var n := Vector3(cos(phi),.24*sin(phi*1.75),sin(phi)).normalized()
        var pos := Vector3(n.x*body_radii.x,.81+n.y*body_radii.y,n.z*body_radii.z)
        if not _blender_module("transporter",pos,n,.85):
            _ellipsoid(self,pos,Vector3(.048,.038,.048),Color(.40,.59,.60),.90)
            _ellipsoid(self,pos+n*.026,Vector3(.024,.018,.024),Color(.20,.35,.37),.86)
    _record_children("membrane_transport",feature_start)
    feature_start = get_child_count()
    # Moduli di adesione, riconoscimento e lisi emergono per mutazione.
    var receptors: int = clampi(int(traits.get("receptors",0)),0,8)
    for i in range(receptors):
        var a: float = TAU*(float(i)+.3)/float(maxi(1,receptors))
        var n: Vector3 = Vector3(cos(a),.22*sin(a*1.8),sin(a)).normalized()
        var anchor: Vector3 = Vector3(n.x*body_radii.x,n.y*body_radii.y,n.z*body_radii.z)+Vector3(0,.81,0)
        if not _blender_module("receptor",anchor,n,1.0):
            _tube(self,PackedVector3Array([anchor,anchor+n*.11]),.018,Color(.74,.84,.72))
            _ellipsoid(self,anchor+n*.12,Vector3.ONE*.04,Color(.82,.85,.74))
    _record_children("surface_recognition",feature_start)
    feature_start = get_child_count()
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
    _record_children("pili_twitch",feature_start)
    feature_start = get_child_count()
    var proteases: int = clampi(int(traits.get("protease",0)),0,6)
    for i in range(proteases):
        var a: float = TAU*(float(i)+.5)/float(maxi(1,proteases))
        var n := Vector3(cos(a),0,sin(a))
        var loc := Vector3(n.x*body_radii.x,.81,n.z*body_radii.z)
        if not _blender_module("protease",loc,n,1.0):
            _ellipsoid(self,loc,Vector3(.045,.025,.043),Color(.80,.64,.52))
            _ellipsoid(self,loc+n*.11,Vector3.ONE*.02,Color(.85,.68,.52),.65)
    _record_children("hydrolase_secretion",feature_start)
    feature_start = get_child_count()
    var vesicles: int = clampi(int(traits.get("vesicles",0)),0,5)
    for i in range(vesicles):
        var a: float = TAU*(float(i)+.2)/float(maxi(1,vesicles))
        var point := Vector3(cos(a)*body_radii.x*1.23,.81+sin(a*2.0)*.12,sin(a)*body_radii.z*1.23)
        if not _blender_module("vesicle",point,Vector3.UP,1.0):
            _ellipsoid(self,point,Vector3.ONE*.065,tint.lightened(.15),.27)
    _record_children("vesicle_pathway",feature_start)
    feature_start = get_child_count()
    if bool(traits.get("adhesion",false)):
        for i in range(4):
            var a: float = TAU*float(i)/4.0
            var n := Vector3(cos(a),.09,sin(a)).normalized()
            var anchor := Vector3(n.x*body_radii.x,.81+n.y*body_radii.y,n.z*body_radii.z)
            _tube(self,PackedVector3Array([anchor,anchor+n*.13,anchor+n*.20]),.017,Color(.69,.81,.74))
    _record_children("surface_recognition",feature_start)
    feature_start = get_child_count()
    if bool(traits.get("eps",false)):
        var matrix: MeshInstance3D = _ellipsoid(self,Vector3(0,.81,0),body_radii*1.15,Color(.49,.75,.63),.075)
        matrix.name = "EPS_ExtracellularMatrix"
        # Sparse extracellular strands make the capsule legible without a second wall.
        for i in range(5):
            var arc := PackedVector3Array()
            for j in range(13):
                var a: float = float(i)*TAU/5.0+float(j)*.055
                arc.append(Vector3(cos(a)*body_radii.x*1.15,.81+sin(a*2.0)*.14,sin(a)*body_radii.z*1.15))
            _tube(self,arc,.009,Color(.54,.78,.64),.40)
    _record_children("eps_biosynthesis",feature_start)
    _build_envelope()
    _build_thermal_domains()
    _build_chaperones()
    feature_start = get_child_count()
    var motors: int = int(traits.get("archaella",0)) if branch == "archaea" else int(traits.get("flagella",0)) if branch == "bacteria" else 0
    for i in range(mini(4,motors)):
        var archaeal: bool = branch == "archaea"
        var assembly := Node3D.new()
        assembly.name = "GeneModule_Archaellum" if archaeal else "GeneModule_Flagellum"
        var polar: float = (float(i)-float(mini(4,motors)-1)*.5)*.16
        assembly.position = Vector3(-body_radii.x*sqrt(1.0-polar*polar),.81,body_radii.z*polar)
        add_child(assembly)
        var motor_tint: Color = Color(.51,.80,.87) if archaeal else Color(.78,.69,.48)
        _ellipsoid(assembly,Vector3.ZERO,Vector3(.035,.049,.049),motor_tint.darkened(.15)).name = "BasalMotor"
        var hook := PackedVector3Array()
        for j in range(13):
            var u: float = float(j)/12.0
            hook.append(Vector3(-.22*u,.06*sin(u*PI*.5),.025*sin(u*PI)))
        _tube(assembly,hook,.016 if archaeal else .021,motor_tint)
        assembly.get_child(1).name = "BasalConnector" if archaeal else "FlexibleHook"
        var rotor := Node3D.new()
        rotor.name = "Archaellum_RotaryFilament" if archaeal else "Flagellum_RotaryFilament"
        rotor.position = hook[hook.size()-1]
        assembly.add_child(rotor)
        filament_roots.append(rotor)
        var path := PackedVector3Array()
        var turns: float = 1.8 if archaeal else 1.55
        var length: float = 2.65 if archaeal else 3.1
        for j in range(65):
            var u: float = float(j)/64.0
            var amplitude: float = (.13 if archaeal else .18)*smoothstep(0.0,.16,u)
            path.append(Vector3(-u*length,sin(u*TAU*turns)*amplitude,cos(u*TAU*turns)*amplitude))
        _tube(rotor,path,.013 if archaeal else .017,motor_tint)
    _record_children("archaellar_motor" if branch == "archaea" else "flagellar_motor",feature_start)

    _record_genetic_core()
    _build_evolution_capabilities()
    _prepare_replication()

    # Ombra di contatto morbida: il fondo resta lontano dalla cellula,
    # ma l'osservatore percepisce l'altezza del corpo sopra il sedimento.
    var shadow_plane := PlaneMesh.new()
    shadow_plane.size = Vector2(2.35,2.35)
    var shadow := MeshInstance3D.new()
    shadow.name = "ContactShadow"
    shadow.mesh = shadow_plane
    shadow.position = Vector3(0,-.242,0)
    var shadow_mat := ShaderMaterial.new()
    shadow_mat.shader = SHADOW_SHADER
    shadow_mat.set_shader_parameter("strength",.31)
    shadow.material_override = shadow_mat
    shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shadow)

    var ring := TorusMesh.new()
    ring.inner_radius = .16
    ring.outer_radius = .19
    ring.rings = 56
    ring.ring_segments = 8
    selection_ring = MeshInstance3D.new()
    selection_ring.mesh = ring
    selection_ring.position.y = -.08
    selection_ring.material_override = _mat(Color(.70,.95,.86),.45)
    selection_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    selection_ring.visible = is_player
    add_child(selection_ring)

func _level(locus: String) -> int:
    return Genome.expressed_allele(traits,locus,branch)

func _capability_root(id: String, external: bool = false) -> Node3D:
    var node := Node3D.new()
    node.name = "Evolution_"+id
    node.set_meta("evolution_capability",id)
    if external:
        add_child(node)
    else:
        interior.add_child(node)
    feature_nodes[id] = {"allele":1,"nodes":[node]}
    return node

func _build_evolution_capabilities() -> void:
    var caps: Dictionary = traits.get("evolution_capabilities",{})
    if bool(caps.get("translation",false)):
        var ribosomes: Node3D = _capability_root("translation")
        for i in range(3):
            var at := Vector3(-.38+float(i)*.32,.16,-.25)
            _ellipsoid(ribosomes,at,Vector3(.065,.045,.05),Color(.68,.73,.83),.95)
            _ellipsoid(ribosomes,at+Vector3(0,.065,0),Vector3(.085,.055,.065),Color(.68,.73,.83),.95)
            _tube(ribosomes,PackedVector3Array([at+Vector3(-.12,.025,0),at+Vector3(.12,.025,0)]),.009,RNA_COLOR)
            _tube(ribosomes,PackedVector3Array([at+Vector3(0,.11,0),at+Vector3(.03,.17,0),at+Vector3(.08,.17,0)]),.009,Color(.85,.85,.61))
    if bool(caps.get("cytoskeleton",false)):
        var network: Node3D = _capability_root("cytoskeleton")
        for i in range(3):
            var z: float = -.25+float(i)*.23
            _tube(network,PackedVector3Array([Vector3(-.6,-.18,z),Vector3(0,-.11,z+.09),Vector3(.6,-.18,z)]),.009,Color(.50,.78,.77),.65)
    if bool(caps.get("asgard_host",false)):
        var protrusions: Node3D = _capability_root("asgard_host",true)
        for i in range(4):
            var a: float = float(i)*TAU/4.0+.35
            var n := Vector3(cos(a),0,sin(a))
            var anchor := Vector3(n.x*body_radii.x,.81,n.z*body_radii.z)
            _tube(protrusions,PackedVector3Array([anchor,anchor+n*.18+Vector3(0,.06,0),anchor+n*.36+Vector3(0,.02,0)]),.035,Color(.52,.78,.85),.65)
    var mature_mito: bool = bool(caps.get("mitochondrion",false))
    if bool(caps.get("internal_symbiont",false)) or mature_mito:
        var symbiont: Node3D = _capability_root("internal_symbiont")
        var center := Vector3(.38,.02,.18)
        _ellipsoid(symbiont,center,Vector3(.19,.105,.11),Color(.82,.52,.28),.50)
        if not mature_mito:
            var bacterial_dna := PackedVector3Array()
            for i in range(33):
                var a: float = TAU*float(i)/32.0
                bacterial_dna.append(center+Vector3(cos(a)*.10,.075,sin(a)*.035))
            _tube(symbiont,bacterial_dna,.007,Color(.75,.45,.95))
        if mature_mito:
            var mitochondrion: Node3D = _capability_root("mitochondrion")
            _ellipsoid(mitochondrion,center,Vector3(.157,.080,.085),Color(.95,.72,.35),.50)
            for i in range(4):
                var x: float = center.x-.10+float(i)*.065
                _tube(mitochondrion,PackedVector3Array([Vector3(x,.04,.12),Vector3(x+.02,.075,.18),Vector3(x,.04,.24)]),.012,Color(.98,.74,.37))
            mitochondrion.set_meta("display","double outline with internal cristae; stylized")
    if bool(caps.get("membrane_traffic",false)):
        var er: Node3D = _capability_root("membrane_traffic")
        # Early membrane traffic: vesicles, not a prematurely mature ER/Golgi stack.
        for i in range(3):
            _ellipsoid(er,Vector3(-.36+float(i)*.16,-.05,.25),Vector3.ONE*(.035+float(i)*.008),Color(.49,.76,.85),.40)
    if bool(caps.get("er_golgi",false)):
        var golgi: Node3D = _capability_root("er_golgi")
        for i in range(4):
            var path := PackedVector3Array()
            for j in range(9):
                var x: float = (float(j)/8.0-.5)*.29
                path.append(Vector3(x+.24,.10+float(i)*.043,-.29+sin(float(j)/8.0*PI)*.055))
            _tube(golgi,path,.023,Color(.84,.61,.84),.85)
        for i in range(3):
            _ellipsoid(golgi,Vector3(.43,.12+float(i)*.06,-.27),Vector3.ONE*.026,Color(.89,.72,.90),.70)
    if bool(caps.get("nucleus",false)):
        var nucleus: Node3D = _capability_root("nucleus")
        _ellipsoid(nucleus,Vector3(-.15,.13,.02),Vector3(.24,.22,.23),Color(.61,.57,.87),.20)
        _ellipsoid(nucleus,Vector3(-.15,.13,.02),Vector3(.22,.20,.21),Color(.61,.57,.87),.12)
        nucleus.set_meta("display","double nuclear envelope; DNA remains inside")
        var dna: Node3D = find_child("DNA_DoubleStrand",true,false) as Node3D
        if dna == null:
            _build_imported_dna(interior)
            dna = interior.get_node("DNA_DoubleStrand")
        dna.position = Vector3(-.15,.06,.02)
        dna.scale = Vector3.ONE*.60
        dna.set_meta("display","compact DNA inside nuclear envelope")
    if bool(caps.get("leca",false)):
        var leca: Node3D = _capability_root("leca")
        leca.set_meta("display","integrated phenotype; organelles remain gated by individual capabilities")
        # Sparse coordinated trafficking markers, no duplicate organelles or extra shell.
        for i in range(4):
            _ellipsoid(leca,Vector3(-.02+float(i)*.09,.28,-.12),Vector3.ONE*.014,Color(.76,.86,.92),.75)

func _prepare_replication() -> void:
    replication_source = find_child("DNA_DoubleStrand",true,false) as Node3D
    if replication_source == null:
        replication_source = find_child("SingleStrand_RNA",true,false) as Node3D
    if replication_source == null:
        return
    replication_origin = replication_source.position
    replication_copy = replication_source.duplicate() as Node3D
    replication_copy.name = "Replicated_GeneticMaterial"
    replication_source.get_parent().add_child(replication_copy)
    replication_copy.hide()
    set_division_progress(0.0)

func _record(locus: String, node: Node3D) -> void:
    var level: int = _level(locus)
    if level<=0 or not is_instance_valid(node):
        return
    if not feature_nodes.has(locus):
        feature_nodes[locus] = {"allele":level,"nodes":[]}
    feature_nodes[locus]["nodes"].append(node)
    node.set_meta("phenotype_locus",locus)
    node.set_meta("phenotype_allele",level)

func _record_children(locus: String, first: int) -> void:
    for i in range(first,get_child_count()):
        var node: Node3D = get_child(i) as Node3D
        if node != null:
            _record(locus,node)

func _record_genetic_core() -> void:
    if bool(traits.get("dna",false)):
        var dna: Node3D = find_child("DNA_DoubleStrand",true,false) as Node3D
        _record("dna_stabilization",dna)
        # DNA does not eliminate RNA. A shorter transcript remains in cytosol.
        var transcript := Node3D.new()
        transcript.name = "Accessory_RNA"
        interior.add_child(transcript)
        var path := PackedVector3Array()
        for i in range(25):
            var t: float = float(i)/24.0
            path.append(Vector3((t-.5)*.65,.25+sin(t*TAU)*.045,-.28+sin(t*TAU*1.4)*.04))
        _tube(transcript,path,.012,RNA_COLOR)
        _record("rna_replicase",transcript)
    else:
        var rna: Node3D = find_child("SingleStrand_RNA",true,false) as Node3D
        if rna == null and interior.get_child_count()>0:
            rna = interior.get_child(0) as Node3D
        _record("rna_replicase",rna)
    _record("cell_elongation",membrane)
    # Sparse solute markers: visual convention, not extra organelles.
    for i in range(7):
        var a: float = float(i)*2.39996
        _ellipsoid(interior,Vector3(cos(a)*.50,sin(a*1.7)*.24,sin(a)*.44),
            Vector3.ONE*(.012+.003*(i%3)),Color(.43,.80,.86),.65)

func _build_thermal_domains() -> void:
    var level: int = _level("thermal_membrane")
    if level<=0:
        return
    var domains := Node3D.new()
    domains.name = "Thermal_MembraneDomains"
    domains.set_meta("scientific_display","false-color lipid-composition cue, not universal membrane rigidity")
    add_child(domains)
    for i in range(level*3):
        var path := PackedVector3Array()
        var phi: float = float(i)*TAU/float(level*3)
        for j in range(10):
            var a: float = phi+float(j)*.025
            var y: float = .22*sin(phi*2.0)
            var radial: float = sqrt(1.0-y*y)*1.012
            path.append(Vector3(cos(a)*body_radii.x*radial,.81+y*body_radii.y,sin(a)*body_radii.z*radial))
        _tube(domains,path,.017,Color(.91,.70,.30),.62)
    _record("thermal_membrane",domains)

func _build_chaperones() -> void:
    var level: int = _level("chaperone_complex")
    if level<=0:
        return
    var complexes := Node3D.new()
    complexes.name = "Chaperone_CytosolicComplexes"
    complexes.set_meta("scientific_display","non-membranous protein complexes, exaggerated scale")
    interior.add_child(complexes)
    for i in range(level+1):
        var a: float = float(i)*TAU/float(level+1)+.4
        var center := Vector3(cos(a)*.43,-.20+sin(a)*.09,sin(a)*.36)
        var torus := TorusMesh.new()
        torus.inner_radius = .041
        torus.outer_radius = .083
        torus.rings = 12
        torus.ring_segments = 6
        var complex := MeshInstance3D.new()
        complex.name = "Chaperonin_Ring_%d" % i
        complex.mesh = torus
        complex.position = center
        complex.rotation = Vector3(.3,a,.2)
        complex.material_override = _mat(Color(.23,.70,.79))
        complex.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        complexes.add_child(complex)
        _ellipsoid(complexes,center,Vector3.ONE*.026,CATALYST_COLOR)
    _record("chaperone_complex",complexes)

func _wall_lattice(host: Node3D, radii: Vector3, tint: Color, fine: bool) -> void:
    # Local surface patches replace latitude/longitude cage lines.
    for i in range(14):
        var phi: float = float(i)*2.39996
        var y: float = -.60+float(i%5)*.27
        var radial: float = sqrt(1.0-y*y)
        var patch := PackedVector3Array()
        for j in range(9):
            var angle: float = phi+(float(j)-4.0)*.025
            patch.append(Vector3(cos(angle)*radii.x*radial,.81+y*radii.y,sin(angle)*radii.z*radial))
        _tube(host,patch,.012 if fine else .024,tint,.40 if fine else .65)

func _build_envelope() -> void:
    var envelope: String = str(traits.get("envelope","none"))
    if envelope == "none":
        return
    var wall := Node3D.new()
    wall.name = "Envelope_"+envelope
    add_child(wall)
    if envelope == "monoderm":
        wall.set_meta("scientific_display","one cytoplasmic membrane plus peptidoglycan wall")
        _wall_lattice(wall,body_radii*1.035,Color(.77,.72,.48),false)
        _record("monoderm_envelope",wall)
    elif envelope == "diderm":
        wall.set_meta("scientific_display","thin wall and periplasm between cytoplasmic and outer membranes")
        _wall_lattice(wall,body_radii*1.025,Color(.77,.72,.48),true)
        var outer: MeshInstance3D = _ellipsoid(wall,Vector3(0,.81,0),body_radii*1.105,Color(.38,.68,.73),.10)
        outer.name = "OuterMembrane"
        _record("diderm_envelope",wall)
    elif envelope == "archaeal":
        wall.set_meta("scientific_display","illustrative protein S-layer; not universal across Archaea")
        _wall_lattice(wall,body_radii*1.035,Color(.50,.72,.85),true)
        _record("archaeal_envelope",wall)

func _process(delta: float) -> void:
    age += delta
    # Stable presentation size; volume-preserving motion lives in FluidMotion.
    scale = Vector3.ONE*growth*1.45
    if is_instance_valid(interior):
        interior.rotation.y = sin(age*.32)*.09
        interior.position.y = sin(age*.83)*.015 if blender_interior else .81+sin(age*.83)*.015
    for i in range(filament_roots.size()):
        var root: Node3D = filament_roots[i]
        # Both propulsors are rotary helical filaments; not whipping eukaryotic cilia.
        root.rotation.x = age*(4.1 if branch == "archaea" else 3.3)+float(i)*.8
