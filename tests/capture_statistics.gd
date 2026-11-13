extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = root.size
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    # Explicit census fixture: 2 RNA and 6 DNA, not a natural playthrough.
    var Ecology = preload("res://src/niche_ecology.gd")
    var Genome = preload("res://src/cell_genome.gd")
    game.ecology = Ecology.origin()
    var lineage: String = str(game.entities[game.player_id].ecotype)
    game.ecological_profiles = {lineage:game.call("_base_traits"),"DNA-02":Genome.grant(game.call("_base_traits"),"dna_stabilization",1,"capture","pre_luca")}
    Ecology.register_birth(game.ecology,lineage,game.player.position,2)
    Ecology.register_birth(game.ecology,"DNA-02",game.player.position,6)
    game.call("_on_statistics")
    await frame("statistics-local")
    for child in game.overlay_list.get_children():
        if child is Button and child.toggle_mode:
            child.button_pressed = true
            break
    await frame("statistics-detail")
    game.call("_close_overlay")
    game.call("_divide_pressed")
    await frame("division-notice")
    print("STATISTICS_RENDERER=",RenderingServer.get_current_rendering_method())
    quit()

func frame(label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = ProjectSettings.globalize_path("res://build/previews/081-"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("SCREENSHOT_GODOT=",path)
