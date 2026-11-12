extends SceneTree
## Frame REALI del renderer Godot. Nessuna generazione di immagini AI.
const GENOME = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var method: String = RenderingServer.get_current_rendering_method()
    var driver: String = RenderingServer.get_current_rendering_driver_name()
    print("ORIGIN_ACTUAL_RENDERER=",method," DRIVER=",driver)
    if OS.get_environment("ORIGIN_REQUIRE_MOBILE") == "1":
        if method != "mobile" or driver != "vulkan":
            push_error("Vulkan Mobile not active; got "+method+" / "+driver)
            quit(1)
            return
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
    game.call("_toggle_focus")
    camera.position = hero.position+Vector3(1.3,2.1,3.4)
    camera.look_at(hero.position+Vector3(0,.65,0))
    await create_timer(.95).timeout
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
    game.entities[game.player_id]["branch"] = "bacteria"
    game.entities[game.player_id]["generation"] = 3
    game.set("generation",3)
    hero.setup(traits,"bacteria",true)
    game.call("_refresh_hud")
    await create_timer(.38).timeout
    if not _save_frame("cellula-evoluta"):
        quit(1)
        return
    if not _save_frame("fenotipo-macro"):
        quit(1)
        return
    hero.position = Vector3(-9.8,0,3.2)
    game.call("_toggle_focus")
    await create_timer(.70).timeout
    camera.position = hero.position+Vector3(0,7.5,8.7)
    camera.look_at(hero.position)
    if not _save_frame("bioma-idrotermale"):
        quit(1)
        return

    # Screenshots of real native Godot Controls in the 720x1280 portrait viewport.
    game.call("_new_game")
    await create_timer(.95).timeout
    game.call("_refresh_hud")
    if not _save_frame("classic-main"):
        quit(1)
        return
    var required: Dictionary = {"carbon":24.0,"amino":15.0,"lipid":12.0,"nucleic":8.0,"biomass":65.0}
    for k in required:
        game.resources[k] = required[k]
    game.atp = 96.0
    game.call("_divide_pressed")
    await create_timer(.4).timeout
    if not _save_frame("classic-daughters"):
        quit(1)
        return
    game.call("_choose_daughter",0)
    game.call("_on_tree")
    await create_timer(.40).timeout
    if not _save_frame("classic-evolution"):
        quit(1)
        return
    game.call("_close_overlay")
    game.call("_on_genealogy")
    await create_timer(.40).timeout
    if not _save_frame("classic-lineage"):
        quit(1)
        return
    quit(0)

func _save_frame(label: String) -> bool:
    var dir: String = ProjectSettings.globalize_path("res://build/previews")
    DirAccess.make_dir_recursive_absolute(dir)
    var prefix: String = OS.get_environment("ORIGIN_CAPTURE_PREFIX")
    var path: String = dir+"/"+prefix+label+"-godot.png"
    var snapshot: Image = root.get_texture().get_image()
    var result: Error = snapshot.save_png(path)
    print("SCREENSHOT_GODOT=",path," result=",result)
    return result == OK
