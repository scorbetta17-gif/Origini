extends Node3D
## Scena ausiliaria: apre direttamente otto fenotipi renderizzati in Godot.
const CellScript = preload("res://src/cell_visual.gd")
const Genome = preload("res://src/cell_genome.gd")

static func variants() -> Array[Dictionary]:
    return [
        {"name":"01 · Protocellula a RNA","branch":"pre_luca","loci":{}},
        {"name":"02 · Protocellula con DNA","branch":"pre_luca","loci":{"dna_stabilization":1}},
        {"name":"03 · LUCA schematico","branch":"luca","loci":{"dna_stabilization":1,"membrane_transport":1,"surface_recognition":1}},
        {"name":"04 · Bacteria mobile","branch":"bacteria","loci":{"dna_stabilization":1,"monoderm_envelope":1,"flagellar_motor":1,"cell_elongation":1,"pili_twitch":1}},
        {"name":"05 · Bacteria diderma","branch":"bacteria","loci":{"dna_stabilization":1,"diderm_envelope":1,"membrane_transport":2,"cell_elongation":2}},
        {"name":"06 · Archaea secernente","branch":"archaea","loci":{"dna_stabilization":1,"archaeal_envelope":1,"hydrolase_secretion":2,"vesicle_pathway":2}},
        {"name":"07 · Archaea termotollerante","branch":"archaea","loci":{"dna_stabilization":1,"archaeal_envelope":1,"archaellar_motor":2,"thermal_membrane":2,"chaperone_complex":2,"cell_elongation":1}},
        {"name":"08 · Matrice EPS e trasporto","branch":"bacteria","loci":{"dna_stabilization":1,"monoderm_envelope":1,"eps_biosynthesis":1,"surface_recognition":2,"membrane_transport":3}}
    ]

static func traits_for_variant(variant: Dictionary) -> Dictionary:
    var traits: Dictionary = {"motility":1.0,"attack":1.0,"defense":1.0,"mutation":0.0,
        "metabolism":1.0,"uptake":1.0,"signature":0.0,"mutations":[],"genome":Genome.origin()}
    var branch: String = str(variant["branch"])
    for locus in variant["loci"]:
        for level in range(int(variant["loci"][locus])):
            traits = Genome.grant(traits,locus,level+1,"gallery_example",branch)
    return Genome.normalize(traits,branch)


func _ready() -> void:
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(.018,.075,.10)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color(.48,.76,.86)
    env.environment.ambient_light_energy = .85
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-53,24,-21)
    sun.light_energy = 1.6
    sun.light_color = Color(.55,.85,1)
    add_child(sun)
    var warm := OmniLight3D.new()
    warm.position = Vector3(-3,4,-2)
    warm.light_color = Color(.96,.55,.42)
    warm.light_energy = 1.2
    warm.omni_range = 15.0
    add_child(warm)
    var cam := Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 12.0
    cam.position = Vector3(0,14,19)
    add_child(cam)
    cam.look_at(Vector3(0,.25,0))
    cam.current = true
    var plane := PlaneMesh.new()
    plane.size = Vector2(35,35)
    var ground := MeshInstance3D.new()
    ground.mesh = plane
    ground.position.y = -.24
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(.03,.21,.25)
    ground.material_override = material
    add_child(ground)
    var examples: Array[Dictionary] = variants()
    for i in range(examples.size()):
        var current: Dictionary = examples[i]
        var traits: Dictionary = traits_for_variant(current)
        var cell: CellVisual = CellScript.new()
        add_child(cell)
        cell.position = Vector3(float(i%4-1.5)*4.5,0,float(int(i/4))*8.0-4.0)
        cell.setup(traits,str(current["branch"]))
        cell.set_growth(1.0)
        if i == 3:
            cell.rotation.y = -PI*.5
        elif i == 6:
            cell.rotation.y = PI*.5
        var caption := Label3D.new()
        caption.text = str(current["name"])
        caption.font_size = 32
        caption.pixel_size = 0.008
        caption.position = cell.position+Vector3(0,3.05,0)
        caption.no_depth_test = true
        caption.modulate = Color(.86,.96,.96)
        add_child(caption)
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "ORIGINI — GALLERIA FENOTIPI 3D | Scena di sviluppo"
    title.position = Vector2(20,20)
    title.add_theme_font_size_override("font_size",22)
    title.add_theme_color_override("font_color",Color(.88,.98,.96))
    layer.add_child(title)
    var hint := Label.new()
    hint.text = "Genotipi reali del gioco · forme, colori e dimensioni simbolici. LUCA e protocellule: modelli ipotetici, non ricostruzioni."
    hint.position = Vector2(20,55)
    layer.add_child(hint)
