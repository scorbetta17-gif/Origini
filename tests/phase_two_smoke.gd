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
    assert(bool(second["progress"]["active_stable"]))
    var stale_bond: Dictionary = PHASE.bind(second["progress"],ready,donor,"NEW",2.0)
    assert(not bool(stale_bond["active_stable"]))
    assert(not bool(PHASE.inherit(stale_bond,ready,true,"A",8)["complete"]))
    var missing: Dictionary = PHASE.inherit(second["progress"],low_genes,true,"A",8)
    assert(not bool(missing["complete"]))
    var inherited: Dictionary = PHASE.inherit(second["progress"],ready,true,"A",8)
    assert(bool(inherited["transmitted"]) and bool(inherited["complete"]))
    assert(str(inherited["transmitted_from"]) == "A")
    var broken: Dictionary = PHASE.advance(PHASE.bind(start,ready,donor,"B",2.0),
        20.0,100.0,ready,donor,20.0,80.0)
    assert(not bool(broken["progress"]["bonded"]))
    assert(not bool(broken["progress"]["stable"]))

    var restored: Dictionary = PHASE.normalize(JSON.parse_string(JSON.stringify(inherited)))
    assert(restored["complete"] and restored["transmitted"])
    print("PASS: legacy phase-two exchange, binding, inheritance and migration serialization")
    quit(0)
