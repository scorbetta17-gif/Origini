extends SceneTree
## Verify classic portrait UX is built by Godot as functional Controls.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(720,1280)
    root.content_scale_size = Vector2i(720,1280)
    var packed: PackedScene = load("res://scenes/Main.tscn")
    assert(packed != null)
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
    if viewport_size.y <= viewport_size.x:
        push_error("Portrait viewport not available: "+str(viewport_size))
        quit(1)
        return
    var classic: OriginiClassicHud = game.get("classic_hud")
    assert(classic != null and classic.visible)
    assert(classic.size.x > 0 and classic.size.y > 0)
    for key in ["nutrients","tree","goals","genealogy","divide","regen","cooperate","focus","enzymes","lysis","menu"]:
        assert(game.buttons.has(key),"Missing classic action "+str(key))
        if key not in ["regen","cooperate","enzymes","lysis"]:
            assert(game.buttons[key].visible,"Classic button hidden: "+str(key))
        else:
            assert(not game.buttons[key].visible,"New campaign must introduce actions progressively")
        assert(game.buttons[key].size.x >= 80,"Classic action too small: "+str(key))
    var divide_rect: Rect2 = game.buttons["divide"].get_rect()
    var joystick_rect: Rect2 = game.joystick.get_rect()
    assert(not divide_rect.intersects(joystick_rect),"Joystick overlaps division CTA")
    assert(divide_rect.position.y > viewport_size.y*.69)
    var tab_rect: Rect2 = game.buttons["nutrients"].get_rect()
    assert(tab_rect.position.y > 0 and tab_rect.position.y < viewport_size.y*.45)
    assert(tab_rect.position.y+tab_rect.size.y < divide_rect.position.y)
    game.call("_update_nutrient_markers")
    assert(game.nutrient_markers != null)
    var visible_marker_count: int = game.nutrient_markers.markers.size()
    print("PORTRAIT_VISIBLE_NUTRIENTS=",visible_marker_count)
    assert(visible_marker_count >= 3, "Initial gameplay must have visible chemical nutrient symbols")
    var silhouettes: OriginiCellWorldGlyphs = game.get("cell_world_glyphs")
    assert(silhouettes != null and not silhouettes.visible)
    assert(game.player.visible,"True 3D cell must render in portrait gameplay")
    assert(game.player.find_child("BlenderCellCore",true,false) != null)
    game.call("_toggle_focus")
    assert(game.player.visible and not silhouettes.visible)
    game.call("_toggle_focus")
    assert(game.player.visible and not silhouettes.visible)

    game.call("_on_resources")
    assert(game.overlay.visible)
    game.call("_close_overlay")
    var required: Dictionary = {"carbon":24.0,"amino":15.0,"lipid":12.0,"nucleic":8.0,"biomass":65.0}
    for k in required:
        game.resources[k] = required[k]
    game.atp = 96.0
    game.cycle_age = 75.0
    game.set_process(false)
    game.call("_divide_pressed")
    assert(game.division_options.size() == 2)
    assert(not game.overlay.visible,"Fission must not open random daughter cards")
    game.buttons["tree"].pressed.emit()
    game.buttons["menu"].pressed.emit()
    assert(not game.overlay.visible and game.division_active,"HUD actions cannot interrupt fission")
    await create_timer(2.7).timeout
    assert(game.division_options.is_empty() and game.generation==1)
    assert(game.entities.has(game.player_id))
    game.call("_on_tree")
    assert(game.tree_view != null)
    assert(game.tree_view.zoom_level > 0)
    game.tree_view.zoom_by(1.2)
    assert(game.tree_view.zoom_level > .9)
    game.tree_view.center_view()
    game.call("_close_overlay")
    game.call("_on_genealogy")
    assert(game.lineage_view != null)
    game.call("_close_overlay")
    game.call("_refresh_hud")
    assert(classic.state.has("carbon") and classic.state.has("fission"))
    print("PASS: Classic portrait HUD with actual 3D phenotype in gameplay and close-up, tabs, resources, joystick/fission CTA, automatic inherited daughter transition, mutation zoom and genealogy")
    quit(0)
