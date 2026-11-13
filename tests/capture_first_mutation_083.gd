extends SceneTree
## Staged, reproducible screenshots rendered by Godot; not human playtest evidence.
func _initialize() -> void: call_deferred("run")
func run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = root.size
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game._layout_ui()
    game._refresh_hud()
    game._update_nutrient_markers()
    await frame("guide")
    game.generation = 1
    game.mutation_points = 2
    game.journey.state.step = "offer"
    game.journey.buy()
    await frame("mutation")
    game.journey.begin_digest()
    game._refresh_hud()
    await frame("detritus")
    game.battle.start(2)
    game.battle.state.elapsed = 180
    game.battle.advance(.01)
    game._update_nutrient_markers()
    game._refresh_hud()
    game._layout_ui()
    await frame("front")
    game.battle.state.elapsed = 1200
    game.battle.advance(0)
    await frame("result")
    print("CAPTURE 083 PASS")
    quit()
func frame(label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = ProjectSettings.globalize_path("res://build/previews/083-"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("SCREENSHOT_GODOT=",path)
