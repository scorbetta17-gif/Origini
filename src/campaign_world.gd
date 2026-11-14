extends Node
## Persistent objectives and individual templates; all counts belong to Ecology.
const E = preload("res://src/niche_ecology.gd")
var game: Node
var state: Dictionary = {}
var marker: MeshInstance3D
func reset() -> void:
    state = {"archive":{},"settlements":{},"verify_seconds":20.0,"destination":-1,"sisters_seen":false}
func restore(raw: Dictionary) -> void:
    reset()
    for key in state:
        if raw.has(key) and (typeof(raw[key])==typeof(state[key]) or (raw[key] is float and state[key] is int)): state[key]=raw[key]
func snapshot(id: String) -> Dictionary:
    var e: Dictionary = game.entities[id]
    var record: Dictionary = {}
    for key in e:
        if key not in ["node","velocity","intent_velocity","census_position"]: record[key]=e[key]
    var at: Vector3 = e.node.position
    record.pos = [at.x,at.y,at.z]
    record["census"] = E.niche_id(at)
    return record.duplicate(true)
func archive(id: String) -> void:
    state.archive[id]=snapshot(id)
    for rec in game.genealogy:
        if rec.id==id:
            rec["ecotype"]=game.entities[id].ecotype
            rec["status"]="coorte"
            rec["last_state"]=state.archive[id].duplicate(true)
func represented(niche: String, lineage: String) -> int:
    var n: int = 0
    for e in game.entities.values():
        if e.ecotype==lineage and E.niche_id(e.node.position)==niche: n+=1
    return n
func restore_individual(id: String) -> bool:
    if not state.archive.has(id): return false
    var r: Dictionary = state.archive[id]
    var niche: String = str(r.census)
    var count: int = int(game.ecology.niches[niche].populations.get(r.ecotype,0))
    if count<=represented(niche,r.ecotype): return false
    game.ecology_syncing=true
    game._create_entity(id,r.parent,int(r.generation),r.branch,r.traits,Vector3(r.pos[0],r.pos[1],r.pos[2]),false,bool(r.external))
    game.ecology_syncing=false
    for key in r:
        if key not in ["pos","census"]: game.entities[id][key]=r[key]
    # _create_entity appends a record; preserve the historical node exactly once.
    var seen: bool = false
    for i in range(game.genealogy.size()-1,-1,-1):
        if game.genealogy[i].id==id:
            if not seen: seen=true
            else: game.genealogy.remove_at(i)
    state.archive.erase(id)
    return true
func follow(id: String) -> String:
    if game.entities.has(id): return id
    if restore_individual(id): return id
    if state.archive.has(id):
        var r: Dictionary=state.archive[id]
        for other in game.entities:
            if game.entities[other].ecotype==r.ecotype and E.niche_id(game.entities[other].node.position)==r.census: return other
    game._notice("Nessuna rappresentante viva disponibile: rimane l’ultimo stato noto")
    return ""
func materialize(niche: String) -> void:
    for id in state.archive.keys():
        if game.entities.size()>=game.npc_population_cap: break
        var r: Dictionary=state.archive[id]
        if r.census==niche: restore_individual(id)
func after_division(parent: String, children: Array) -> void:
    for id in children:
        if game.entities.has(id):
            game.entities[id]["sister_ids"]=children.duplicate()
            for rec in game.genealogy:
                if rec.id==id: rec["ecotype"]=game.entities[id].ecotype
    if (not game.journey.active()) and not state.sisters_seen and children.size()==2:
        state.sisters_seen=true
        game._notice("Due sorelle vive: LINEA permette di seguirle e specializzarle separatamente")
func advance(dt: float) -> void:
    if game.battle.active(): return
    for id in state.archive:
        var r: Dictionary=state.archive[id]
        var alive: bool=int(game.ecology.niches[r.census].populations.get(r.ecotype,0))>0
        for rec in game.genealogy:
            if rec.id==id:
                rec.alive=alive
                rec.status="coorte" if alive else "estinta"
                if not alive: rec.cause="estinzione della coorte"
    for i in range(3):
        var at: Vector3=E.LOCAL_CENTERS[i]
        var pops: Dictionary=game.ecology.niches["site"+str(i)].populations
        for lineage in pops:
            var key: String=str(i)+"|"+str(lineage)
            var record: Dictionary=state.settlements.get(key,{"held":0.0,"previous":int(pops[lineage]),"trend":0,"established":false})
            record.held=float(record.held)+dt if int(pops[lineage])>=E.CONSOLIDATION_COUNT else 0.0
            record.trend=int(pops[lineage])-int(record.previous)
            record.previous=int(pops[lineage])
            record.established=float(record.held)>=float(state.verify_seconds)
            state.settlements[key]=record
        for key in state.settlements.keys():
            if str(key).begins_with(str(i)+"|") and not pops.has(str(key).get_slice("|",1)):
                state.settlements[key].held=0.0
                state.settlements[key].established=false
                state.settlements[key].previous=0
    if int(state.destination)>=0:
        var at: Vector3=E.LOCAL_CENTERS[int(state.destination)]
        if not is_instance_valid(marker):
            marker=MeshInstance3D.new()
            var ring:=TorusMesh.new(); ring.inner_radius=6.8;ring.outer_radius=7.0
            marker.mesh=ring
            marker.material_override=game._solid(Color(.4,.8,.65))
            game.world_root.add_child(marker)
        marker.position=at+Vector3(0,.08,0)
        marker.visible=true
func travel(index: int) -> void:
    state.destination=index
    game._close_overlay()
    game._notice("Destinazione segnata sul fondale: "+game.habitats.TITLES[index])
func open_map() -> void:
    game._cache_current()
    game._open_overlay("MAPPA · POPOLAZIONI", "Fonda la tua prima popolazione · obiettivo facoltativo")
    game._add_overlay_label("DIVIDI sul posto, lascia discendenti e torna. Consolidamento: %d individui per %d s; il censimento continua anche lontano."%[E.CONSOLIDATION_COUNT,int(state.verify_seconds)])
    var map = preload("res://src/niche_map.gd").new()
    map.game=game
    map.custom_minimum_size=Vector2(280,250)
    game.overlay_list.add_child(map)
    var lineage: String=game.entities[game.player_id].ecotype
    for i in range(3):
        var summary: Dictionary=E.summary(game.ecology,lineage,E.LOCAL_CENTERS[i])
        var key: String=str(i)+"|"+lineage
        var held: float=float(state.settlements.get(key,{}).get("held",0))
        game._add_overlay_label("%s · %s\nTuoi: %d · totale: %d · %s · persistenza %.0f/%ds"%[game.habitats.TITLES[i],["carbonio disperso · rischio basso","nucleotidi/lipidi · rischio termico","amminoacidi · concorrenti"][i],summary.population,summary.total_population,game._niche_label(summary.status),minf(held,state.verify_seconds),int(state.verify_seconds)])
        for other in game.ecology.niches["site"+str(i)].populations:
            var count: int=game.ecology.niches["site"+str(i)].populations[other]
            game._add_overlay_label("  %s: %d · Δ %d"%[other,count,int(state.settlements.get(str(i)+"|"+str(other),{}).get("trend",0))])
        game._add_overlay_button("Segna "+game.habitats.TITLES[i],travel.bind(i))
    game._add_overlay_button("Segui una linea nella genealogia",game._on_genealogy)
