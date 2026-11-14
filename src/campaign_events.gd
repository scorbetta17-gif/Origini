extends Node
const Genome=preload("res://src/cell_genome.gd")
const E=preload("res://src/niche_ecology.gd")
const REST_MIN: float=12.0
var game: Node
var state: Dictionary={}
var route: Node3D
func reset() -> void:
    state={"generations":[],"digestions":0,"last_detritus":[0,0,0],"next_current":-1.0,"current":{},"npc_cooldown":{},"variants":[]}
    if is_instance_valid(route): route.queue_free()
func restore(raw: Dictionary) -> void:
    reset()
    for key in state:
        if raw.has(key): state[key]=raw[key]
func dormant(id: String) -> bool:
    return not game.battle.active() and game.entities.has(id) and bool(game.entities[id].get("rest",{}).get("active",false))
func can_rest(id: String) -> bool:
    return bool(game.entities[id].traits.get("evolution_capabilities",{}).get("dormancy",false))
func resting_traits(id: String) -> Dictionary:
    var tr: Dictionary=game.entities[id].traits
    if not dormant(id): return tr
    var copy: Dictionary=tr.duplicate(true);copy["dormant"]=true
    return copy
func toggle_rest() -> void:
    var id: String=game.player_id
    if not can_rest(id):
        game._notice("Dormienza: capacità ereditabile, 2 PM dopo Ereditarietà RNA")
        game._on_evolution();return
    var e: Dictionary=game.entities[id]
    var r: Dictionary=e.get("rest",{"active":false,"since":-100.0})
    if bool(r.active) and game.t-float(r.since)<REST_MIN:
        game._notice("Risveglio disponibile fra %.0f s"%(REST_MIN-(game.t-float(r.since))));return
    if not bool(r.active) and game.atp<8:
        game._notice("Servono 8 ATP per entrare in dormienza");return
    if not bool(r.active): game.atp-=4
    r={"active":not bool(r.active),"since":game.t}
    e.rest=r
    e.velocity=Vector3.ZERO;e.intent_velocity=Vector3.ZERO
    game.move_vector=Vector2.ZERO;game.selected_target_id="";game.selected_substrate=null
    game._close_overlay()
    game._notice("Dormiente: consumi ridotti, resta il rischio termico. Puoi seguire una sorella." if r.active else "Risveglio: movimento e ciclo ripresi")
func on_digest(patch: Node3D) -> void:
    state.digestions=int(state.digestions)+1
    if not state.generations.has(game.generation): state.generations.append(game.generation)
    state.last_detritus=[patch.position.x,patch.position.y,patch.position.z]
    if float(state.next_current)<0: state.next_current=game.t+20
    if state.generations.size()==2: game._notice("Detrito sfruttato in più generazioni: osserva le nuove discendenti rivali")
func variation(parent: Dictionary, traits: Dictionary, at: Vector3, generation: int, index: int) -> Dictionary:
    if not bool(parent.external) or index!=0 or state.generations.size()<2: return traits
    var target:=Vector3(state.last_detritus[0],state.last_detritus[1],state.last_detritus[2])
    if at.distance_to(target)>26: return traits
    var available: bool=false
    for patch in game.substrates:
        if is_instance_valid(patch) and patch.position.distance_to(target)<8: available=true
    if not available or Genome.has(traits,"hydrolase_secretion"): return traits
    var variant: Dictionary=Genome.grant(traits,"hydrolase_secretion",generation,"variante_figlia_detrito_locale",str(parent.branch))
    variant["uptake"]=maxf(.6,float(variant.get("uptake",1))-.06)
    state.variants.append({"parent_lineage":parent.ecotype,"generation":generation,"at":[at.x,at.z]})
    game._notice("Una nuova discendente rivale produce idrolasi: compete per il detrito")
    return variant
func npc_target(id: String, fallback: Vector3) -> Vector3:
    if dormant(id): return Vector3.ZERO
    var e: Dictionary=game.entities[id]
    if not Genome.has(e.traits,"hydrolase_secretion"): return fallback
    if float(e.energy)<8 or float(e.biomass)>=57: return fallback
    var closest: Node3D
    var distance: float=12
    for patch in game.substrates:
        var d: float=Vector2(patch.position.x-e.node.position.x,patch.position.z-e.node.position.z).length()
        if d<distance: closest=patch;distance=d
    if is_instance_valid(closest):
        if distance<=1.55: game._digest_for(closest,id)
        return closest.position-e.node.position if distance>1.55 else Vector3.ZERO
    return fallback
func start_current() -> void:
    if game.battle.active() or not state.current.is_empty(): return
    var start: Vector3=game.player.position+Vector3(-7,0,4)
    var end: Vector3=start+Vector3(14,0,0)
    var candidates: Array=game.nutrients.duplicate()
    candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.node.position.distance_squared_to(start)<b.node.position.distance_squared_to(start))
    var selected: Dictionary={}
    for n in candidates.slice(0,12): selected[str(n.uid)]=[n.node.position.x,n.node.position.z]
    state.current={"elapsed":0.0,"duration":18.0,"start":[start.x,start.z],"end":[end.x,end.z],"particles":selected}
    state.next_current=game.t+150
    game._notice("Corrente: segui le frecce o intercetta il riparo. L’adesione riduce la deriva.")
    rebuild_route()
func carried(uid: int) -> bool:
    return not state.current.is_empty() and state.current.particles.has(str(uid)) and float(state.current.elapsed)<float(state.current.duration)
func rebuild_route() -> void:
    if is_instance_valid(route): route.queue_free()
    if state.current.is_empty(): return
    route=Node3D.new();game.world_root.add_child(route)
    var c: Dictionary=state.current
    for i in range(8):
        var label:=Label3D.new();label.text="›";label.font_size=80;label.pixel_size=.018
        label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
        label.position=Vector3(lerpf(c.start[0],c.end[0],i/7.0),.1,c.start[1])
        route.add_child(label)
    for i in range(3):
        var rock:=MeshInstance3D.new();var shape:=SphereMesh.new()
        shape.radius=.75;shape.height=.65;shape.radial_segments=7;shape.rings=3
        rock.mesh=shape;rock.material_override=game._solid(Color(.15,.29,.32))
        rock.position=Vector3(c.end[0]+1.7,-.3,c.end[1]+(i-1)*1.1);route.add_child(rock)
    var label:=Label3D.new();label.text="RIPARO · DEPOSIZIONE";label.font_size=34;label.pixel_size=.012
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=Vector3(c.end[0],.8,c.end[1]);route.add_child(label)
func advance(dt: float) -> void:
    if game.battle.active(): return
    for id in game.entities:
        var e: Dictionary=game.entities[id]
        if dormant(id):
            var stock: Dictionary=game.resources if id==game.player_id else e.resources
            var energy: float=game.atp if id==game.player_id else float(e.energy)
            var at: Vector3=e.node.position
            if game.t-float(e.rest.since)>=REST_MIN and energy>=18 and game._temperature_at(at)<=39 and float(stock.carbon)>=8:
                e.rest.active=false
                if id==game.player_id: game._notice("Condizioni migliorate: la cellula si risveglia")
        if dormant(id) and not e.node.has_node("Dormienza"):
            var label:=Label3D.new();label.name="Dormienza";label.text="◌ Z Z";label.font_size=42;label.pixel_size=.014;label.position=Vector3(0,1.4,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;e.node.add_child(label)
        if e.node.has_node("Dormienza"): e.node.get_node("Dormienza").visible=dormant(id)
    if float(state.next_current)>=0 and game.t>=float(state.next_current) and state.current.is_empty(): start_current()
    if state.current.is_empty(): return
    if not is_instance_valid(route): rebuild_route()
    var c: Dictionary=state.current
    c.elapsed=float(c.elapsed)+dt
    var progress: float=clampf(float(c.elapsed)/float(c.duration),0,1)
    for n in game.nutrients:
        if not c.particles.has(str(n.uid)): continue
        var origin: Array=c.particles[str(n.uid)]
        var deposited: bool=int(n.uid)%2==0
        var endpoint: Vector2=Vector2(c.end[0],c.end[1])+Vector2(0 if deposited else 4,float(int(n.uid)%5)*.32)
        var at: Vector2=Vector2(origin[0],origin[1]).lerp(endpoint,progress)
        n.node.position.x=at.x;n.node.position.z=at.y
    if progress<1:
        for id in game.entities:
            var e: Dictionary=game.entities[id]
            if absf(e.node.position.z-float(c.start[1]))<3 and e.node.position.x>float(c.start[0])-2 and e.node.position.x<float(c.end[0])+2:
                var anchored: bool=bool(e.traits.get("adhesion",false)) or bool(e.traits.get("eps",false)) or (game.collectives.linked(str(id)) and E.niche_id(e.node.position)=="site2")
                var sheltered: bool=Vector2(e.node.position.x-float(c.end[0]),e.node.position.z-float(c.end[1])).length()<2.0
                e.node.position.x+=dt*(.08 if anchored or sheltered else .48)
    if c.elapsed>c.duration+15:
        state.current={}
        if is_instance_valid(route): route.queue_free()
