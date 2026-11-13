extends SceneTree
## Accelerated real-world simulation, not a human pacing/performance measurement.
var game: Node
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    var results: Array = []
    for trial in range(12):
        var profile: int = trial%4
        var scenario_seed: int = 8200+int(trial/4)
        game.rng.seed = scenario_seed
        game.battle.start(profile)
        var initial: int = game.entities.size()
        var boundary_errors: int = 0
        for tick in range(2400):
            if not str(game.battle.state.result).is_empty(): break
            var dt: float = .5
            game.t += dt
            game.skill_cooldown = maxf(0,game.skill_cooldown-dt)
            game.regeneration_cooldown = maxf(0,game.regeneration_cooldown-dt)
            var id: String = game.player_id
            game.entities[id].energy = game.atp
            var idx: int = game._nearest_nutrient(game.player.position,30)
            var direction := Vector3.ZERO
            if idx>=0: direction = game.nutrients[idx].node.position-game.player.position
            direction = game.battle.npc_goal(id,direction)
            var previous: Vector3 = game.player.position
            game._move_player(Vector2(direction.x,direction.z).normalized() if direction.length()>.3 else Vector2.ZERO,dt)
            var energy: Dictionary = game.Physiology.energy_step(game.atp,game.zero_atp_seconds,dt,previous.distance_to(game.player.position),game.entities[id].traits)
            game.atp = energy.atp
            game.zero_atp_seconds = energy.zero_seconds
            if energy.dead: game.hp = 0
            if game.hp<65 and game.regeneration_cooldown<=0: game._on_regen()
            if profile==0:
                for other in game.entities:
                    if not game.battle.friendly(id,other) and game.player.position.distance_to(game.entities[other].node.position)<1.4:
                        game.selected_target_id = other
                        game.attack_mode = "lysis"
                        game._follow_attack(dt)
                        break
            game._collect_nearby()
            game._update_ecosystem(dt)
            game._update_npc_motion(dt)
            if profile==3 and tick%10==0 and not game.battle.state.pacts.has("player"):
                game.battle.cooperate()
            game.battle.advance(dt)
            if not is_finite(game.hp) or not is_finite(game.atp): boundary_errors += 1
            if tick%100==0: await process_frame
        results.append({"profile":profile,"seed":scenario_seed,"result":game.battle.state.result,"elapsed":game.battle.state.elapsed,"survivors":game.entities.size(),"initial":initial,"hp":game.hp,"atp":game.atp,"invalid":boundary_errors,"ranking_new":game.battle.ranking(),"ranking_old_same_events":game.battle.ranking(true),"personal":game.battle.scoring.breakdown(game.battle.state,game.player_id,game.hp,game.atp),"nutrition_target":game.battle.state.nutrition_target})
        assert(boundary_errors==0)
        assert(not str(game.battle.state.result).is_empty())
    var report_path: String = ProjectSettings.globalize_path("res://build/battle-playthrough.json")
    var directory_error: Error = DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
    if directory_error!=OK:
        push_error("Cannot create playthrough report directory: %s" % error_string(directory_error))
        quit(1)
        return
    var file := FileAccess.open(report_path,FileAccess.WRITE)
    if file==null:
        push_error("Cannot open playthrough report: %s" % error_string(FileAccess.get_open_error()))
        quit(1)
        return
    file.store_string(JSON.stringify(results,"  "))
    file.close()
    print("BATTLE_PLAYTHROUGH=",JSON.stringify(results))
    game.queue_free()
    await process_frame
    print("BATTLE PLAYTHROUGH PASS")
    quit()
