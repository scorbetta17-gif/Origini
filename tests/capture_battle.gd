extends SceneTree
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = root.size
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.battle.start(2)
    game.battle.state.elapsed = 180.0
    game.battle.advance(.01)
    game._refresh_hud()
    game._layout_ui()
    await frame("arena")
    game.battle.dashboard()
    await frame("situation")
    game._close_overlay()
    game.battle.choose()
    await frame("selection")
    print("BATTLE_RENDERER=",RenderingServer.get_current_rendering_method())
    quit()
func frame(label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = ProjectSettings.globalize_path("res://build/previews/082-battle-"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("SCREENSHOT_GODOT=",path)
