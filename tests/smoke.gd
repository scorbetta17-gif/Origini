extends SceneTree
## Esecuzione opzionale con l'eseguibile Godot: godot --headless --path . --script tests/smoke.gd
## Questo file non e' eseguito automaticamente nell'ambiente ChatGPT.

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var packed: PackedScene = load("res://scenes/Main.tscn")
    if packed == null:
        printerr("FAIL: scena principale assente")
        quit(1)
        return
    var game: Variant = packed.instantiate()
    root.add_child(game)
    await process_frame
    if not game.entities.has("C-000"):
        printerr("FAIL: cellula iniziale assente")
        quit(1)
        return
    var initial: Dictionary = game.entities["C-000"]["traits"]
    assert(not bool(initial.get("dna",true)))
    assert(int(initial.get("archaella",1)) == 0)
    assert(int(initial.get("flagella",1)) == 0)
    assert(not game._can_divide())
    var required: Dictionary = {"carbon":24.0,"amino":15.0,"lipid":12.0,"nucleic":8.0,"biomass":65.0}
    for k in required:
        game.resources[k] = float(required[k])
    game.atp = 96.0
    game._divide_pressed()
    assert(game.division_options.size() == 2)
    game._choose_daughter(1)
    assert(game.genealogy.size() == 3)
    assert(str(game.genealogy[0]["status"]) == "divisa")
    assert(game.entities.size() == 2)
    var mother_id: String = "C-000"
    for id in game.entities:
        assert(str(game.entities[id]["parent"]) == mother_id)
    var sister_id: String = ""
    for id in game.entities:
        if id != game.player_id:
            sister_id = str(id)
    game.entities[sister_id]["biomass"] = 67.0
    game.entities[sister_id]["energy"] = 55.0
    game._divide_npc(sister_id)
    assert(game.entities.size() == 3)
    assert(game.genealogy.size() == 5)
    var sister_status: String = ""
    for rec in game.genealogy:
        if str(rec["id"]) == sister_id:
            sister_status = str(rec["status"])
    assert(sister_status == "divisa")
    var victim_id: String = ""
    for id in game.entities:
        if id != game.player_id:
            victim_id = str(id)
            break
    game._remove_entity(victim_id,"predazione")
    var cause: String = ""
    for rec in game.genealogy:
        if str(rec["id"]) == victim_id:
            cause = str(rec["cause"])
    assert(cause == "predazione")
    game.hp = 40.0
    game.resources["carbon"] = 20.0
    game.resources["amino"] = 10.0
    game.resources["lipid"] = 10.0
    game.resources["nucleic"] = 6.0
    game._on_regen()
    assert(game.hp > 69.0)
    assert(game.resources["carbon"] < 19.0)
    game._save_game()
    game._load_game()
    assert(game.genealogy.size() == 5)
    assert(game.entities.has(game.player_id))
    print("PASS: origine, joystick separato, scissioni, genealogia, predazione, HP e salvataggio")
    quit(0)
