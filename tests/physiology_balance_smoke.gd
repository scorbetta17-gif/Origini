extends SceneTree
const PHYS = preload("res://src/cell_physiology.gd")
const P1 = preload("res://src/phase_one_progress.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var basic: Dictionary = {"motility":1.0,"metabolism":1.0,
        "archaella":0,"flagella":0,"pili":0,"attack":1.0,"defense":1.0}
    assert(PHYS.initial_nutrients() == 84)
    assert(PHYS.nutrient_goal() == 94)
    assert(is_equal_approx(PHYS.reserve_cap(24.0),26.88))
    assert(is_equal_approx(PHYS.reserve_cap(65.0),72.8))
    assert(is_equal_approx(PHYS.growth_scale(23,23,65),.72))
    assert(is_equal_approx(PHYS.growth_scale(65,23,65),.864))
    assert(is_equal_approx(PHYS.growth_scale(250,23,65),.864))
    assert(is_equal_approx(PHYS.player_speed(basic),3.40*.78*.90))
    assert(is_equal_approx(PHYS.npc_speed(basic),.90))
    assert(PHYS.motion_cost(2.0,basic) > 0.0)
    var current: Dictionary = PHYS.energy_step(20.0,0.0,2.0,2.0,basic)
    assert(float(current["atp"]) < 20.0)
    assert(float(current["atp"]) > 18.0)
    var zero: Dictionary = PHYS.energy_step(0.0,0.0,14.99,0.0,basic)
    assert(not bool(zero["dead"]))
    var death: Dictionary = PHYS.energy_step(0.0,float(zero["zero_seconds"]),.02,0.0,basic)
    assert(bool(death["dead"]))
    assert(float(PHYS.energy_step(9.0,12.0,.2,0.0,basic)["zero_seconds"]) == 0.0)
    var runner: Dictionary = basic.duplicate(true)
    runner["motility"] = 1.28
    runner["pili"] = 2
    var predator: Dictionary = basic.duplicate(true)
    predator["attack"] = 1.22
    predator["protease"] = 1
    predator["motility"] = .83
    assert(PHYS.strategy(runner) == "esploratore")
    assert(PHYS.strategy(predator) == "predatore")
    assert(PHYS.strategy_speed(predator) < PHYS.strategy_speed(runner))

    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    assert(game.nutrients.size() == 84)
    assert(game.overlay.visible,"First launch MUST show Phase 1 mission board")
    assert(not bool(game.phase1_progress["complete"]))
    assert(game.is_paused)
    game.call("_close_overlay")
    game.call("_create_entity","TEST-NPC","",2,"pre_luca",game.call("_base_traits"),
        Vector3(3.0,0,2.0),false,false)
    var npc: Dictionary = game.entities["TEST-NPC"]
    var node: Node3D = npc["node"]
    var initial: Vector3 = node.position
    npc["intent_velocity"] = Vector3(.9,0,0)
    for i in range(10):
        game.call("_update_npc_motion",.016)
    var covered: float = node.position.distance_to(initial)
    assert(covered > 0.01 and covered < .15,"NPC position should be smoothed every frame")
    assert(float(npc["energy"]) < 46.0,"NPC movement consumes energy")
    game.atp = 0.0
    game.zero_atp_seconds = 14.8
    var motion_before: Vector3 = game.player.position
    game.call("_move_player",Vector2.ZERO,.016)
    assert(game.player.position == motion_before)
    print("PASS: +10% nutrients, -10% unmotorized motion, +20% size cap, +12% reserves, locomotion ATP, 15s starvation, continuous NPC motion and ecotypes")
    quit(0)
