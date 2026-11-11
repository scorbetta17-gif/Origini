extends SceneTree
## Cattura frame autentici dal motore Godot. Non e' un concept AI.
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
    await create_timer(1.5).timeout
    if not _save_frame("primordiale"):
        quit(1)
        return
    var traits: Dictionary = game.call("_base_traits")
    traits["dna"] = true
    traits["pili"] = 5
    traits["receptors"] = 4
    traits["protease"] = 2
    traits["vesicles"] = 2
    traits["adhesion"] = true
    traits["thermotolerance"] = 2.0
    game.call("_create_entity","PREVIEW", "", 3, "bacteria",traits,Vector3(2.3,0,0),false,true)
    await create_timer(.4).timeout
    if not _save_frame("cellula-evoluta"):
        quit(1)
        return
    var controlled: Node3D = game.get("player")
    controlled.position = Vector3(-11.0,0,3.0)
    await create_timer(.9).timeout
    if not _save_frame("bioma-idrotermale"):
        quit(1)
        return
    quit(0)

func _save_frame(label: String) -> bool:
    var dir: String = ProjectSettings.globalize_path("res://build/previews")
    DirAccess.make_dir_recursive_absolute(dir)
    var path: String = dir+"/"+label+"-godot.png"
    var image: Image = root.get_texture().get_image()
    var result: Error = image.save_png(path)
    print("SCREENSHOT_GODOT=",path," result=",result)
    return result == OK
