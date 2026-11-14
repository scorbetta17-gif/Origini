extends SceneTree
const G = preload("res://src/cell_genome.gd")
var game: Node

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1000,800)
    root.content_scale_size = root.size
    game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.journey.skip()
    for label in game.find_children("*","Label3D",true,false): label.hide()
    game.hud.hide()
    game.overlay.hide()
    game.nutrient_root.hide()
    var camera: Camera3D = game.camera
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.5
    game.player.position = Vector3(0,0,0)
    camera.position = Vector3(0,3.2,4.0)
    camera.look_at(Vector3(0,.65,0))
    await create_timer(.3).timeout
    await _save("cell-rna")
    var dna: Dictionary = G.grant(game.call("_base_traits"),"dna_stabilization",1,"capture","pre_luca")
    game.player.setup(dna,"pre_luca",true)
    await _save("cell-dna")
    var advanced: Dictionary = dna.duplicate(true)
    for locus in ["membrane_transport","surface_recognition","pili_twitch","hydrolase_secretion",
            "vesicle_pathway","eps_biosynthesis","thermal_membrane","chaperone_complex",
            "cell_elongation","diderm_envelope","flagellar_motor"]:
        advanced = G.grant(advanced,locus,8,"capture","bacteria")
    game.player.setup(advanced,"bacteria",true)
    camera.size = 5.5
    camera.position = Vector3(-.6,3.2,4.0)
    camera.look_at(Vector3(-.6,.65,0))
    await _save("cell-evolved")
    # Real portrait gameplay with real cell meshes (no phenotype overlay).
    game.player.setup(game.call("_base_traits"),"pre_luca",true)
    root.size = Vector2i(720,1280)
    root.content_scale_size = root.size
    await process_frame
    camera.size = 19.5
    camera.position = Vector3(0,24,13)
    camera.look_at(Vector3(0,.55,0))
    game.hud.show()
    game.nutrient_root.show()
    game.call("_layout_ui")
    game.call("_update_nutrient_markers")
    game.call("_refresh_hud")
    await _save("cell-gameplay-3d")
    # Optional authentic frame sequence, exercised through the real movement path.
    if OS.get_environment("ORIGIN_CELL_MOTION") == "1":
        game.hud.hide()
        game.nutrient_root.hide()
        root.size = Vector2i(640,640)
        root.content_scale_size = root.size
        camera.size = 3.4
        game.player.set_process(false)
        var motion: Node = game.player.get_node("FluidMotion")
        motion.set_process(false)
        for i in range(90):
            var angle: float = float(i)*TAU/90.0
            var direction := Vector2(cos(angle),sin(angle))
            var previous: Vector3 = game.player.position
            game.call("_move_player",direction,1.0/30.0)
            game.player.call("_process",1.0/30.0)
            motion.advance_motion((game.player.position-previous)*30.0,1.0/30.0)
            camera.position = game.player.position+Vector3(0,3.2,4)
            camera.look_at(game.player.position+Vector3(0,.65,0))
            await _save("motion/cell-%03d" % i)
    print("CELL_RENDERER=",RenderingServer.get_current_rendering_method()," DRIVER=",RenderingServer.get_current_rendering_driver_name())
    quit(0)

func _save(label: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = ProjectSettings.globalize_path("res://build/previews/")+OS.get_environment("ORIGIN_CAPTURE_PREFIX")+label+".png"
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("SCREENSHOT_GODOT=",path)
