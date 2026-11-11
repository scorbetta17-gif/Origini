extends SceneTree
## Integrazione Fase 2: cinque obiettivi, comportamento reale delle risorse,
## scissione ereditaria, genealogia, salvataggio e ripristino.
const PHASE = preload("res://src/phase_two_progress.gd")
const GENES = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_run")

func _make_archaea(game: Node) -> Dictionary:
    var tr: Dictionary = game.call("_base_traits")
    for gene in ["dna_stabilization","archaeal_envelope",
                 "surface_recognition","membrane_transport"]:
        tr = GENES.grant(tr,gene,4,"test_major_mutation","archaea")
    return tr

func _make_bacteria(game: Node) -> Dictionary:
    var tr: Dictionary = game.call("_base_traits")
    for gene in ["dna_stabilization","diderm_envelope",
                 "surface_recognition","membrane_transport"]:
        tr = GENES.grant(tr,gene,4,"independent_test_line","bacteria")
    return tr

func _run() -> void:
    var start: Dictionary = PHASE.empty()
    assert(PHASE.objective_lines(start).size() == 5)
    var low_genes: Dictionary = {"adhesion":true,"transporters":0}
    var donor: Dictionary = {"adhesion":true,"transporters":3}
    var observed: Dictionary = PHASE.observe(start,"bacteria","E-T01",2.0)
    assert(bool(observed["discovered"]))
    observed = PHASE.bind(observed,low_genes,donor,"E-T01",2.0)
    assert(bool(observed["adhesion"]) and bool(observed["bonded"]))
    var test_without_gene: Dictionary = PHASE.advance(observed,30.0,2.0,low_genes,donor,20.0,80.0)
    assert(not bool(test_without_gene["progress"]["exchanged"]))
    var ready: Dictionary = {"adhesion":true,"transporters":3}
    observed = PHASE.bind(observed,ready,donor,"E-T01",2.0)
    var first: Dictionary = PHASE.advance(observed,11.0,2.0,ready,donor,20.0,80.0)
    assert(not bool(first["progress"]["exchanged"]))
    var second: Dictionary = PHASE.advance(first["progress"],14.0,2.0,ready,donor,18.0,79.0)
    assert(bool(second["progress"]["exchanged"]))
    assert(bool(second["progress"]["stable"]))
    var missing: Dictionary = PHASE.inherit(second["progress"],low_genes,true,"A",8)
    assert(not bool(missing["complete"]))
    var inherited: Dictionary = PHASE.inherit(second["progress"],ready,true,"A",8)
    assert(bool(inherited["transmitted"]) and bool(inherited["complete"]))
    assert(str(inherited["transmitted_from"]) == "A")
    var broken: Dictionary = PHASE.advance(PHASE.bind(start,ready,donor,"B",2.0),
        20.0,100.0,ready,donor,20.0,80.0)
    assert(not bool(broken["progress"]["bonded"]))
    assert(not bool(broken["progress"]["stable"]))

    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.call("_create_entity","TEST-A","",4,"archaea",_make_archaea(game),Vector3.ZERO,false,true)
    game.call("_activate_lineage","TEST-A")
    assert(game.player_id == "TEST-A")
    game.call("_create_entity","TEST-B","",0,"bacteria",_make_bacteria(game),Vector3(2.3,0,0),false,true)
    game.call("_advance_phase_two",.10)
    assert(bool(game.phase2_progress["discovered"]))
    game.call("_on_cooperate")
    assert(game.partner_id == "TEST-B")
    assert(bool(game.phase2_progress["adhesion"]))
    game.resources["carbon"] = 24.0
    game.resources["amino"] = 15.0
    game.resources["lipid"] = 12.0
    game.resources["nucleic"] = 8.0
    game.resources["biomass"] = 65.0
    game.atp = 99.0
    for i in range(30):
        game.call("_advance_phase_two",1.0)
    assert(bool(game.phase2_progress["exchanged"]))
    assert(bool(game.phase2_progress["stable"]))
    assert(float(game.phase2_progress["metabolites_exchanged"]) > 0.0)
    assert(float(game.resources["carbon"]) < 24.0)
    game.call("_divide_pressed")
    assert(game.division_options.size() == 2)
    game.call("_choose_daughter",0)
    assert(bool(game.phase2_progress["transmitted"]))
    assert(bool(game.phase2_progress["complete"]))
    assert(game.partner_id == "TEST-B")
    assert(int(game.generation) == 5)
    assert(game.entities.size() >= 3)
    game.call("_save_game")
    game.call("_load_game")
    assert(bool(game.phase2_progress["complete"]))
    assert(game.partner_id == "TEST-B")
    assert(game.entities.has(game.player_id))
    assert(game.genealogy.size() >= 5)
    print("PASS: entire Phase 2 — bacteria recognition, adhesion, reciprocal transfer 12s, stable contact 25s, daughter inheritance and save/load")
    quit(0)
