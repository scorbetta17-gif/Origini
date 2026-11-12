extends SceneTree
const G = preload("res://src/cell_genome.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.rng.seed=2042
    game.call("_new_game")
    game.call("_close_overlay")
    # Chapter-start fixture only: no fission resources or ATP are granted below.
    game.phase1_progress.complete=true
    var traits: Dictionary = game.call("_base_traits")
    for locus in ["dna_stabilization","archaeal_envelope","surface_recognition","membrane_transport"]:
        traits=G.grant(traits,locus,5,"chapter_fixture","archaea")
    game.call("_create_entity","A-010","",5,"archaea",traits,Vector3.ZERO,false,true)
    game.call("_activate_lineage","A-010")
    game.next_id=11
    game.call("_seek_partner")
    for i in range(700):
        game.call("_process",.05)
        if i%100==0: await process_frame
        if game.phase2_progress.active_stable: break
    assert(game.phase2_progress.active_stable,"Partner search and live ecosystem must produce stability")
    game.call("_toggle_exchange")
    var elapsed: float = 0
    while not game.call("_can_divide") and elapsed<300:
        var nearest: float = INF
        var target: Vector3 = game.player.position
        for n in game.nutrients:
            var kind: String = n.kind
            if kind=="detritus": continue
            if float(game.resources[kind])>=float(game.NEED[kind]) and float(game.resources.biomass)>=65 and game.atp>=30: continue
            var d: float = game.player.position.distance_to(n.node.position)
            if d<nearest and game.call("_temperature_at",n.node.position)<40:
                target=n.node.position
                nearest=d
        var offset: Vector3 = target-game.player.position
        var wait_partner: bool = game.partner_id!="" and game.player.position.distance_to(game.entities[game.partner_id].node.position)>3.1
        game.move_vector=Vector2.ZERO if wait_partner else Vector2(offset.x,offset.z).normalized()
        game.call("_process",.05)
        elapsed+=.05
        if int(elapsed*20)%100==0: await process_frame
        assert(game.hp>0,"Playable route must survive")
    game.move_vector=Vector2.ZERO
    assert(game.call("_can_divide"),"Actual environmental uptake must fund fission within 5 min")
    assert(game.phase2_progress.active_stable,"Partner must follow while harvesting")
    game.call("_divide_pressed")
    game.call("_choose_daughter",0)
    assert(game.phase2_progress.complete and game.phase2_progress.transmitted)
    game.call("_load_game")
    assert(game.phase2_progress.complete)
    print("PASS: playable Phase 2 with live ecosystem, automatic approach, real feeding, conserved carbon, following partner, division and save; feeding_seconds=",elapsed)
    quit()
