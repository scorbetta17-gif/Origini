extends SceneTree
const G=preload("res://src/cell_genome.gd")
const E=preload("res://src/evolution_progress.gd")
func _initialize() -> void: call_deferred("run")
func total(g: Node) -> int:
    var n: int=0
    for niche in g.ecology.niches.values():
        for count in niche.populations.values(): n+=int(count)
    return n
func run() -> void:
    var g=load("res://scenes/Main.tscn").instantiate()
    root.add_child(g);await process_frame;g.set_process(false);g.journey.skip()
    assert(g.entities.has("DONOR-0") and g.entities.has("DONOR-1"))
    var tr: Dictionary=g._base_traits()
    tr["evolution_capabilities"]={"bacteria":true,"prokaryotic_groups":true,"differentiated_groups":true}
    g.entities[g.player_id].traits=tr;g.entities[g.player_id].branch="bacteria"
    g.player.position=Vector3(-15,0,-9)
    g.evolution.unlocks=tr.evolution_capabilities.duplicate(true)
    for key in g.NEED: g.resources[key]=g.NEED[key]
    g.atp=90;g.cycle_age=35;g._divide_pressed();await create_timer(2.7).timeout
    assert(g.collectives.linked(g.player_id))
    g.collectives.advance(.2)
    assert(g.collectives.joints.get_child_count()>=3)
    assert(g.collectives.speed(g.player_id)<1)
    var key: String=g.collectives.group_of(g.player_id)
    var members: Array=g.collectives.state.groups[key]
    assert(g.collectives.role(members[0])!=g.collectives.role(members[1]))
    var before: int=total(g)
    g.collectives.fragment();assert(total(g)==before and g.collectives.state.groups.size()==2)
    g._save_game("user://filament.json");g._load_game("user://filament.json")
    assert(total(g)==before and g.collectives.state.groups.size()==2)
    # Accelerated host prerequisites, but actual normal cooperation/exchange commands.
    g.entities[g.player_id].branch="archaea"
    tr=G.grant(g._base_traits(),"surface_recognition",30,"test","archaea")
    tr=G.grant(tr,"membrane_transport",30,"test","archaea")
    g.entities[g.player_id].traits=tr
    g.player.position=g.entities["DONOR-1"].node.position+Vector3(1,0,0)
    g.atp=80;g.resources.carbon=24
    g._on_cooperate();assert(g.partner_id=="DONOR-1")
    for i in range(30): g._advance_phase_two(1)
    assert(g.phase2_progress.active_stable and g.phase2_progress.metabolites_exchanged>0)
    var host: String=g.player_id
    g._create_entity("sister-host","",1,"pre_luca",g._base_traits(),Vector3(100,0,100),false)
    g._switch_lineage("sister-host");g._advance_niches(0)
    assert(g.campaign.state.archive.has("DONOR-1"))
    g._switch_lineage(host)
    assert(g.partner_id=="DONOR-1" and g.entities.has("DONOR-1"))
    g._save_game("user://consortium.json");g._load_game("user://consortium.json")
    assert(g.partner_id=="DONOR-1" and g.phase2_progress.active_stable)
    g.evolution.divisions=40;g.mutation_points=20
    for entry in E.catalogue():
        if entry.id in ["cell_zero","rna_inheritance","translation","dna_archive","bioenergetics","luca","archaea","asgard_host","cytoskeleton","membrane_traffic","stable_consortium"]: g.evolution.unlocks[entry.id]=true
    g.evolution.stability.external=6
    # Evidence threshold uses existing campaign observations.
    g.evolution["external_stability"]=6
    g.evolution.evidence=g._evolution_context()
    g._unlock_capability("internal_symbiont")
    assert(g.evolution.unlocks.get("internal_symbiont",false))
    assert(g.evolution.endosymbiont.donor_id=="DONOR-1" and not g.entities.has("DONOR-1"))
    g._save_game("user://internal.json");g._load_game("user://internal.json")
    assert(g.evolution.endosymbiont.donor_id=="DONOR-1")
    print("PASS: real scission filament, differentiated roles, fragment census conservation, donor encounter normal cooperation exchange and internalization provenance")
    g.queue_free();quit()
