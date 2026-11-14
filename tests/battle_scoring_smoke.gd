extends SceneTree
const Score = preload("res://src/battle_scoring.gd")
const Rules = preload("res://src/battle_rules.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var state: Dictionary = Rules.origin()
    state.front_version=1 # Existing arena keeps the 0.83 single quota.
    Score.initialize(state)
    var full: Dictionary = {"carbon":26.88,"amino":16.8,"lipid":13.44,"nucleic":8.96,"biomass":72.8,"atp":100}
    assert(Score.intake(state,"A",full,full)==0)
    assert(Score.intake(state,"A",{}, {"carbon":2,"amino":3,"biomass":50,"atp":100})==5)
    state.elapsed = 50
    Score.hit(state,"victim","B",15)
    Score.hit(state,"victim","A",15)
    Score.hit(state,"victim","C",3)
    assert(Score.death(state,"victim")=="A")
    assert(Score.death(state,"victim")=="A" and Score.account(state,"A").kills.size()==1)
    assert(Score.death(state,"environment")=="")
    Score.hit(state,"expired","B",99)
    state.elapsed = 80.01
    assert(Score.death(state,"expired")=="")
    assert(Score.front(state,"A",1,"refugio anticipato"))
    assert(not Score.front(state,"A",1,"deposito appena attivato"))
    assert(Rules.valid(JSON.parse_string(JSON.stringify(state))))
    var bad: Dictionary = state.duplicate(true)
    bad.nutrition_target = 0
    assert(not Rules.valid(bad))
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.battle.start(2)
    var id: String = game.player_id
    for key in game.NEED: game.resources[key] = game.Physiology.reserve_cap(game.RESERVE_BASE[key])
    game._award_bundle({"carbon":200,"amino":100,"atp":30,"biomass":100},true)
    assert(Score.account(game.battle.state,id).absorbed==0)
    game.resources.carbon -= 1.0
    game._award_bundle({"carbon":200,"biomass":100},true)
    assert(is_equal_approx(Score.account(game.battle.state,id).absorbed,1.0))
    game._create_nutrient("carbon",game.player.position)
    game._consume_nutrient(game.nutrients.size()-1,true)
    assert(is_equal_approx(Score.account(game.battle.state,id).absorbed,1.0))
    var npc: String = "BR-001"
    for key in game.NEED: game.entities[npc].resources[key] = game.Physiology.reserve_cap(game.RESERVE_BASE[key])
    game._award_bundle({"carbon":99,"atp":100},false,npc)
    assert(Score.account(game.battle.state,npc).absorbed==0)
    game.entities[npc].resources.carbon -= 1.0
    game._create_nutrient("carbon",game.entities[npc].node.position)
    game._consume_nutrient(game.nutrients.size()-1,false,npc)
    assert(is_equal_approx(Score.account(game.battle.state,npc).absorbed,1.0))
    game.battle.state.elapsed = 160
    game.battle.record_hit(npc,id,25)
    game.battle.record_hit(npc,"BR-002",40)
    game.battle.advance(.01)
    var fronts: int = Score.account(game.battle.state,id).fronts.size()
    assert(fronts==1)
    game.battle.advance(.01)
    assert(Score.account(game.battle.state,id).fronts.size()==1)
    game._save_game()
    var saved: String = JSON.stringify(game.battle.state)
    game._load_game(game.battle.PATH)
    assert(JSON.parse_string(saved)==JSON.parse_string(JSON.stringify(game.battle.state)))
    game._remove_entity(npc,"predazione")
    assert(Score.account(game.battle.state,"BR-002").kills.size()==1)
    # New-depot objective requires actual nutrition, not ATP-only harvesting.
    game.battle.start(2)
    id = game.player_id
    game.battle.state.elapsed = 240
    game.player.position = Rules.depot(240,0)
    game.battle.advance(.01)
    assert(Score.account(game.battle.state,id).fronts.get("1","")=="deposito appena attivato")
    game.battle.advance(4.1)
    assert(Score.account(game.battle.state,id).fronts.size()==1)
    # A real boundary crossing by two nearby allies in the explicit five-second window.
    game.battle.start(3)
    id = game.player_id
    game.battle.state.pacts["player"] = "BR-002"
    game.battle.state.pacts["BR-002"] = "player"
    game.battle.state.elapsed = 250
    var center: Vector3 = Rules.center(1)
    game.player.position = center+Vector3(27,0,0)
    game.entities["BR-002"].node.position = center+Vector3(27,0,.5)
    game.battle.update_front_objectives(Rules.zone(250))
    game.battle.state.elapsed = 251
    game.player.position = center+Vector3(25,0,0)
    game.entities["BR-002"].node.position = center+Vector3(25,0,.5)
    game.battle.update_front_objectives(Rules.zone(251))
    assert(Score.account(game.battle.state,id).fronts.get("1","")=="attraversamento con alleato")
    assert(Score.account(game.battle.state,"BR-002").fronts.size()==1)
    # Reproducible controlled end states: no-kill forager beats a healthy hunter.
    game.battle.start(2)
    id = game.player_id
    for other in game.entities.keys():
        if other not in [id,"BR-001"]: game._remove_entity(other,"fixture")
    game.hp = 80; game.atp = 80
    game.entities["BR-001"].hp = 100; game.entities["BR-001"].energy = 100
    Score.account(game.battle.state,id).absorbed = game.battle.state.nutrition_target
    for stage in range(1,5):
        Score.front(game.battle.state,id,stage,"refugio anticipato")
        Score.front(game.battle.state,id,stage,"deposito appena attivato")
    var rank: Array = game.battle.ranking()
    assert(rank[0].id==id and rank[0].breakdown.kills.is_empty() and rank[0].points==72)
    print("NO_KILL_FIXTURE=",JSON.stringify(rank))
    # Same vitality/intake/events, credited kills alone change winner.
    Score.account(game.battle.state,id).absorbed = 0
    Score.account(game.battle.state,id).fronts = {}
    Score.account(game.battle.state,id).early = {}
    Score.account(game.battle.state,id).active = {}
    assert(game.battle.ranking()[0].id=="BR-001")
    for i in range(3):
        game.battle.record_hit("fixture-victim-%d"%i,id,30)
        Score.death(game.battle.state,"fixture-victim-%d"%i)
    assert(game.battle.ranking()[0].id==id)
    print("KILL_SWING_FIXTURE=",JSON.stringify(game.battle.ranking()))
    # Best ally, not player and not the sum of two weak allies.
    game.battle.state.pacts["player"] = "BR-001"
    game.battle.state.pacts["BR-001"] = "player"
    assert(game.battle.ranking().size()==1 and game.battle.ranking()[0].points==44)
    game.hp = 40
    assert(game.battle.ranking()[0].id=="BR-001" and game.battle.ranking()[0].points==40)
    game.hp = 0 # The only remaining contestant is our ally: shared victory.
    game.battle.advance(0)
    assert(game.battle.state.result=="vittoria")
    print("PASS: intake caps, particles/deposits parity, recent multiple attackers, deterministic tie, environment, one front award, reload, no-kill win, kill swing and best-member alliance")
    game.queue_free()
    quit()
