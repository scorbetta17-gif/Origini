extends SceneTree
const Stats = preload("res://src/game_statistics.gd")
const Ecology = preload("res://src/niche_ecology.gd")
const Genome = preload("res://src/cell_genome.gd")
var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func run() -> void:
    var ecology: Dictionary = Ecology.origin()
    Ecology.register_birth(ecology,"rna",Vector3.ZERO,2)
    var profiles := {"rna":{"dna":false},"dna":{"dna":true}}
    var before: Dictionary = ecology.duplicate(true)
    var census: Dictionary = Stats.census(ecology,profiles,Vector3.ZERO)
    check(is_equal_approx(census.occupied_percent,100.0*2/48),"Two cells occupy 4.17% capacity")
    check(census.lines[0].population_percent==100.0,"Two RNA cells are 100% of population")
    check(ecology==before,"Census never changes simulation")
    Ecology.register_birth(ecology,"dna",Vector3.ZERO,6)
    census = Stats.census(ecology,profiles,Vector3.ZERO)
    check(census.groups["Cellule DNA"]==6 and census.lines[0].population_percent==75,"Mixed population composition")
    check(Stats.census(ecology,profiles,Vector3.ZERO,true).capacity==1200,"Whole map denominator")
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    for key in game.NEED: game.resources[key] = float(game.NEED[key])
    game.atp = 90.0
    game.cycle_age = 0.0
    game.call("_refresh_hud")
    check(game.scission_bar.value<100,"Full nutrients do not falsely promise division before maturity")
    check(game.call("_division_block_reason").begins_with("Divisione pronta tra"),"Maturity has correct reason")
    game.cycle_age = 75.0
    game.resources.amino = 0.0
    game.call("_divide_pressed")
    check(game.tips_label.text=="Raccogli tutti i nutrienti necessari","Exact short nutrient notice")
    game.call("_on_statistics")
    check(game.overlay.visible,"Statistics panel opens")
    await create_timer(3.7).timeout
    game.call("_expire_notice")
    check(not game.tips_label.visible and not game.toast_back.visible,"Notice expires within four seconds even with paused overlay")
    game.call("_on_statistics",1,2)
    check(game.overlay.visible,"Map census and DNA filter open")
    game.call("_close_overlay")
    var stock: float = game.resources.amino
    game.call("_award_bundle",{"amino":1000.0},true)
    check(is_equal_approx(game.statistics.collected.amino,game.resources.amino-stock),"Counters track actual capped intake")
    var collected: float = game.statistics.collected.amino
    game.call("_award_bundle",{"amino":1000.0},true)
    check(game.statistics.collected.amino==collected,"Discarded surplus not counted")
    for key in game.NEED: game.resources[key] = float(game.NEED[key])
    game.atp = 29.0
    check(game.call("_division_block_reason").contains("ATP"),"ATP shortage is not mislabeled nutrients")
    game.atp = 90.0
    game.call("_refresh_hud")
    check(game.scission_bar.value==100 and game.call("_can_divide"),"100% means ready")
    game.call("_divide_pressed")
    await create_timer(2.7).timeout
    check(game.statistics.divisions==1,"Animated division counted once")
    var saved: Dictionary = game.statistics.duplicate(true)
    game.call("_save_game","user://statistics_test.json")
    game.statistics = Stats.origin()
    game.call("_load_game","user://statistics_test.json")
    check(game.statistics==saved,"Statistics survive save/load")
    check(Stats.normalize({},120).started_at==120,"Legacy saves explicitly start tracking now")
    game.queue_free()
    await process_frame
    print("STATISTICS FEEDBACK ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
