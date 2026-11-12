extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    for fps in [30, 60, 120]:
        game.call("_new_game")
        game.rng.seed = 1024
        # Clear pickups to measure replenishment without collection or the cap.
        for n in game.nutrients:
            n["node"].queue_free()
        game.nutrients.clear()
        game.nutrient_respawn = 0.0
        for frame in range(fps * 4):
            game.call("_respawn_nutrients",1.0/float(fps))
        assert(game.nutrients.size() == 18,
            "Four seconds must replenish 18 pickups at every frame rate")
        assert(is_equal_approx(game.nutrient_respawn,.04))
        game.call("_respawn_nutrients",100.0)
        assert(game.nutrients.size() == 94)
        assert(is_zero_approx(game.nutrient_respawn),"No accumulated burst at the cap")
        var before: int = game.nutrients.size()
        game.call("_respawn_nutrients",-1.0)
        assert(game.nutrients.size() == before)
    print("PASS: nutrient replenishment is identical at 30/60/120 FPS, bounded at 94")
    quit(0)
