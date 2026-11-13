extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.rng.seed = 6012
    game._new_game()
    assert(not game.overlay.visible and game.journey.state.step=="gather")
    # Real collection and physiology; no nutrient, age or point grants.
    for tick in range(9000):
        if game._can_divide(): break
        var target: Vector3 = game.player.position
        var best: float = INF
        for n in game.nutrients:
            var useful: bool = game.resources.biomass<game.NEED.biomass or game.atp<65 or (n.kind in game.TYPES and game.resources[n.kind]<game.NEED[n.kind])
            var d: float = n.node.position.distance_to(game.player.position)
            if useful and game._temperature_at(n.node.position)<40 and d<best:
                best = d
                target = n.node.position
        var offset: Vector3 = target-game.player.position
        game.move_vector = Vector2(offset.x,offset.z).normalized()
        game._process(.07)
        if tick%100==0: await process_frame
    assert(game._can_divide())
    game.move_vector = Vector2.ZERO
    game._divide_pressed()
    await create_timer(2.7).timeout
    assert(game.generation==1 and game.journey.state.step=="offer")
    var points: float = game.mutation_points
    game.journey.buy()
    assert(game.purchased.has("88") and game.mutation_points==points-2)
    assert(game.GenomeScript.has(game.entities[game.player_id].traits,"hydrolase_secretion"))
    assert(game.journey.state.step=="comparison" and game.overlay_list.get_child_count()>=3)
    game._save_game("user://journey.json")
    game._load_game("user://journey.json")
    assert(game.journey.state.step=="comparison")
    game.journey.buy() # Duplicate purchase is rejected by existing tree validator.
    assert(game.mutation_points==points-2)
    game.journey.begin_digest()
    assert(Vector2(game.journey.target.position.x-game.player.position.x,game.journey.target.position.z-game.player.position.z).length()<=3.5)
    game._on_skill("enzyme")
    for tick in range(300):
        game._process(.07)
        if game.statistics.substrates>0: break
        if tick%30==0: await process_frame
    assert(game.statistics.substrates==1 and game.journey.state.step=="explain")
    game._on_tree()
    assert(game.journey.state.step=="done")
    game._close_overlay()
    game._save_game("user://legacy.json")
    var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://legacy.json"))
    raw.erase("journey")
    var file := FileAccess.open("user://legacy.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(raw)); file.close()
    game._new_game()
    game._load_game("user://legacy.json")
    assert(game.generation==1 and game.journey.state.step=="done")
    game._new_game()
    game.journey.skip()
    game._save_game("user://skip.json")
    game._load_game("user://skip.json")
    assert(game.journey.state.step=="skipped" and not game.journey.active())
    assert(game._temperature_at(Vector3(0,0,5))<40)
    var hot: float = game._temperature_at(Vector3(18.5,0,-14))
    assert(hot>43 and hot<43+18*1.5)
    assert(game.entities.has("MAT-00") and game.entities.has("MAT-02"))
    assert(game.habitats.CENTERS[1].length()/game.Physiology.player_speed(game._base_traits())<15)
    game.battle.start(0)
    assert(game.entities.size()==13 and not game.journey.active())
    print("PASS: real first fission, single enzyme charge, 3D comparison, digestion, resume, skip, legacy and three reachable habitats")
    game.queue_free()
    quit()
