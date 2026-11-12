extends SceneTree
## Verifica reale Godot: vista a volo d'uccello, mesh fondale/venti,
## moto ascendente bolle, vulcani caldi vs fessure innocue e pickup molecolari.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = Vector2i(720,1280)
    var game: Node3D = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var camera: Camera3D = game.camera
    assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
        "Normal gameplay MUST be top-down orthographic")
    assert(camera.position.y > 18.0)
    assert(is_equal_approx(camera.size,game.ISOMETRIC_CAMERA_SIZE))
    var seabed: Node3D = game.world_root.get_node("Fondale_minimale")
    assert(seabed != null)
    var volcanoes: int = 0
    var fissures: int = 0
    var heated_lights: int = 0
    for child in seabed.get_children():
        if child.name == "Camino_vulcanico_minerale":
            volcanoes += 1
        if child.name == "Termico_luce_arancio":
            heated_lights += 1
        if child is MeshInstance3D and child.material_override == seabed.dark_crack:
            fissures += 1
    assert(volcanoes == 2, "Exactly two volcanoes, no visual overcrowding")
    assert(heated_lights == 2, "Two local hazard lights")
    assert(fissures == 4, "Four harmless mineral cracks")
    assert(game._temperature_at(Vector3(-11,0,3)) > 43.0)
    assert(game._temperature_at(Vector3(16,0,-14)) > 43.0)
    assert(game._temperature_at(Vector3(-3.5,0,-3.0)) < 43.0,
        "Gas fissures should be harmless")
    var bubbles: MultiMeshInstance3D = seabed.get_node("Bolle_che_risalgo")
    assert(bubbles != null)
    assert(bubbles.multimesh.instance_count >= 65)
    var before: Vector3 = bubbles.multimesh.get_instance_transform(0).origin
    seabed.call("_process",.7)
    var after: Vector3 = bubbles.multimesh.get_instance_transform(0).origin
    assert(after.y > before.y, "Gas bubbles need actual upward animation")

    game.call("_close_overlay")
    game.call("_update_nutrient_markers")
    var nutrients: OriginiNutrientMarkers = game.nutrient_markers
    assert(nutrients.visible)
    assert(nutrients.markers.size() >= 3)
    for molecule in nutrients.markers:
        assert(is_equal_approx(float(molecule["scale"]),1.10),
            "All nutrient icons must be +10% of previous preview")
    var carbon_count: int = 0
    var phospholipid_count: int = 0
    for n in game.nutrients:
        if str(n["kind"]) == "carbon":
            carbon_count += 1
        if str(n["kind"]) == "lipid":
            phospholipid_count += 1
    assert(carbon_count >= 18 and phospholipid_count >= 18)
    assert(game.cell_world_glyphs.visible,
        "Selected cell must have true top-down phenotype view")
    assert(not game.player.visible,
        "Hide macro 3D mesh in orthographic 2.5D gameplay")
    game.call("_toggle_focus")
    assert(camera.projection == Camera3D.PROJECTION_PERSPECTIVE)
    assert(game.player.visible)
    game.call("_toggle_focus")
    assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL)
    assert(not game.player.visible)
    print("PASS: genuine isometric overhead world; 2 thermal volcanic cones, 4 harmless fissures, %d rising bubble particles and chemical nutrient glyphs +10 percent" % bubbles.multimesh.instance_count)
    quit(0)
