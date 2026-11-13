extends SceneTree
const G = preload("res://src/cell_genome.gd")
const C = preload("res://src/cell_visual.gd")
const S = preload("res://src/substrate_patch.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var cell := C.new()
    root.add_child(cell)
    cell.setup(G.normalize({"genome":G.origin()}),"pre_luca")
    assert(cell.find_child("Membrane_InnerLeaflet",true,false)!=null)
    assert(cell.find_child("CytoplasmicEnzymes",true,false)==null)
    cell.set_growth(100)
    assert(is_equal_approx(cell.growth/.72,1.2))
    cell.setup(G.grant(cell.traits,"hydrolase_secretion",1,"test","pre_luca"),"pre_luca")
    assert(cell.find_child("CytoplasmicEnzymes",true,false)!=null)
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.entities[game.player_id].traits=cell.traits.duplicate(true)
    for i in range(3):
        var patch: Node3D = game.substrates[i]
        assert(patch.kind==S.KINDS[i])
        game.player.position=Vector3(patch.position.x,0,patch.position.z)
        game.atp=30
        game.skill_cooldown=0
        for key in game.NEED: game.resources[key]=0.0
        assert(game._digest_substrate(patch))
        var key: String = ["nucleic","amino","lipid"][i]
        assert(game.resources[key]>=8.9)
        for other in ["nucleic","amino","lipid"]:
            if other!=key: assert(is_zero_approx(game.resources[other]))
        assert(patch.portions==2)
        assert(not patch.fragments[2].visible)
    game.is_paused=true
    game.player.position=Vector3(1000,0,1000)
    for i in range(25): game._process(.016)
    var terrain: Node = game.world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
    assert(terrain.pending.is_empty() and terrain.sectors.has(Vector2i(992,992)),"Saved distant terrain must load behind a paused overlay")
    print("PASS: bilayer, enzyme-gated inclusions, 20 percent growth and three distinct digestible resources")
    quit(0)
