extends SceneTree
## Questo test fallisce se il gioco usa ancora i segnaposto procedurali
## invece di caricare i veri mesh asset Blender/glTF.
const G = preload("res://src/cell_genome.gd")
const CORE = "res://assets/models/primordial_core.glb"

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    assert(ResourceLoader.exists(CORE), "Cell model GLB missing")
    var packed: PackedScene = load(CORE) as PackedScene
    assert(packed != null)
    var scene: Node3D = packed.instantiate() as Node3D
    assert(scene != null)
    assert(scene.find_child("Membrane_Outer",true,false) != null)
    assert(scene.find_child("SingleStrand_RNA",true,false) != null)
    assert(scene.find_child("Autocatalytic_01_01",true,false) != null)
    scene.queue_free()

    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var cell: CellVisual = game.get("player")
    assert(cell != null)
    assert(cell.use_blender_assets)
    assert(cell.find_child("BlenderCellCore",true,false) != null)
    assert(not bool(game.entities[game.player_id]["traits"].get("dna",true)))

    var tr: Dictionary = game.call("_base_traits")
    for locus in ["dna_stabilization","surface_recognition","pili_twitch",
                  "hydrolase_secretion","vesicle_pathway","membrane_transport"]:
        tr = G.grant(tr,locus,3,"test_import","bacteria")
    cell.setup(tr,"bacteria",true)
    assert(cell.use_blender_assets)
    for module_name in ["pili","receptor","protease","transporter","vesicle"]:
        assert(cell.find_child("GeneModule_"+module_name,true,false) != null,
            "Missing GLB gene module "+module_name)
    print("PASS: Blender GLB core + major-gene modules instantiated by actual Godot scene importer")
    quit(0)
