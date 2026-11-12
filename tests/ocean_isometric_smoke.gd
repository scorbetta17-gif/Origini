extends SceneTree
## Verifica reale Godot: vista a volo d'uccello, mesh fondale/venti,
## moto ascendente bolle, vulcani caldi vs fessure innocue e pickup molecolari.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = Vector2i(720,1280)
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var camera: Camera3D = game.get("camera")
    assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
        "Normal gameplay MUST be top-down orthographic")
    assert(camera.position.y > 18.0)
    assert(is_equal_approx(camera.size,19.5))
    var world: Node3D = game.get("world_root")
    var seabed: Node3D = world.get_node("Fondale_minimale")
    assert(seabed != null)
    var volcanoes: int = 0
    var fissures: int = 0
    var heated_lights: int = 0
    for child in seabed.get_children():
        if child.is_in_group("primordial_volcano"):
            volcanoes += 1
        if child.is_in_group("thermal_source"):
            heated_lights += 1
        if child.is_in_group("harmless_gas_fissure"):
            fissures += 1
    print("GEOMETRY volcanic=%d hot_lights=%d inert_fissures=%d" % [volcanoes,heated_lights,fissures])
    assert(volcanoes == 2, "Exactly two volcanoes, no visual overcrowding")
    assert(heated_lights == 2, "Two local hazard lights")
    assert(fissures == 4, "Four harmless mineral cracks")
    assert(game.call("_temperature_at",Vector3(-11,0,3)) > 43.0)
    assert(game.call("_temperature_at",Vector3(16,0,-14)) > 43.0)
    assert(game.call("_temperature_at",Vector3(-3.5,0,-3.0)) < 43.0,
        "Gas fissures should be harmless")
    var bubbles: MultiMeshInstance3D = seabed.get_node("Bolle_che_risalgo")
    assert(bubbles != null)
    assert(bubbles.multimesh.instance_count >= 65)
    var before: Vector3 = bubbles.multimesh.get_instance_transform(0).origin
    var t_before: float = float(seabed.get("bubble_time"))
    seabed.call("_process",.7)
    var after: Vector3 = bubbles.multimesh.get_instance_transform(0).origin
    var t_after: float = float(seabed.get("bubble_time"))
    print("BUBBLE_DYNAMICS before=",before," after=",after," t=",t_before," -> ",t_after)
    if t_after <= t_before or after.y <= before.y+.00001:
        push_error("Hydrothermal 3D particle animation is not ascending")
        quit(1)
        return

    game.call("_close_overlay")
    game.call("_update_nutrient_markers")
    var nutrients: OriginiNutrientMarkers = game.get("nutrient_markers")
    assert(nutrients.visible)
    assert(nutrients.markers.size() >= 3)
    for molecule in nutrients.markers:
        assert(is_equal_approx(float(molecule["scale"]),1.10),
            "All nutrient icons must be +10% of previous preview")
    var carbon_count: int = 0
    var phospholipid_count: int = 0
    for n in game.get("nutrients"):
        if str(n["kind"]) == "carbon":
            carbon_count += 1
        if str(n["kind"]) == "lipid":
            phospholipid_count += 1
    assert(carbon_count >= 18 and phospholipid_count >= 18)
    var glyphs: OriginiCellWorldGlyphs = game.get("cell_world_glyphs")
    var player: Node3D = game.get("player")
    assert(glyphs.visible,
        "Selected cell must have true top-down phenotype view")
    assert(not player.visible,
        "Hide macro 3D mesh in orthographic 2.5D gameplay")
    game.call("_toggle_focus")
    assert(camera.projection == Camera3D.PROJECTION_PERSPECTIVE)
    assert(player.visible)
    game.call("_toggle_focus")
    assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL)
    assert(not game.player.visible)
    print("PASS: genuine isometric overhead world; 2 thermal volcanic cones, 4 harmless fissures, %d rising bubble particles and chemical nutrient glyphs +10 percent" % bubbles.multimesh.instance_count)
    quit(0)
