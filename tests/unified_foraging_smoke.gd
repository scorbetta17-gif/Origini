extends SceneTree
## Unfunded starter playthrough: real food, motion, ATP, NPC competition and cycle age.
const STEP: float = .07
const MAX_TICKS: int = 12857 # 15 simulated minutes, no age/resource shortcuts.

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.rng.seed = 6012
    game.call("_new_game")
    game.call("_close_overlay")
    var ticks: int = 0
    var minimum_atp: float = game.atp
    var maximum_stall: float = 0.0
    var stall: float = 0.0
    var milestones: Array = []
    while ticks < MAX_TICKS and game.generation < 3 and game.hp > 0:
        if game.call("_can_divide"):
            game.move_vector = Vector2.ZERO
            game.call("_divide_pressed")
            await create_timer(2.7).timeout
            milestones.append({"generation":game.generation,"simulation_seconds":ticks*STEP,"atp":game.atp,"hp":game.hp})
            print("FORAGING_DIVISION ",JSON.stringify(milestones.back()))
            if game.generation >= 3:
                break
            game.call("_close_overlay")
        if game.hp < 65:
            game.call("_on_regen") # Pays actual resources/cooldown; no free healing.
        var best: float = INF
        var target: Vector3 = game.player.position
        for nutrient in game.nutrients:
            if not is_instance_valid(nutrient.node):
                continue
            var kind: String = nutrient.kind
            var needs_biomass: bool = float(game.resources.biomass) < float(game.NEED.biomass)
            var useful: bool = needs_biomass or game.atp < 65.0
            if kind != "detritus":
                useful = useful or float(game.resources[kind]) < float(game.NEED[kind])
            if not useful or game.call("_temperature_at",nutrient.node.position) >= 40:
                continue
            var distance: float = game.player.position.distance_to(nutrient.node.position)
            var score: float = distance
            if game.atp < 45.0 and kind == "carbon":
                score *= .45
            # Avoid currently visible predators through path choice, never remove them.
            for id in game.entities:
                if id == game.player_id:
                    continue
                var entity: Dictionary = game.entities[id]
                if int(entity.traits.get("protease",0)) > 0 and entity.node.position.distance_to(nutrient.node.position)<4:
                    score += 20.0
            if score < best:
                best = score
                target = nutrient.node.position
        var offset: Vector3 = target-game.player.position
        game.move_vector = Vector2(offset.x,offset.z).normalized() if best < INF else Vector2.ZERO
        var previous: Vector3 = game.player.position
        game.call("_process",STEP)
        ticks += 1
        minimum_atp = minf(minimum_atp,float(game.atp))
        stall = stall+STEP if game.player.position.distance_to(previous)<.001 else 0.0
        maximum_stall = maxf(maximum_stall,stall)
        if ticks % 1000 == 0:
            print("FORAGING_PROGRESS seconds=",ticks*STEP," gen=",game.generation," ATP=",game.atp," HP=",game.hp," resources=",JSON.stringify(game.resources))
        if ticks % 100 == 0:
            await process_frame
    print("FORAGING_RESULT seconds=",ticks*STEP," generation=",game.generation," minimum_ATP=",minimum_atp," longest_stall=",maximum_stall," HP=",game.hp," resources=",JSON.stringify(game.resources))
    if game.generation >= 3 and game.hp > 0:
        print("PASS: unfunded starter forages real nutrients and completes three real division animations without resource or age grants")
        game.queue_free()
        quit(0)
    else:
        printerr("FAIL: unfunded starter failed three cycles within 15 simulated minutes")
        game.queue_free()
        quit(1)
