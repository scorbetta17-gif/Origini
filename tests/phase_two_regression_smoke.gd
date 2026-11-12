extends SceneTree
const P = preload("res://src/phase_two_progress.gd")
const G = preload("res://src/cell_genome.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var traits: Dictionary = {"adhesion":true,"transporters":1}
    var bond: Dictionary = P.bind(P.empty(),traits,traits,"B",2)
    var dry: Dictionary = P.advance(bond,25,2,traits,traits,.01,80)
    assert(float(dry.progress.exchange_seconds)<.11,"Tiny resource cannot buy 25 seconds")
    var stable: Dictionary = P.advance(bond,25,2,traits,traits,20,80).progress
    assert(stable.active_stable)
    var rebound: Dictionary = P.bind(P.release(stable),traits,traits,"NEW",2)
    rebound=P.advance(rebound,30,2,traits,traits,0,80).progress
    assert(not rebound.active_stable,"Historical milestone cannot stabilize a dry new bond")
    stable.exchange_enabled=false
    var paused: Dictionary = P.advance(stable,2,2,traits,traits,20,80)
    assert(paused.carbon_cost==0 and paused.progress.active_stable)
    assert(not P.advance(stable,1,2,traits,traits,20,0).progress.active_stable)
    assert(not P.advance(stable,1,9,traits,traits,20,80).progress.bonded)
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    game.phase1_progress.complete=true
    game.call("_follow_archaeal_lineage")
    assert(game.entities[game.player_id].branch=="archaea")
    var tr: Dictionary = game.entities[game.player_id].traits
    tr=G.grant(tr,"surface_recognition",4,"test","archaea")
    tr=G.grant(tr,"membrane_transport",5,"test","archaea")
    game.entities[game.player_id].traits=tr
    game.call("_create_external_bacterium")
    game.call("_on_cooperate")
    assert(game.partner_id!="")
    var partner: String = game.partner_id
    game.call("_divide_npc",partner)
    assert(game.partner_id!=partner and game.entities.has(game.partner_id))
    game.call("_advance_phase_two",.1)
    game.call("_remove_entity",game.partner_id,"predazione")
    assert(game.partner_id=="" and not game.phase2_progress.bonded)
    game.call("_save_game")
    var f: FileAccess = FileAccess.open(game.SAVE_PATH,FileAccess.READ)
    var data: Dictionary = JSON.parse_string(f.get_as_text())
    f.close()
    var before: String = game.player_id
    var count: int = game.entities.size()
    data.entities[0].pos=[0]
    f=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    f.close()
    game.call("_load_game")
    assert(game.player_id==before and game.entities.size()==count)
    game.hp=0
    game.call("_game_over")
    game.call("_close_overlay")
    game.call("_on_regen")
    assert(game.hp==0 and game.is_paused and game.overlay.visible)
    assert(not game.call("_can_divide"))
    game.call("_switch_lineage","C-000")
    assert(game.hp>0 and not game.entities.has(before))
    print("PASS: real exchange duration, stale stability, pause, starvation, lost/divided partner, branch recovery, invalid save and death recovery")
    quit()
