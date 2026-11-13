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
    assert(PHASE.report_lines(mission).size() >= 9)
    assert(int(mission["observation_start"]["totale"]) == 10)
    assert(is_equal_approx(float(mission["final_report"]["intermedie_pct"]) - float(mission["observation_start"]["intermedie_pct"]),0.0))
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
    assert(incomplete["observation_start"].is_empty())
    assert(not bool(incomplete["complete"]))

    var restored: Dictionary = PHASE.normalize(JSON.parse_string(JSON.stringify(mission)))
    assert(restored["complete"] and restored["final_report"]["totale"]==10)
    print("PASS: legacy phase-one mission state, census, competition boundaries and migration serialization")
    quit(0)
