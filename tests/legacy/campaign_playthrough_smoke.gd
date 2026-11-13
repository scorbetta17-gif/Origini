extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.rng.seed=6012
    game.call("_new_game")
    game.call("_close_overlay")
    var ticks: int=0
    while ticks<24000 and not game.phase1_progress.complete:
        if game.call("_can_divide") and game.generation<6:
            var choice: int=1 if game.generation==2 else 0
            game.call("_divide_pressed")
            game.call("_choose_daughter",choice)
        if game.hp<65:
            game.call("_on_regen")
        var best: float=INF
        var target: Vector3=game.player.position
        for n in game.nutrients:
            if n.kind=="detritus": continue
            if game.resources[n.kind]>=game.NEED[n.kind] and game.resources.biomass>=65 and game.atp>60: continue
            var d: float=game.player.position.distance_to(n.node.position)
            if d<best and game.call("_temperature_at",n.node.position)<40:
                best=d
                target=n.node.position
        var offset: Vector3=target-game.player.position
        game.move_vector=Vector2(offset.x,offset.z).normalized()
        game.call("_process",.05)
        ticks+=1
        if ticks%200==0: await process_frame
        if game.hp<=0: break
    print("CAMPAIGN elapsed=",ticks*.05," gen=",game.generation," population=",game.entities.size()," autonomous=",game.phase1_progress.autonomous_divisions," HP=",game.hp)
    assert(game.phase1_progress.complete,"Unfunded campaign must reach Phase 2")
    assert(FileAccess.file_exists(game.PHASE_TWO_CHECKPOINT))
    game.move_vector=Vector2.ZERO
    game.call("_close_overlay")
    game.call("_seek_partner")
    for i in range(1200):
        if game.hp<65: game.call("_on_regen")
        game.call("_process",.05)
        if i%100==0: await process_frame
        if game.phase2_progress.active_stable: break
    assert(game.phase2_progress.active_stable)
    game.call("_toggle_exchange")
    for i in range(6000):
        if game.call("_can_divide"): break
        if game.hp<65: game.call("_on_regen")
        var nearest: float=INF
        var target: Vector3=game.player.position
        for n in game.nutrients:
            if n.kind=="detritus": continue
            if game.resources[n.kind]>=game.NEED[n.kind] and game.resources.biomass>=65 and game.atp>=30: continue
            var d: float=game.player.position.distance_to(n.node.position)
            if d<nearest and game.call("_temperature_at",n.node.position)<40:
                nearest=d
                target=n.node.position
        var offset: Vector3=target-game.player.position
        var wait_partner: bool=game.partner_id!="" and game.player.position.distance_to(game.entities[game.partner_id].node.position)>3.1
        game.move_vector=Vector2.ZERO if wait_partner else Vector2(offset.x,offset.z).normalized()
        game.call("_process",.05)
        if i%100==0: await process_frame
    game.move_vector=Vector2.ZERO
    assert(game.call("_can_divide") and game.phase2_progress.active_stable)
    game.call("_divide_pressed")
    game.call("_choose_daughter",0)
    assert(game.phase2_progress.complete)
    print("PASS: entire unfunded campaign from primordial cell through Phase 1 ecology and Phase 2 inherited consortium")
    quit()
