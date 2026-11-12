extends SceneTree
const GENES = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.call("_close_overlay")
    game.mutation_points = 24
    game.call("_on_tree")
    var tree: MutationTree = game.tree_view
    assert(tree != null)
    assert(tree.zoom_level >= 1.20,"Skill tree must be larger than 0.74")
    assert(tree.major_locus(40) == "pili_twitch")
    assert(tree.major_locus(48+40) == "hydrolase_secretion")
    assert(tree.major_locus(2*48+40) == "eps_biosynthesis")
    assert(tree.major_locus(4*48+40) == "membrane_transport")
    assert(tree.major_locus(3) == "","Point mutations stay stat-only")
    assert(not GENES.has(game.entities[game.player_id]["traits"],"pili_twitch"))
    # Reach a major node through the actual connected tree path.
    for id in [0,8,16,24,32,40]:
        tree.call("_select",id)
        tree.call("_select",id)
        assert(game.purchased.has(str(id)),"Skill tree node %d not purchased" % id)
    assert(GENES.has(game.entities[game.player_id]["traits"],"pili_twitch"))
    assert(int(game.entities[game.player_id]["traits"]["pili"]) > 0)
    assert(game.player.use_blender_assets)
    assert(game.player.find_child("GeneModule_pili",true,false) != null)
    assert(int(game.genealogy[0]["traits"].get("pili",0)) > 0)
    print("PASS: enlarged skill tree, branch-specific gene icons and actual heritable pili unlock through major node")
    quit(0)
