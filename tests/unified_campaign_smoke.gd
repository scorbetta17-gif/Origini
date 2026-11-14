extends SceneTree
const Evolution = preload("res://src/evolution_progress.gd")
const Balance = preload("res://src/mutation_balance.gd")
const Ecology = preload("res://src/niche_ecology.gd")
var failures: int = 0
var game: Node

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("UNIFIED CAMPAIGN: "+message)

func fill_cycle() -> void:
    for key in game.NEED:
        game.resources[key] = float(game.NEED[key])
    game.atp = 90.0
    game.hp = 100.0
    game.cycle_age = 75.0

func save_roundtrip(path: String) -> void:
    var previous_id: String = game.player_id
    var ids: Array = game.entities.keys()
    ids.sort()
    var previous_evolution: Dictionary = JSON.parse_string(JSON.stringify(game.evolution))
    var previous_ecology: Dictionary = JSON.parse_string(JSON.stringify(Ecology.normalize(game.ecology)))
    var previous_points: float = game.mutation_points
    for iteration in range(2):
        game.call("_save_game",path)
        game.call("_load_game",path)
        var new_ids: Array = game.entities.keys()
        new_ids.sort()
        check(game.player_id==previous_id and new_ids==ids,"Roundtrip preserves controlled and entity IDs")
        check(JSON.parse_string(JSON.stringify(game.evolution))==previous_evolution,"Roundtrip preserves evolution including donor provenance")
        check(JSON.parse_string(JSON.stringify(Ecology.normalize(game.ecology)))==previous_ecology,"Roundtrip preserves ecological census and credits")
        check(is_equal_approx(game.mutation_points,previous_points),"Roundtrip preserves fractional wallet")
        game.call("_close_overlay")

func _run() -> void:
    game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    check(game.evolution.unlocks.get("cell_zero",false),"New game starts at Cellula Zero")
    check(int(game.evolution.divisions)==0,"New game has no inherited campaign progress")
    fill_cycle()
    game.cycle_age = 34.99
    check(not game.call("_can_divide"),"First cycle guard before 35 seconds")
    game.cycle_age = 35.0
    check(game.call("_can_divide"),"First cycle ready at 35 seconds")
    var original_traits: Dictionary = game.entities[game.player_id].traits.duplicate(true)
    game.mutation_points = .375
    game.call("_divide_pressed")
    check(game.division_options.size()==2,"Division prepares two inherited genomes")
    check(game.division_options[0].traits==original_traits and game.division_options[1].traits==original_traits,"Both daughters inherit identical genome; no random variant offer")
    await create_timer(2.7).timeout
    check(game.generation==1,"Real division tween automatically activates daughter")
    check(is_equal_approx(game.mutation_points,4.375),"Baseline division grants 4 PM and preserves fraction")
    check(game.division_options.is_empty() and game.journey.state.step=="offer","First division offers enzymes, never random daughter choices")
    fill_cycle()
    game.cycle_age = 74.99
    check(not game.call("_can_divide"),"Later cycle guard before 75 seconds")
    game.cycle_age = 75.0
    check(game.call("_can_divide"),"Later cycle matures at 75 seconds")
    var donor_id: String = "QA-DONOR"
    game.call("_create_entity",donor_id,"",1,"bacteria",game.call("_base_traits"),game.player.position+Vector3(.5,0,0),false,true)
    var donor_lineage: String = str(game.entities[donor_id].ecotype)
    var first_leca: int = -1
    # Accelerated integration fixture: fills resources/maturity, supplies actual live donor,
    # and marks observed external exchange stable. This is not a natural-duration playthrough.
    for division in range(2,81):
        fill_cycle()
        game.phase1_progress["complete"] = false
        if game.entities.has(donor_id):
            game.partner_id = donor_id
            game.phase2_progress["partner_id"] = donor_id
            game.phase2_progress["bonded"] = true
            game.phase2_progress["stable"] = true
            game.phase2_progress["active_stable"] = true
            game.phase2_progress["exchange_seconds"] = 20.0
            game.phase2_progress["contact_seconds"] = 30.0
            game.entities[donor_id].node.position = game.player.position+Vector3(.5,0,0)
        var before: float = game.mutation_points
        var inherited: Dictionary = game.entities[game.player_id].traits.duplicate(true)
        var branch: String = game.entities[game.player_id].branch
        game.division_options = [{"traits":inherited.duplicate(true),"branch":branch},{"traits":inherited.duplicate(true),"branch":branch}]
        game.call("_choose_daughter",0)
        check(is_equal_approx(game.mutation_points,before+4.0*Balance.points_multiplier(inherited)),"Accelerated division uses bounded PM multiplier")
        check(game.entities[game.player_id].traits==inherited,"Daughter preserves phenotype and functional genome")
        # A division can reset external association state; explicitly restore the observed fixture.
        if game.entities.has(donor_id):
            game.partner_id = donor_id
            game.phase2_progress["active_stable"] = true
        for entry in Evolution.catalogue():
            if entry.id in ["bacteria","alpha_partner","prokaryotic_groups","differentiated_groups"]:
                continue
            var context: Dictionary = game.call("_evolution_context")
            if float(game.mutation_points)>=float(entry.cost) and Evolution.can_unlock(game.evolution,entry.id,game.entities[game.player_id].traits,context):
                var wallet: float = game.mutation_points
                game.call("_unlock_capability",entry.id)
                check(game.evolution.unlocks.get(entry.id,false),"Actual handler unlocks "+entry.id)
                check(is_equal_approx(game.mutation_points,wallet-float(entry.cost)),"Single wallet deducts exact capacity cost")
                game.call("_close_overlay")
        if game.evolution.unlocks.get("internal_symbiont",false):
            check(not game.entities.has(donor_id),"Internalization consumes external donor exactly once")
            check(game.evolution.endosymbiont.donor_id==donor_id and game.evolution.endosymbiont.donor_lineage==donor_lineage,"Endosymbiont preserves independent donor provenance")
        if game.evolution.unlocks.get("leca",false):
            first_leca = int(game.evolution.divisions)
            break
        await process_frame
    check(first_leca>=60 and first_leca<=80,"Actual root handlers reach LECA after 60+ divisions")
    check(not game.evolution.unlocks.has("bacteria"),"Host campaign requires no purchase of alternative bacterial branch")
    check(is_equal_approx(fmod(game.mutation_points,1.0),.375),"Fractional PM persist through full campaign purchases")
    var census_id: String = Ecology.niche_id(game.player.position)
    var ecotype: String = game.entities[game.player_id].ecotype
    game.ecology.niches[census_id].birth_credit[ecotype] = .375
    game.ecology.niches[census_id].death_credit[ecotype] = .625
    save_roundtrip("user://unified_campaign_v80.json")
    game.call("_save_game","user://unified_campaign_legacy.json")
    var file: FileAccess = FileAccess.open("user://unified_campaign_legacy.json",FileAccess.READ)
    var legacy: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    legacy.version = 71
    legacy.erase("ecology")
    legacy.erase("ecological_profiles")
    for entity in legacy.entities:
        entity.erase("evolution")
        entity.erase("ecotype")
        entity.erase("cycle_age")
    file = FileAccess.open("user://unified_campaign_legacy.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(legacy))
    file.close()
    var legacy_id: String = game.player_id
    game.call("_load_game","user://unified_campaign_legacy.json")
    check(game.player_id==legacy_id,"Version71 migration preserves cell ID")
    check(not game.evolution.unlocks.get("internal_symbiont",false),"Legacy lacks internal state and must not infer endosymbiosis")
    save_roundtrip("user://unified_campaign_migrated.json")
    if failures==0:
        print("PASS: unified campaign actual division/unlock handlers, 60+ generations, donor provenance, fractional wallet, v80 and v71 roundtrips")
    else:
        printerr("FAIL: unified campaign checks: ",failures)
    game.queue_free()
    quit(0 if failures==0 else 1)
