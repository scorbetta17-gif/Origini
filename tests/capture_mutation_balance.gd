extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    root.size=Vector2i(720,1280)
    root.content_scale_size=root.size
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    game.generation=1
    game.mutation_points=2
    game.call("_on_tree")
    game.tree_view.focus_node(88)
    await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
    root.get_texture().get_image().save_png("res://build/previews/mutation-tree.png")
    game.call("_close_overlay")
    game.hud.hide()
    game.nutrient_root.hide()
    var patch = game.substrates[0]
    game.camera.size=7.0
    game.camera.position=patch.position+Vector3(0,8,5)
    game.camera.look_at(patch.position)
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/previews/organic-substrate.png")
    print("PASS: authentic mutation and substrate captures")
    quit()
