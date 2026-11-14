extends SceneTree
const G=preload("res://src/cell_genome.gd")
const P=preload("res://src/cell_physiology.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var g=load("res://scenes/Main.tscn").instantiate()
    root.add_child(g);await process_frame;g.set_process(false);g.journey.skip()
    g.entities[g.player_id].traits["evolution_capabilities"]={"dormancy":true}
    g.atp=12;g.events.toggle_rest()
    assert(g.events.dormant(g.player_id) and not g._can_divide())
    var pos: Vector3=g.player.position
    g._move_player(Vector2.RIGHT,1);assert(g.player.position==pos)
    g.events.toggle_rest();assert(g.events.dormant(g.player_id))
    var ordinary: Dictionary=P.energy_step(40,0,10,0,{})
    var resting: Dictionary=P.energy_step(40,0,10,0,{"dormant":true})
    assert(resting.atp>ordinary.atp and P.energy_step(0,29,2,0,{"dormant":true}).dead)
    g.t+=13;g.atp=25;g.resources.carbon=10;g.events.advance(0)
    assert(not g.events.dormant(g.player_id))
    g.events.start_current()
    var count: int=g.nutrients.size()
    var chosen: Dictionary=g.events.state.current.particles.duplicate(true)
    g.events.advance(7)
    g._save_game("user://current.json");g._load_game("user://current.json")
    assert(g.nutrients.size()==count and JSON.stringify(g.events.state.current.particles)==JSON.stringify(chosen))
    g.events.advance(12)
    assert(g.nutrients.size()==count)
    var ids: Dictionary={}
    for n in g.nutrients:
        assert(not ids.has(n.uid));ids[n.uid]=true
    var patch: Node3D=g.substrates[0]
    var at: Vector3=patch.position
    g.events.state.generations=[1,2];g.events.state.last_detritus=[at.x,at.y,at.z]
    g._create_entity("rival","",1,"pre_luca",g._base_traits(),at,false,true)
    var before: int=patch.portions
    assert(not G.has(g.entities.rival.traits,"hydrolase_secretion"))
    g._divide_npc("rival")
    var child: String=""
    for id in g.entities:
        if g.entities[id].parent=="rival" and G.has(g.entities[id].traits,"hydrolase_secretion"): child=id
    assert(not child.is_empty())
    g.entities[child].node.position=at;g.entities[child].energy=40
    assert(g._digest_for(patch,child) and patch.portions==before-1)
    assert(not g._digest_for(patch,child))
    g._divide_npc(child)
    for id in g.entities:
        if g.entities[id].parent==child: assert(G.has(g.entities[id].traits,"hydrolase_secretion"))
    print("PASS: dormancy command, movement/fission lock, wake hysteresis, current save and particle conservation, inherited rival digestion")
    g.queue_free();quit()
