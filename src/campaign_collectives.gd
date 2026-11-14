extends Node
const G=preload("res://src/cell_genome.gd")
const E=preload("res://src/niche_ecology.gd")
var game: Node
var state: Dictionary={"groups":{},"next":1,"seeded":false}
var joints: Node3D
var visual_clock: float=0.0
func reset() -> void:
    state={"groups":{},"next":1,"seeded":false}
    if is_instance_valid(joints): joints.queue_free()
func restore(raw: Dictionary) -> void:
    reset()
    for key in state:
        if raw.has(key): state[key]=raw[key]
func seed_donors() -> void:
    if state.seeded or game.battle.active(): return
    state.seeded=true
    for i in range(2):
        var tr: Dictionary=game._base_traits()
        for gene in ["dna_stabilization","diderm_envelope","surface_recognition","membrane_transport"]:
            tr=G.grant(tr,gene,0,"popolazione_donatrice_indipendente","bacteria")
        tr["evolution_capabilities"]={"bacteria":true,"alpha_partner":true}
        var id: String="DONOR-"+str(i)
        game._create_entity(id,"",0,"bacteria",tr,E.LOCAL_CENTERS[2 if i==0 else 0]+Vector3(2,0,0),false,true)
        game.entities[id].evolution.unlocks={"cell_zero":true,"bacteria":true,"alpha_partner":true}
func group_of(id: String) -> String:
    for key in state.groups:
        if state.groups[key].has(id): return key
    return ""
func linked(id: String) -> bool: return not group_of(id).is_empty()
func division(parent: String, children: Array) -> void:
    if game.battle.active() or children.is_empty(): return
    var key: String=group_of(parent)
    var e: Dictionary=game.entities[children[0]]
    if key.is_empty():
        if e.branch!="bacteria" or not bool(e.traits.get("evolution_capabilities",{}).get("prokaryotic_groups",false)): return
        key="F-"+str(state.next);state.next=int(state.next)+1
        state.groups[key]=[]
    var members: Array=state.groups[key]
    var index: int=members.find(parent)
    if index>=0: members.remove_at(index)
    else: index=members.size()
    for child in children:
        members.insert(index,child);index+=1
    game._notice("Filamento clonale: giunzioni persistenti. MENU permette di frammentarlo.")
func fragment() -> void:
    var key: String=group_of(game.player_id)
    if key.is_empty(): game._notice("Nessun filamento collegato");return
    var members: Array=state.groups[key]
    var split: int=maxi(1,members.size()/2)
    var right: Array=members.slice(split)
    state.groups[key]=members.slice(0,split)
    var next: String="F-"+str(state.next);state.next=int(state.next)+1
    state.groups[next]=right
    for id in right:
        if game.entities.has(id): game.entities[id].node.position+=Vector3(2.5,0,0)
    game._advance_niches(0)
    game._close_overlay();game._notice("Frammento vitale separato: stessi individui, un nuovo luogo da colonizzare")
func role(id: String) -> String:
    var key: String=group_of(id)
    if key.is_empty() or not game.entities.has(id): return ""
    if not bool(game.entities[id].traits.get("evolution_capabilities",{}).get("differentiated_groups",false)): return ""
    return "ADESIONE" if state.groups[key].find(id)%2==0 else "ASSORBIMENTO"
func speed(id: String) -> float:
    if not linked(id): return 1.0
    return .58 if role(id)=="ADESIONE" else .72
func intake(id: String) -> float:
    if not linked(id): return 1.0
    var mat: bool=E.niche_id(game.entities[id].node.position)=="site2"
    # Benefit requires complementary living specialists; no free buff in open water.
    var complementary: bool=false
    for other in state.groups[group_of(id)]:
        if other!=id and role(other)!=role(id) and not role(other).is_empty(): complementary=true
    return (.88 if role(id)=="ADESIONE" else 1.08)*(1.22 if mat and complementary else 1.0)
func nearest_donor() -> String:
    var result: String=""
    var best: float=INF
    for id in game.entities:
        var e: Dictionary=game.entities[id]
        if e.branch!="bacteria" or not e.traits.get("adhesion",false) or int(e.traits.get("transporters",0))<1: continue
        var d: float=e.node.position.distance_squared_to(game.player.position)
        if d<best and id!=game.player_id: best=d;result=id
    # Materialize a known living archived donor without changing census.
    if result.is_empty():
        for id in game.campaign.state.archive.keys():
            var e: Dictionary=game.campaign.state.archive[id]
            if e.branch=="bacteria" and e.traits.get("adhesion",false) and int(e.traits.get("transporters",0))>0:
                if game.campaign.restore_individual(str(id)): return str(id)
    return result
func map_info() -> void:
    game._add_overlay_label("CONSORZIO: tappeto ricco e conteso oppure piana riparata, meno risorse. Adesine e trasportatori su entrambi, distanza <3,7; carbonio dell'ospite e ATP del donatore sostengono lo scambio.")
    var donor: String=nearest_donor()
    game._add_overlay_label("Donatore vivo: "+donor if not donor.is_empty() else "Nessun donatore compatibile noto: esplora altre nicchie e le popolazioni batteriche nella genealogia.")
    if not donor.is_empty():
        game._add_overlay_button("Segna donatore "+donor,seek_donor)
    if game.evolution.has("endosymbiont"):
        game._add_overlay_label("Provenienza interna: "+str(game.evolution.endosymbiont.donor_lineage)+(" · MITOCONDRIO INTEGRATO" if game.evolution.unlocks.get("mitochondrion",false) else " · SIMBIONTE INTERNO"))
func seek_donor() -> void:
    var id: String=nearest_donor()
    if id.is_empty(): game._notice("Popolazione estinta: cerca un'altra linea batterica compatibile");return
    game.cooperation_target=id
    game._close_overlay()
    game._notice("Raggiungi il donatore "+id+"; COOPERA per verificare adesione e scambio")
func advance(_dt: float) -> void:
    if game.battle.active(): return
    visual_clock+=_dt
    if visual_clock<.1: return
    _dt=visual_clock;visual_clock=0
    if is_instance_valid(joints): joints.queue_free()
    joints=Node3D.new();game.world_root.add_child(joints)
    for key in state.groups.keys():
        var living: Array=[]
        for id in state.groups[key]:
            if game.entities.has(id): living.append(id)
        state.groups[key]=living
        if living.is_empty(): state.groups.erase(key);continue
        var leader: String=game.player_id if living.has(game.player_id) else str(living[0])
        var anchor: Vector3=game.entities[leader].node.position
        var step: int=0
        for id in living:
            var e: Dictionary=game.entities[id]
            if id!=leader:
                step+=1
                var desired: Vector3=anchor+Vector3(step*1.65,0,0)
                e.node.position=e.node.position.lerp(desired,1.0-exp(-_dt*5))
            if not role(id).is_empty():
                var label:=Label3D.new();label.text="⊥" if role(id)=="ADESIONE" else "⋮";label.font_size=32;label.pixel_size=.012
                label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=e.node.position+Vector3(0,1.3,0);joints.add_child(label)
        for i in range(1,living.size()):
            var a: Vector3=game.entities[living[i-1]].node.position
            var b: Vector3=game.entities[living[i]].node.position
            if a.distance_to(b)<.01: continue
            var mesh:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
            cylinder.top_radius=.06;cylinder.bottom_radius=.06;cylinder.height=a.distance_to(b)
            mesh.mesh=cylinder;mesh.material_override=game._solid(Color(.35,.85,.72));joints.add_child(mesh)
            mesh.position=(a+b)*.5
            mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

func focus_position() -> Vector3:
    var key: String=group_of(game.player_id)
    if key.is_empty(): return game.player.position
    var center:=Vector3.ZERO
    var count: int=0
    for id in state.groups[key]:
        if game.entities.has(id): center+=game.entities[id].node.position;count+=1
    return center/maxi(1,count)
