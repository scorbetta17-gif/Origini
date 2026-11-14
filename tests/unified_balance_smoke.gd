extends SceneTree
const B = preload("res://src/mutation_balance.gd")
const TREE = preload("res://src/mutation_tree.gd")

func _initialize() -> void:
    var base: Dictionary = B.normalize({})
    assert(base.mutation==0.0 and base.vitality==1.0)
    assert(B.points_multiplier(base)==1.0)
    var first: Dictionary = B.tree_effect(base,"attack",false)
    assert(first.attack>1.0 and first.uptake<1.0 and first.metabolism<1.0)
    var forward: Dictionary = base
    var reverse: Dictionary = base
    var order: Array = ["motility","attack","defense","vitality","mutation","metabolism","uptake"]
    for stat in order:
        forward=B.tree_effect(forward,stat,true)
    order.reverse()
    for stat in order:
        reverse=B.tree_effect(reverse,stat,true)
    for stat in B.CAPS:
        assert(is_equal_approx(float(forward[stat]),float(reverse[stat])),"Order changes phenotype")
    assert(not base.has("balance_investments"),"Input mutated")
    var legacy: Dictionary = {"defense":1.85,"metabolism":1.8,"mutation":.35,"flagella":2,"genome":{"version":1}}
    var normalized: Dictionary = B.normalize(legacy)
    for key in legacy:
        assert(normalized[key]==legacy[key],"Legacy value changed")
    var migrated: Dictionary = B.tree_effect(normalized,"motility",false)
    assert(migrated.balance_baseline.defense==1.85 and migrated.flagella==2)
    assert(B.normalize(B.normalize(migrated))==B.normalize(migrated))
    var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(migrated))
    var resumed: Dictionary = B.tree_effect(roundtrip,"attack",false)
    var direct: Dictionary = B.tree_effect(migrated,"attack",false)
    for stat in B.CAPS:
        assert(is_equal_approx(float(resumed[stat]),float(direct[stat])))
    for i in range(1000):
        forward=B.tree_effect(forward,order[i%order.size()],false)
    for stat in B.CAPS:
        assert(float(forward[stat])<=float(B.CAPS[stat])+.00001)
        assert(float(forward[stat])>=float(B.FLOORS[stat])-.00001)
    assert(B.points_multiplier({"mutation":-100})==1.0)
    assert(B.points_multiplier({"mutation":100})==1.5)
    assert(B.division_credit({}).points==4)
    assert(B.division_credit({"mutation":.5}).points==6)
    var carry: float = 0.0
    var earned: int = 0
    for i in range(10):
        var credit: Dictionary = B.division_credit({"mutation":.125},carry)
        earned+=int(credit.points)
        carry=float(credit.remainder)
    assert(earned==45 and is_equal_approx(carry,0))
    var rng := RandomNumberGenerator.new()
    rng.seed=20261113
    for budget in [10,30,60,120,240,1000]:
        for sample in range(50):
            var traits: Dictionary = B.normalize({})
            for purchase in range(budget):
                traits=B.tree_effect(traits,order[rng.randi_range(0,6)],false)
            var positive: float = 0.0
            for stat in B.CAPS:
                if stat!="mutation": positive+=maxf(0.0,float(traits[stat])-1.0)
            assert(positive<=B.POSITIVE_GAIN_BUDGET+.000001)
    var tree: Control = TREE.new()
    tree.configure({},20,base,1)
    assert(tree.STATS.size()==7 and tree.NODE_COUNT==336)
    assert(tree.STATS[6]=="vitality" and tree.major_locus(328)=="chaperone_complex")
    assert(tree.major_locus(88)=="hydrolase_secretion")
    assert(tree.call("_available",288) and not tree.call("_available",336))
    assert(tree.preview_changes(288).size()>=3)
    tree.focus_node(335)
    assert(tree.inspected==335)
    tree.free()
    print("PASS: unified balance order independence, real tradeoffs, legacy preservation, JSON carry, bounds, division fractional credit")
    quit()
