extends SceneTree
const Rules = preload("res://src/battle_rules.gd")
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func run() -> void:
    check(Rules.zone(149).warning==false and Rules.zone(150).warning,"90 second warning boundary")
    check(is_equal_approx(Rules.zone(240).radius,34) and is_equal_approx(Rules.zone(330).radius,28),"Front transitions continuously")
    check(Rules.damage(700,Vector3.ZERO,{})==0,"Safe center does not inflict damage")
    check(Rules.damage(700,Vector3(39,0,0),{"defense":10},true)>0,"Defense and cooperation cannot make storm immunity")
    check(Rules.score(100,100,1000)==100,"Score is capped and not based on kills")
    check(not Rules.valid({"enabled":true}),"Malformed mode save rejected")
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    var campaign_id: String = game.player_id
    game.mutation_points = 13.5
    game.battle.start(1)
    check(game.battle.active() and game.entities.size()==13,"Arena starts with 12 real opponents")
    check(game.mutation_points==6 and game.generation==3,"Separate arena loadout")
    check(game.world_radius==40,"Arena has bounded play space")
    var count: int = game.entities.size()
    game.call("_advance_niches",0.0) if not game.battle.active() else null
    game.battle.state.elapsed = 150.0
    game.battle.advance(.01)
    check(game.battle.warning_ring.visible,"Warning visible on terrain")
    game.battle.state.elapsed = 240.0
    game.battle.advance(.01)
    check(game.battle.state.stocks==[60,60,60],"Front refreshes finite deposits once")
    game.player.position = Rules.depot(game.battle.state.elapsed,0)
    game.atp = 40
    game.battle.advance(.1)
    check(game.battle.state.stocks[0]==59 and game.atp>40,"Real contact harvest consumes shared stock")
    game.battle.advance(.1)
    check(game.battle.state.stocks[0]==59,"Harvest cooldown blocks frame-rate exploitation")
    game.atp = 100
    game.resources.amino = 0
    check(game.battle.needs_supply(game.player_id),"Full ATP does not block missing nutrients at a cache")
    var friend: String = "BR-002"
    game.entities[friend].node.position = game.player.position+Vector3(.5,0,0)
    game.battle.cooperate()
    check(game.battle.friendly(game.player_id,friend),"Contact creates mutual pact")
    var previous_hp: float = 60
    game.hp = previous_hp
    game.battle.advance(1)
    check(game.hp>previous_hp,"Nearby cooperation recovers HP at ATP cost")
    game.battle.cooperate()
    check(not game.battle.friendly(game.player_id,friend),"Pact dissolves in both directions")
    var saved: Dictionary = game.battle.state.duplicate(true)
    game.call("_save_game")
    game.call("_load_game",game.battle.PATH)
    check(JSON.parse_string(JSON.stringify(game.battle.state))==JSON.parse_string(JSON.stringify(saved)),"Timer stocks harvest and alliances survive reload")
    check(game.entities.size()==count,"Reload does not create extra competitors")
    var current: String = game.player_id
    game.call("_switch_lineage",friend)
    check(game.player_id==current,"No resurrection or switching to rivals")
    game.hp = 0
    game.call("_game_over")
    check(game.battle.state.result=="sconfitta" and game.is_paused,"Death ends the match")
    game.call("_close_overlay")
    check(game.is_paused,"Closing result cannot resume match")
    game.call("_load_game",game.SAVE_PATH)
    check(not game.battle.active() and game.player_id==campaign_id and game.mutation_points==13.5,"Campaign untouched by arena autosaves")
    check(game.world_radius>1000,"Campaign world size restored")
    game.battle.start(3)
    for key in game.NEED: game.resources[key] = float(game.NEED[key])
    game.cycle_age = 75
    game.atp = 90
    game.call("_divide_pressed")
    await create_timer(2.7).timeout
    check(game.battle.team(game.player_id)=="player" and game.statistics.divisions==1,"Division preserves contestant identity and points")
    check(game.battle.active(),"Division does not exit arena")
    game.battle.start(0)
    game.battle.state.elapsed = 1200
    game.hp = 100
    game.atp = 100
    for e in game.entities.values():
        e.hp = 100
        e.energy = 100
    game.battle.advance(0)
    check(game.battle.state.result=="pareggio","Deadline resolves equal vitality as a draw")
    game.battle.start(2)
    for id in game.entities.keys():
        if id!=game.player_id: game.call("_remove_entity",id,"test")
    game.battle.advance(.1)
    check(game.battle.state.result=="vittoria","Last contestant wins")
    game.queue_free()
    await process_frame
    print("BATTLE ROYALE ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
