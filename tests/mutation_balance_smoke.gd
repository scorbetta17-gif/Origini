extends SceneTree
const B = preload("res://src/mutation_balance.gd")
const P = preload("res://src/cell_physiology.gd")
const G = preload("res://src/cell_genome.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var traits: Dictionary = B.normalize({})
    for i in range(1000):
        traits = B.tree_effect(traits,"motility",true)
    assert(float(traits.motility)<=B.CAPS.motility and float(traits.metabolism)>=B.FLOORS.metabolism)
    traits["flagella"]=1
    assert(P.player_speed(traits)<=P.PLAYER_BASE_SPEED*B.CAPS.motility+.0001)
    var base: Dictionary = B.normalize({})
    var spent: float = 66.0-float(P.energy_step(66,0,1,P.player_speed(base),base).atp)
    assert(spent>.52 and spent<.54)
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    var carbon: int = 0
    for n in game.nutrients:
        if n.kind=="carbon": carbon+=1
    assert(carbon==36)
    assert(game.substrates.size()==6)
    var patch: Node3D = game.substrates[0]
    game.player.position.x=patch.position.x
    game.player.position.z=patch.position.z
    assert(not game.call("_digest_substrate",patch))
    game.generation=1
    game.mutation_points=2
    game.call("_on_tree")
    var tree = game.tree_view
    assert(tree.call("_available",88))
    assert(not tree.call("_available",40))
    tree.call("_select",88)
    tree.call("_select",88)
    assert(game.mutation_points==0)
    assert(G.has(game.entities[game.player_id].traits,"hydrolase_secretion"))
    game.atp=30
    for key in game.NEED: game.resources[key]=0.0
    assert(game.call("_digest_substrate",patch))
    assert(patch.portions==2 and is_equal_approx(game.atp,32))
    assert(not game.call("_digest_substrate",patch),"Cooldown blocks repeated digestion")
    var resource_key: String = "nucleic" if patch.kind=="rna" else ("amino" if patch.kind=="peptide" else "lipid")
    var expected: float = minf(P.reserve_cap(game.NEED[resource_key]),10.75*float(game.entities[game.player_id].traits.uptake))
    assert(is_equal_approx(game.resources[resource_key],expected))
    for i in range(2):
        game.skill_cooldown=0
        assert(game.call("_digest_substrate",patch))
    assert(game.substrates.size()==5)
    game.call("_maintain_substrates",20.1)
    assert(game.substrates.size()==6)
    game.call("_create_entity","PREY","",1,"pre_luca",game.call("_base_traits"),game.player.position,false,false)
    game.entities.PREY.hp=1.0
    for key in game.NEED: game.resources[key]=0.0
    game.atp=30
    game.skill_cooldown=0
    game.selected_target_id="PREY"
    game.attack_mode="enzyme"
    game.call("_follow_attack",.01)
    assert(not game.entities.has("PREY"))
    assert(game.resources.carbon>9 and game.resources.amino>6 and game.resources.lipid>3 and game.resources.nucleic>2)
    assert(is_equal_approx(game.atp,42))
    var loot: float = game.resources.carbon
    game.call("_follow_attack",.01)
    assert(is_equal_approx(game.resources.carbon,loot),"No duplicate kill reward")
    var saved_kind: String = game.substrates[0].kind
    game.substrates[0].set_portions(2)
    game.entities[game.player_id].traits["point_mutation_progress"]=4
    game.call("_save_game")
    game.call("_load_game")
    assert(game.substrates[0].portions==2 and game.substrates[0].kind==saved_kind)
    assert(int(game.entities[game.player_id].traits.point_mutation_progress)==4)
    var f: FileAccess = FileAccess.open(game.SAVE_PATH,FileAccess.READ)
    var legacy: Dictionary = JSON.parse_string(f.get_as_text())
    f.close()
    legacy.erase("substrates")
    legacy.erase("substrate_respawn")
    f=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
    f.store_string(JSON.stringify(legacy))
    f.close()
    game.call("_load_game")
    assert(game.substrates.size()==6 and game.purchased.has("88"))
    print("PASS: bounded stacking, ATP budget, carbon abundance, first-division enzyme purchase, digestion/cooldown/depletion/respawn and kill rewards")
    quit(0)
