extends SceneTree
const PHASE = preload("res://src/phase_one_progress.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var population: Dictionary = {}
    var generations: Array[int] = [0,1,2,3,3,4,4,5,6,7]
    for i in range(generations.size()):
        population["T%d" % i] = {"generation":generations[i],
            "strategy":["raccoglitore","esploratore","difensore","predatore"][i%4]}
    var census: Dictionary = PHASE.population(population)
    assert(census["totale"] == 10)
    assert(census["prime"] == 3)
    assert(census["intermedie"] == 5)
    assert(census["recenti"] == 2)
    assert(is_equal_approx(float(census["prime_pct"])+float(census["intermedie_pct"])+float(census["recenti_pct"]),100.0))
    var mission: Dictionary = PHASE.empty()
    assert(PHASE.mission_lines(mission,census,0).size() == 5)
    mission["player_divisions"] = 6
    mission["autonomous_divisions"] = 3
    mission = PHASE.advance(mission,74.0,6,census,120.0)
    assert(not mission["complete"])
    assert(float(mission["observation_seconds"]) == 74.0)
    mission = PHASE.advance(mission,2.0,6,census,122.0)
    assert(bool(mission["complete"]))
    assert(mission["final_report"]["intermedie_pct"] == 50.0)
    assert(PHASE.report_lines(mission).size() == 5)
    var incomplete: Dictionary = PHASE.empty()
    incomplete["player_divisions"] = 6
    incomplete["autonomous_divisions"] = 2
    incomplete = PHASE.advance(incomplete,100.0,7,census,150.0)
    assert(not bool(incomplete["complete"]))
    assert(float(incomplete["observation_seconds"]) == 0.0)
    incomplete["autonomous_divisions"] = 3
    incomplete = PHASE.advance(incomplete,35.0,7,census,180.0)
    population.erase("T9")
    population.erase("T8")
    incomplete = PHASE.advance(incomplete,1.0,7,PHASE.population(population),181.0)
    assert(float(incomplete["observation_seconds"]) == 0.0)
    assert(not bool(incomplete["complete"]))

    # Real Godot mission transition, not only an isolated pure-state test.
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    assert(game.overlay.visible,"Initial Phase 1 intro must open")
    assert(str(game.phase1_progress.get("intro_seen",false)) == "true")
    game.call("_close_overlay")
    game.phase1_progress["player_divisions"] = 6
    game.phase1_progress["autonomous_divisions"] = 3
    game.generation = 6
    for i in range(9):
        game.call("_create_entity","TEST-C%d" % i,"C-000",i%8,"pre_luca",
            game.call("_base_traits"),Vector3(float(i%5)*2.0,0,float(i/5)*2.0),false,false)
    assert(game.entities.size() == 10)
    game.t = 200.0
    game.call("_advance_phase_one",74.9)
    assert(not bool(game.phase1_progress["complete"]))
    game.call("_advance_phase_one",.2)
    assert(bool(game.phase1_progress["complete"]))
    assert(game.overlay.visible,"Phase 2 intro MUST open after ecological victory")
    assert(bool(game.phase1_progress["phase_two_intro_seen"]))
    assert(int(game.phase1_progress["final_report"]["totale"]) == 10)
    game.call("_close_overlay")
    game.call("_save_game")
    game.call("_load_game")
    assert(bool(game.phase1_progress["complete"]))
    assert(int(game.phase1_progress["final_report"]["totale"]) == 10)
    print("PASS: Phase 1 intro, five missions, 75s competition gate, live cohort percentages, Phase 2 unlock and save/load")
    quit(0)
