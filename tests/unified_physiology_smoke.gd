extends SceneTree
const P = preload("res://src/cell_physiology.gd")
const B = preload("res://src/mutation_balance.gd")
const E = preload("res://src/evolution_progress.gd")

func _initialize() -> void:
    var motor: Dictionary = {"flagella":1,"motility":B.CAPS.motility}
    assert(is_equal_approx(P.player_speed(motor),P.PLAYER_BASE_SPEED*float(B.CAPS.motility)))
    assert(is_equal_approx(P.player_speed(motor,true),P.player_speed(motor)*P.ATTACHED_SPEED_FACTOR))
    assert(is_equal_approx(P.npc_speed(motor,true),P.npc_speed(motor)*P.ATTACHED_SPEED_FACTOR))
    assert(motor.flagella==1 and not motor.has("anchored"))
    assert(P.player_speed({"motility":-50})>0)
    assert(P.motion_cost(10,{"metabolism":10000})>0)
    assert(P.complexity_upkeep({})==0.0)
    assert(P.complexity_upkeep({"evolution_capabilities":{"cell_zero":true,"mitochondrion":false,"unknown":true}})==0.0)
    var internal: Dictionary = {"evolution_capabilities":{"internal_symbiont":true}}
    assert(P.energy_yield_multiplier(internal)==1.0)
    assert(P.complexity_upkeep(internal)>0.0)
    var mature: Dictionary = {"evolution_capabilities":{"mitochondrion":true}}
    assert(is_equal_approx(P.energy_yield_multiplier(mature),1.15))
    var capabilities: Dictionary = {}
    for entry in E.catalogue():
        capabilities[entry.id]=true
    var complex: Dictionary = {"evolution_capabilities":capabilities}
    assert(is_equal_approx(P.complexity_upkeep(complex),P.MAX_COMPLEXITY_UPKEEP))
    var base_energy: Dictionary = P.energy_step(30,0,10,0,{})
    var complex_energy: Dictionary = P.energy_step(30,0,10,0,complex)
    assert(is_equal_approx(float(base_energy.atp)-float(complex_energy.atp),.6))
    assert(is_equal_approx(P.npc_energy_step(30,10,0)-P.npc_energy_step(30,10,0,complex),.6))
    assert(P.energy_step(0,14.9,.2,0,{}).dead)
    assert(not P.energy_step(20,14.9,.2,0,{}).dead)
    print("PASS: physiology caps, attachment state, nonfree motion, active complexity upkeep, functional-only organelle yield, ATP death")
    quit()
