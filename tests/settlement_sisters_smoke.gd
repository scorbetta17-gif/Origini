extends SceneTree
const E=preload("res://src/niche_ecology.gd")
func _initialize() -> void: call_deferred("run")
func total(g: Node) -> int:
    var n: int=0
    for niche in g.ecology.niches.values():
        for count in niche.populations.values(): n+=int(count)
    return n
func run() -> void:
    var g=load("res://scenes/Main.tscn").instantiate()
    root.add_child(g); await process_frame
    g.set_process(false);g.journey.skip()
    for key in g.NEED: g.resources[key]=g.NEED[key]
    g.atp=90;g.cycle_age=35
    g._divide_pressed();await create_timer(2.7).timeout
    var a: String=g.player_id
    var b: String=""
    for id in g.entities:
        if id!=a and g.entities[id].parent=="C-000": b=id
    assert(not b.is_empty())
    var inherited: Dictionary=g.entities[a].traits.duplicate(true)
    assert(g.entities[b].traits==inherited)
    g._on_tree();g._on_tree_mutation(88,g.tree_view.STATS[1],0,2)
    g._switch_lineage(b)
    assert(g.mutation_points==4 and g.entities[b].traits==inherited)
    g._on_tree();g._on_tree_mutation(0,g.tree_view.STATS[0],0,1);g._close_overlay()
    assert(g.mutation_points==3 and g.entities[a].traits!=g.entities[b].traits)
    var before: int=total(g)
    g.player.position=Vector3(100,0,100)
    g._advance_niches(0)
    assert(g.campaign.state.archive.has(a) and total(g)==before)
    g._save_game("user://sisters.json")
    g._load_game("user://sisters.json")
    assert(total(g)==before and g.campaign.state.archive.has(a))
    g._switch_lineage(a)
    assert(g.player_id==a and g.mutation_points==2 and g.purchased.has("88"))
    assert(total(g)==before)
    g._switch_lineage(b)
    assert(g.mutation_points==3 and g.purchased.has("0"))
    g.player.position=E.LOCAL_CENTERS[0];g._advance_niches(0)
    # Accelerated demographic fixture: six genuine binary divisions, no census grants.
    for i in range(6):
        var parent: String="founder" if i==0 else ""
        if i==0: g._create_entity(parent,"",1,"pre_luca",g._base_traits(),E.LOCAL_CENTERS[0],false)
        else:
            for id in g.entities:
                if g.entities[id].ecotype=="founder": parent=id;break
        g._divide_npc(parent)
    assert(g.ecology.niches.site0.populations.founder==7)
    g.campaign.advance(20)
    assert(g.campaign.state.settlements["0|founder"].established)
    var census: int=total(g)
    g.player.position=Vector3(100,0,100);g._advance_niches(0)
    assert(total(g)==census)
    g.player.position=E.LOCAL_CENTERS[0];g._advance_niches(0);g._materialize_cohorts()
    assert(total(g)==census)
    # Mutation immediately after a niche crossing cannot duplicate census.
    var before_mutation: int=total(g)
    g.player.position=Vector3(100,0,100)
    g.purchased["fixture-crossing"]=true
    g._differentiate_lineage()
    assert(total(g)==before_mutation)
    g._advance_niches(0);assert(total(g)==before_mutation)
    g.campaign.open_map();assert(g.overlay.visible)
    assert(E.climate_fit({"thermotolerance":1.5},"thermal_fault")>E.climate_fit({},"thermal_fault"))
    print("PASS: real division commands, diverging sisters, exact census on demotion/return/load, persistent settlement and map")
    g.queue_free();quit()
