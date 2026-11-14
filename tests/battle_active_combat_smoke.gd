extends SceneTree
const S=preload("res://src/battle_scoring.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var g=load("res://scenes/Main.tscn").instantiate()
    root.add_child(g);await process_frame;g.set_process(false);g.battle.start(0)
    var b: Node=g.battle
    var id: String=g.player_id
    assert(S.front(b.state,id,1,"refugio anticipato"))
    assert(S.breakdown(b.state,id,100,100).objectives==2)
    assert(S.front(b.state,id,1,"deposito appena attivato"))
    assert(not S.front(b.state,id,1,"attraversamento con alleato"))
    assert(S.breakdown(b.state,id,100,100).objectives==5)
    var target: String="BR-001"
    g.player.position=Vector3.ZERO;g.entities[target].node.position=Vector3(1,0,0)
    var before: float=g.entities[target].hp
    assert(b.combat.request(b,id,target))
    b.combat.advance(b,.3);assert(g.entities[target].hp==before)
    g._save_game();g._load_game(b.PATH)
    assert(b.combat.busy(b,id) and S.breakdown(b.state,id,100,100).objectives==5)
    g.entities[target].node.position=Vector3(4,0,0)
    b.combat.advance(b,.5)
    assert(g.entities[target].hp==before and not b.state.damage.has(target))
    assert(b.state.combat_metrics.misses==1)
    g.entities[target].node.position=Vector3(1,0,0)
    g.entities[target].energy=80
    assert(b.combat.request(b,target,id))
    var hp: float=g.hp
    b.combat.advance(b,.71)
    assert(g.hp<hp and b.state.damage.has(id))
    b.combat.advance(b,2)
    assert(not b.combat.busy(b,id))
    # Contact at safe depot never qualifies; contested depot needs actual intake.
    b.start(2);id=g.player_id;b.state.elapsed=240
    g.player.position=b.rules.depot(240,1);b.advance(.01)
    assert(S.account(b.state,id).active.is_empty())
    for key in g.NEED: g.resources[key]=g.Physiology.reserve_cap(g.RESERVE_BASE[key])
    g.atp=100;g.player.position=b.rules.depot(240,0);b.advance(4.1)
    assert(S.account(b.state,id).active.is_empty())
    g.resources.carbon=20;b.advance(4.1)
    assert(S.account(b.state,id).active.size()==1)
    g._save_game();g._load_game(b.PATH);b.advance(4.1)
    assert(S.account(b.state,id).active.size()==1)
    print("PASS: 2+3 front quotas, full-reserve exclusion, persisted windup, dodge miss no credit, recovery counterattack, load no double bonus")
    g.queue_free();quit()
