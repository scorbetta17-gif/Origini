extends SceneTree
const E = preload("res://src/evolution_progress.gd")

func _initialize() -> void:
    var state: Dictionary = E.origin()
    assert(E.normalize(E.normalize({})) == E.normalize({}))
    assert(not E.can_unlock(state,"leca"))
    assert(not E.can_unlock(state,"unknown"))
    assert(E.unlock(state,"leca") == state)
    assert(not E.origin().has("points"),"Wallet belongs to main")
    var legacy: Dictionary = E.normalize({"complete":true,"stable":true,"transmitted":true,"other":{"value":7}})
    assert(not legacy.unlocks.has("internal_symbiont"))
    assert(legacy.other.value == 7 and E.normalize(legacy) == legacy)
    var ids: Dictionary = {}
    for entry in E.catalogue():
        assert(not ids.has(entry.id))
        for requirement in entry.requires:
            assert(ids.has(requirement),"Catalogue is topologically ordered")
        ids[entry.id] = true
        assert(entry.has("confidence") and entry.has("description"))
    var context: Dictionary = {"external_partner_alive":true,"partner_id":"donor_a", "partner_branch":"bacteria","exchange_active":true,
        "internal_transmitted":true,"protein_import":true,"metabolic_integration":true,"coordinated_division":true,
        "membrane_traffic_functional":true,"nuclear_transport_functional":true}
    var first_leca: int = -1
    for generation in range(1,81):
        context["division_id"] = "division_%d" % generation
        state = E.on_division(state,context)
        assert(E.on_division(state,context) == state,"Duplicate delivery is idempotent")
        for entry in E.catalogue():
            if entry.id in ["bacteria","alpha_partner","prokaryotic_groups","differentiated_groups"]:
                continue
            if E.can_unlock(state,entry.id,{},context):
                state = E.unlock(state,entry.id)
        if bool(state.unlocks.get("leca",false)) and first_leca == -1:
            first_leca = generation
    assert(first_leca >= 60 and first_leca <= 80,"Archaeal eukaryotic route reachable independently")
    assert(E.status(state).complete)
    assert(not state.unlocks.has("bacteria") and not state.unlocks.has("alpha_partner"))
    assert(not E.can_unlock(state,"bacteria"))
    var before: Dictionary = E.origin()
    before.divisions = 80
    before.unlocks = {"cell_zero":true,"rna_inheritance":true,"translation":true,"dna_archive":true,"bioenergetics":true,"luca":true,"bacteria":true}
    assert(E.can_unlock(before,"alpha_partner"))
    assert(not E.can_unlock(before,"archaea"))
    assert(not E.can_unlock(before,"asgard_host"))
    var host: Dictionary = state.duplicate(true)
    host.unlocks.erase("stable_consortium")
    host.unlocks.erase("internal_symbiont")
    host.stability.external = 6
    assert(not E.can_unlock(host,"stable_consortium",{}, {"external_partner_alive":false}))
    host = E.on_division(host,{"division_id":"loss"})
    assert(host.stability.external == 0 and host.stability.internal == 0 and host.stability.leca == 0)
    assert(not E.can_unlock(host,"stable_consortium"))
    var switched: Dictionary = state.duplicate(true)
    context["partner_id"] = "different_partner"
    context["division_id"] = "switch"
    switched = E.on_division(switched,context)
    assert(switched.stability.external == 1,"Different partners cannot pool stability")
    print("PASS: evolution DAG, independent branches, 60+ divisions, evidence gates, no idle progress, duplicate event and legacy normalization")
    quit(0)
