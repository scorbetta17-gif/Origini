extends SceneTree
## Frame REALI del renderer Godot. Nessuna generazione di immagini AI.
const GENOME = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn")
    if packed == null:
        push_error("Scena principale non disponibile")
        quit(1)
        return
    var game: Node = packed.instantiate()
    root.add_child(game)
    await create_timer(1.0).timeout
    if not _save_frame("primordiale"):
        quit(1)
        return
    var hero: Node3D = game.get("player")
    var camera: Camera3D = game.get("camera")
    # Lente macro: screenshot reale per ispezionare volume e strutture.
    camera.position = hero.position+Vector3(0,3.25,4.25)
    camera.look_at(hero.position+Vector3(0,.62,0))
    camera.fov = 34.0
    await create_timer(.30).timeout
    if not _save_frame("primordiale-macro"):
        quit(1)
        return
    var traits: Dictionary = game.call("_base_traits")
    for gene in ["dna_stabilization","diderm_envelope","surface_recognition",
                 "pili_twitch","hydrolase_secretion","vesicle_pathway",
                 "membrane_transport","cell_elongation","chaperone_complex"]:
        traits = GENOME.grant(traits,str(gene),3,"preview_gene","bacteria")
    # Il fenotipo di anteprima deriva dal GENOMA: nessun flag visivo artificiale.
    game.entities[game.player_id]["traits"] = traits
    hero.setup(traits,"bacteria",true)
    await create_timer(.38).timeout
    if not _save_frame("cellula-evoluta"):
        quit(1)
        return
    if not _save_frame("fenotipo-macro"):
        quit(1)
        return
    hero.position = Vector3(-9.8,0,3.2)
    var previous: Vector3 = game.get("camera_offset")
    game.set("camera_offset",Vector3(0,7.5,8.7))
    await create_timer(.65).timeout
    camera.position = hero.position+Vector3(0,7.5,8.7)
    camera.look_at(hero.position)
    if not _save_frame("bioma-idrotermale"):
        quit(1)
        return
    game.set("camera_offset",previous)
    quit(0)

func _save_frame(label: String) -> bool:
    var dir: String = ProjectSettings.globalize_path("res://build/previews")
    DirAccess.make_dir_recursive_absolute(dir)
    var path: String = dir+"/"+label+"-godot.png"
    var snapshot: Image = root.get_texture().get_image()
    var result: Error = snapshot.save_png(path)
    print("SCREENSHOT_GODOT=",path," result=",result)
    return result == OK
