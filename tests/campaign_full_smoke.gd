extends SceneTree
## Test di campagna completa DAL GIORNO ZERO alla conclusione Fase 2.
## Le risorse sono date dal test; le transizioni e le mutazioni sono quelle reali.
const GENES = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_run")

const FISSION_NEEDS: Dictionary = {"carbon":24.0,"amino":15.0,"lipid":12.0,"nucleic":8.0,"biomass":65.0}

func _fund_fission(game: Node) -> void:
    for key in FISSION_NEEDS:
        game.resources[key] = float(FISSION_NEEDS[key])
    game.atp = 99.0

func _daughter(game: Node, choice: int) -> void:
    _fund_fission(game)
    game.call("_divide_pressed")
    assert(game.division_options.size() == 2, "Two living daughters must be offered")
    game.call("_choose_daughter",choice)
    assert(game.entities.has(game.player_id))

func _run() -> void:
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    assert(game.generation == 0)
    assert(str(game.entities[game.player_id]["branch"]) == "pre_luca")
    assert(not bool(game.entities[game.player_id]["traits"]["dna"]))
    _daughter(game,0) # gen 1: protocellula
    assert(game.generation == 1)
    _daughter(game,0) # gen 2: LUCA ludico con DNA
    assert(game.generation == 2)
    assert(str(game.entities[game.player_id]["branch"]) == "luca")
    assert(GENES.has(game.entities[game.player_id]["traits"],"dna_stabilization"))
    _daughter(game,1) # gen 3: sister line Archaea, bacterial sister remains NPC
    assert(game.generation == 3)
    assert(str(game.entities[game.player_id]["branch"]) == "archaea")
    assert(GENES.has(game.entities[game.player_id]["traits"],"archaeal_envelope"))
    var bacterial_sibling_alive: bool = false
    for id in game.entities:
        if id != game.player_id and str(game.entities[id]["branch"]) == "bacteria":
            bacterial_sibling_alive = true
    assert(bacterial_sibling_alive)
    _daughter(game,0) # gen 4: selective major surface-recognition allele
    assert(GENES.has(game.entities[game.player_id]["traits"],"surface_recognition"))
    _daughter(game,0) # gen 5: heritable transport allele
    assert(GENES.has(game.entities[game.player_id]["traits"],"surface_recognition"))
    assert(GENES.has(game.entities[game.player_id]["traits"],"membrane_transport"))

    # Entire Phase 1 must end before Phase 2 is playable.
    _daughter(game,0) # gen 6: final cohort available
    assert(game.generation == 6)
    for i in range(3):
        var autonomous_id: String = ""
        for candidate_id in game.entities:
            if str(candidate_id) != game.player_id:
                autonomous_id = str(candidate_id)
                break
        assert(autonomous_id != "")
        game.call("_divide_npc",autonomous_id)
    assert(int(game.phase1_progress["autonomous_divisions"]) >= 3)
    assert(game.entities.size() >= 10)
    game.call("_advance_phase_one",74.0)
    assert(not bool(game.phase1_progress["complete"]))
    game.call("_advance_phase_one",1.1)
    assert(bool(game.phase1_progress["complete"]))
    assert(game.overlay.visible)
    game.call("_close_overlay")
    game.call("_create_external_bacterium")
    game.call("_advance_phase_two",.2)
    assert(bool(game.phase2_progress["discovered"]))
    game.call("_on_cooperate")
    assert(game.partner_id != "")
    assert(game.entities[game.partner_id]["branch"] == "bacteria")
    assert(bool(game.entities[game.partner_id]["external"]))
    for i in range(30):
        game.call("_advance_phase_two",1.0)
    assert(bool(game.phase2_progress["stable"]))
    assert(bool(game.phase2_progress["active_stable"]))
    assert(bool(game.phase2_progress["exchanged"]))
    _daughter(game,0) # gen 7: inherited collaboration into selected daughter
    assert(game.generation == 7)
    assert(bool(game.phase2_progress["complete"]))
    assert(bool(game.phase2_progress["transmitted"]))
    assert(game.partner_id != "")
    game.call("_save_game")
    game.call("_load_game")
    assert(bool(game.phase2_progress["complete"]))
    assert(game.generation == 7)
    assert(game.genealogy.size() >= 20)
    print("PASS: full campaign — primordial cell, RNA/DNA, Bacteria/Archaea, autonomous population, 75s Phase 1, 12s metabolism, 25s consortium, daughter and save")
    quit(0)
