extends SceneTree
## Actual game-world render; only camera/HUD and simulation pause are controlled.
## No reference image is loaded by this scene or any runtime material.
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.hud.hide()
    game.overlay.hide()
    game.cells_root.hide()
    game.nutrient_root.hide()
    var camera: Camera3D = game.camera
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.far = 800.0
    camera.size = 23.0
    var target := Vector3(-4,-.5,3)
    camera.position = target+Vector3(7,16,19)
    camera.look_at(target)
    await create_timer(.5).timeout
    await _save("seabed-start")
    target = Vector3(-4,-1,-3)
    camera.size = 11.0
    camera.position = target+Vector3(4,7,9)
    camera.look_at(target)
    await _save("seabed-fault")
    var terrain: Node = game.world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
    var path: PackedVector2Array = terrain.faults[10]
    var point: Vector2 = path[4]
    target = Vector3(point.x,-1,point.y)
    camera.size = 28
    camera.position = target+Vector3(9,19,17)
    camera.look_at(target)
    await _save("seabed-distant")
    camera.size = 510
    camera.position = Vector3(0,420,60)
    camera.look_at(Vector3.ZERO)
    await _save("seabed-map")
    # Real portrait framing and gameplay HUD, with the cell outside the crater.
    root.size = Vector2i(720, 1280)
    root.content_scale_size = Vector2i(720, 1280)
    await process_frame
    game.hud.show()
    game.cells_root.show()
    game.nutrient_root.show()
    game.player.position = Vector3(-8.8, 0, 1.7)
    camera.size = 19.5
    camera.position = game.player.position + Vector3(0, 24, 13)
    camera.look_at(game.player.position + Vector3(0, .55, 0))
    game.call("_layout_ui")
    game.call("_update_nutrient_markers")
    game.call("_update_cell_world_glyphs")
    game.call("_refresh_hud")
    await _save("seabed-gameplay")
    print("SEABED_RENDERER=", RenderingServer.get_current_rendering_method(),
        " DRIVER=", RenderingServer.get_current_rendering_driver_name())
    quit(0)

func _save(label: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var directory: String = ProjectSettings.globalize_path("res://build/previews")
    DirAccess.make_dir_recursive_absolute(directory)
    var path: String = directory + "/" + OS.get_environment("ORIGIN_CAPTURE_PREFIX") + label + ".png"
    var result: Error = root.get_texture().get_image().save_png(path)
    if result != OK:
        push_error("Could not save " + path)
        quit(1)
    print("SCREENSHOT_GODOT=", path)
