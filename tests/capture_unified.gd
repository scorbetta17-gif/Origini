extends SceneTree
var game: Node
func _initialize() -> void:
    call_deferred("_run")
func _shot(file: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/previews/"+OS.get_environment("ORIGIN_CAPTURE_PREFIX")+file+".png")
func _run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = root.size
    game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game._close_overlay()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
    await _shot("unified-gameplay")
    game._on_evolution()
    await _shot("unified-capabilities")
    game._close_overlay()
    game.mutation_points = 12.75
    game._on_tree()
    game.tree_view.focus_node(288)
    await _shot("unified-specializations")
    game._close_overlay()
    game.hud.hide()
    game.nutrient_root.hide()
    game.camera.size = 4.8
    game.camera.position = Vector3(0,3.2,4)
    game.camera.look_at(Vector3(0,.65,0))
    game.player.set_division_progress(.82)
    await _shot("unified-fission")
    var traits: Dictionary = game._base_traits()
    traits = game.GenomeScript.grant(traits,"dna_stabilization",60,"capture","archaea")
    traits["evolution_capabilities"] = {}
    for entry in game.Evolution.catalogue():
        traits.evolution_capabilities[entry.id] = true
    game.player.setup(traits,"archaea",true)
    await _shot("unified-eukaryote")
    print("RENDERER="+RenderingServer.get_current_rendering_method()+" DRIVER="+RenderingServer.get_current_rendering_driver_name())
    print("PASS unified capture")
    quit()
