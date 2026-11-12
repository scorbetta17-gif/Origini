extends Node3D
## Scena ausiliaria: apre direttamente otto fenotipi renderizzati in Godot.
const CellScript = preload("res://src/cell_visual.gd")

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
    cam.size = 18.5
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
    var base := {"motility":1.0,"attack":1.0,"defense":1.0,"mutation":0.0,
        "metabolism":1.0,"uptake":1.0,"archaella":0,"dna":false,"eps":false,"adhesion":false,"flagella":0,"envelope":"none","signature":0.0,"mutations":[]}
    var variants := [
        ["01 · Protocellula RNA","pre_luca",{}],
        ["02 · LUCA con DNA","luca",{"dna":true}],
        ["03 · Bacteria monoderma","bacteria",{"dna":true,"defense":1.5,"envelope":"monoderm"}],
        ["04 · Bacteria didermica*","bacteria",{"dna":true,"defense":1.2,"uptake":1.35,"envelope":"diderm","flagella":3}],
        ["05 · Archaea motile","archaea",{"dna":true,"archaella":5,"motility":1.55,"envelope":"archaeal"}],
        ["06 · Predatore litico","archaea",{"dna":true,"attack":1.85,"archaella":2,"envelope":"archaeal"}],
        ["07 · Involucro EPS","bacteria",{"dna":true,"eps":true,"adhesion":true,"defense":1.75,"envelope":"monoderm"}],
        ["08 · Trasportatori potenziati","archaea",{"dna":true,"uptake":1.85,"motility":.92,"envelope":"archaeal"}]
    ]
    for i in range(variants.size()):
        var current: Array = variants[i]
        var traits: Dictionary = base.duplicate(true)
        for key in current[2]:
            traits[key] = current[2][key]
        var cell: CellVisual = CellScript.new()
        add_child(cell)
        cell.position = Vector3(float(i%4-1.5)*4.5,0,float(int(i/4))*5.2-2.6)
        cell.setup(traits,current[1])
        cell.set_growth(.58 if i == 0 else 1.0)
        var caption := Label3D.new()
        caption.text = current[0]
        caption.font_size = 28
        caption.pixel_size = 0.006
        caption.position = Vector3(0,2.0,0)
        caption.modulate = Color(.86,.96,.96)
        cell.add_child(caption)
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "ORIGINI — GALLERIA FENOTIPI 3D | Scena di sviluppo"
    title.position = Vector2(20,20)
    title.add_theme_font_size_override("font_size",22)
    title.add_theme_color_override("font_color",Color(.88,.98,.96))
    layer.add_child(title)
    var hint := Label.new()
    hint.text = "* I due involucro batterici sono prototipi visivi, non ricostruzioni filogenetiche."
    hint.position = Vector2(20,55)
    layer.add_child(hint)
