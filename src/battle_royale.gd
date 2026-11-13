extends Node
const rules = preload("res://src/battle_rules.gd")
const Genome = preload("res://src/cell_genome.gd")
const PATH: String = "user://battle_royale_082.json"
var game: Node
var state: Dictionary = {}
var visuals: Node3D
var current_ring: Node3D
var warning_ring: Node3D
var caches: Array[Node3D] = []
var radar: Control

func active() -> bool:
    return bool(state.get("enabled",false))

func reset() -> void:
    state = {}
    if is_instance_valid(visuals): visuals.queue_free()
    if is_instance_valid(radar): radar.queue_free()
    caches.clear()

func choose() -> void:
    game._open_overlay("BATTLE ROYALE", "Sopravvivenza ecologica · partita contro 12 IA")
    game._add_overlay_label("20 minuti massimi di gioco attivo. Fronti di temperatura e pH, preavviso di 90 s e rifugio verde sulla minimappa. Il cerchio oro indica il prossimo rifugio. La tua morte conclude la partita.")
    game._add_overlay_label("Tre depositi arancioni: scorte condivise e finite, una porzione ogni 4 s a contatto. Il resto del rifugio contiene nutrienti meno concentrati. Si vince eliminando i rivali, anche in alleanza; al limite di tempo contano HP, ATP e raccolta, non le uccisioni.")
    game._add_overlay_label("La campagna viene salvata prima di entrare. Questa modalità ha un salvataggio separato. Scegli una specializzazione iniziale:")
    for i in range(4):
        var tradeoff: String = ["+25% attacco / -22% assorbimento","+35% difesa / -18% mobilità","+30% mobilità / -15% difesa","+15% assorbimento / -22% attacco"][i]
        game._add_overlay_button(rules.NAMES[i]+"\n"+tradeoff,start.bind(i))
    game._add_overlay_button("Riprendi Battle Royale",game._load_game.bind(PATH))

func profile(index: int) -> Dictionary:
    var traits: Dictionary = game._base_traits()
    for locus in ["dna_stabilization","monoderm_envelope","hydrolase_secretion","surface_recognition"]:
        traits = Genome.grant(traits,locus,3,"arena","bacteria")
    var values: Array = [[1.25,.85,.95,.78],[.78,1.35,.82,1.0],[.90,.85,1.30,1.0],[.78,1.10,.95,1.15]][index]
    for k in range(4): traits[["attack","defense","motility","uptake"][k]] = values[k]
    if index==1: traits = Genome.grant(traits,"eps_biosynthesis",3,"arena","bacteria")
    if index==2: traits = Genome.grant(traits,"flagellar_motor",3,"arena","bacteria")
    traits["arena_profile"] = index
    return traits

func start(index: int) -> void:
    if not active(): game._save_game()
    game._new_game()
    game._close_overlay()
    state = rules.origin()
    state.profile = clampi(index,0,3)
    game.world_radius = 40.0
    var e: Dictionary = game.entities[game.player_id]
    e.traits = profile(state.profile)
    e.branch = "bacteria"
    e.generation = 3
    game.generation = 3
    e.node.setup(e.traits,e.branch,true)
    game.ecological_profiles[e.ecotype] = e.traits.duplicate(true)
    for record in game.genealogy:
        if record.id==game.player_id:
            record.traits = e.traits.duplicate(true)
            record.branch = "bacteria"
            record.generation = 3
    game.evolution = game._legacy_evolution(e)
    e.evolution = game.evolution.duplicate(true)
    game.mutation_points = 6.0
    state.teams[game.player_id] = "player"
    for i in range(12):
        var id: String = "BR-%03d" % (i+1)
        var a: float = TAU*i/12.0
        game._create_entity(id,"",3,"bacteria",profile(i%4),Vector3(cos(a)*22,0,sin(a)*22),false,true)
        state.teams[id] = id
        game.entities[id].energy = 66.0
    # Two cooperative contestants form a visible, non-aggressive pair.
    state.pacts["BR-004"] = "BR-008"
    state.pacts["BR-008"] = "BR-004"
    for n in game.nutrients: n.node.queue_free()
    game.nutrients.clear()
    for i in range(190): spawn_food()
    game._reset_substrates([],true)
    rebuild()
    game._save_game()
    game._refresh_hud()
    game._notice("Battle Royale · rifugio verde, depositi arancioni")

func team(id: String) -> String:
    return str(state.get("teams",{}).get(id,id))

func friendly(a: String, b: String) -> bool:
    if not active(): return false
    var ta: String = team(a)
    var tb: String = team(b)
    return ta==tb or str(state.pacts.get(ta,""))==tb

func nearby_partner(id: String) -> String:
    var pair: String = str(state.pacts.get(team(id),""))
    if pair.is_empty() or not game.entities.has(id): return ""
    for other in game.entities:
        if team(other)==pair and game.entities[other].node.position.distance_to(game.entities[id].node.position)<=3.0:
            return other
    return ""

func cooperate() -> void:
    var my_team: String = team(game.player_id)
    if state.pacts.has(my_team):
        var other: String = state.pacts[my_team]
        state.pacts.erase(other)
        state.pacts.erase(my_team)
        game._notice("Alleanza sciolta")
        return
    var best: String = ""
    var distance: float = 5.0
    for id in game.entities:
        if friendly(id,game.player_id) or state.pacts.has(team(id)): continue
        if int(game.entities[id].traits.get("arena_profile",0))==0: continue
        var d: float = game.entities[id].node.position.distance_to(game.player.position)
        if d<distance:
            best = id
            distance = d
    if best.is_empty():
        game._notice("Avvicinati entro 5 m a una cellula non predatrice libera")
        return
    state.pacts[my_team] = team(best)
    state.pacts[team(best)] = my_team
    game._notice("Alleanza: protezione e recupero HP entro 3 m · costa ATP")

func spawn_food() -> void:
    var z: Dictionary = rules.zone(state.elapsed)
    var a: float = game.rng.randf()*TAU
    var r: float = sqrt(game.rng.randf())*z.radius*.95
    var at: Vector3 = z.center+Vector3(cos(a)*r,.29,sin(a)*r)
    game._create_nutrient(game.Balance.NUTRIENT_CYCLE[game.rng.randi_range(0,game.Balance.NUTRIENT_CYCLE.size()-1)],at)

func needs_supply(id: String) -> bool:
    var e: Dictionary = game.entities[id]
    if (game.atp if id==game.player_id else float(e.energy))<85: return true
    var reserves: Dictionary = game.resources if id==game.player_id else e.resources
    for key in game.NEED:
        if float(reserves.get(key,0))<float(game.NEED[key]): return true
    return false

func npc_goal(id: String, fallback: Vector3) -> Vector3:
    var at: Vector3 = game.entities[id].node.position
    var z: Dictionary = rules.zone(state.elapsed)
    # Anticipate the next front before seeking food or chasing prey.
    var goal: Vector3 = z.next_center if z.warning else z.center
    var radius: float = z.next_radius if z.warning else z.radius
    if at.distance_to(goal)>radius-2.0: return goal-at
    # Energy emergencies outrank following allies or travelling to a rich cache.
    # Food must be reached and picked up normally; no energy is granted here.
    var energy: float = game.atp if id==game.player_id else float(game.entities[id].energy)
    if energy<25:
        var nearest: float = 25.0
        var food := Vector3.ZERO
        for n in game.nutrients:
            if n.kind not in ["carbon","detritus"]: continue
            var p: Vector3 = n.node.position
            if p.distance_to(goal)>radius-1: continue
            var distance: float = at.distance_to(p)
            if distance<nearest:
                food = p-at
                nearest = distance
        if nearest<25: return food
    var pair: String = str(state.pacts.get(team(id),""))
    if not pair.is_empty():
        for other in game.entities:
            if team(other)==pair and at.distance_to(game.entities[other].node.position)>2.5:
                return game.entities[other].node.position-at
    if int(game.entities[id].traits.get("arena_profile",0))!=0:
        for other in game.entities:
            if friendly(id,other): continue
            if int(game.entities[other].traits.get("arena_profile",-1))==0:
                var away: Vector3 = at-game.entities[other].node.position
                if away.length()<3.5: return away
    # Rich caches compete with ordinary foraging; no teleporting or free NPC intake.
    var best: Vector3 = fallback
    var distance: float = 15.0
    if needs_supply(id):
        for i in range(3):
            var offset: Vector3 = rules.depot(state.elapsed,i)-at
            if state.stocks[i]>0 and offset.length()<distance:
                best = offset if offset.length()>1.2 else Vector3.ZERO
                distance = offset.length()
    return best

func advance(dt: float) -> void:
    if not active() or not str(state.result).is_empty(): return
    state.elapsed = minf(rules.DURATION,float(state.elapsed)+dt)
    var z: Dictionary = rules.zone(state.elapsed)
    if int(state.depot_phase)!=int(z.stage):
        state.depot_phase = z.stage
        state.stocks = [60,60,60]
    if z.warning and int(state.announced)!=int(z.stage):
        state.announced = z.stage
        game._notice("Fronte in arrivo: raggiungi il rifugio oro entro %d s" % int(ceil(z.seconds)))
    state.spawn_credit = float(state.spawn_credit)+dt
    while state.spawn_credit>=.32:
        state.spawn_credit -= .32
        # Stranded particles must not fill the whole budget outside the refuge.
        for i in range(game.nutrients.size()-1,-1,-1):
            if rules.exposure(state.elapsed,game.nutrients[i].node.position)>5:
                game.nutrients[i].node.queue_free()
                game.nutrients.remove_at(i)
        if game.nutrients.size()<220: spawn_food()
    for id in game.entities.keys():
        if not game.entities.has(id): continue
        var e: Dictionary = game.entities[id]
        var controlled: bool = id==game.player_id
        var energy: float = game.atp if controlled else float(e.energy)
        var health: float = game.hp if controlled else float(e.hp)
        # NPCs use the same reserve-funded repair as the player, not free HP.
        if not controlled and health>0 and health<60 and energy>0 and float(state.elapsed)-float(state.repair.get(id,-13.5))>=13.5:
            var total: float = 0.0
            for key in game.TYPES: total += float(e.resources.get(key,0))
            if total>=8:
                for key in game.TYPES: e.resources[key] = float(e.resources[key])*.9
                health = minf(100,health+30)
                state.repair[id] = state.elapsed
        var together: bool = not nearby_partner(id).is_empty() and energy>5
        health -= rules.damage(state.elapsed,e.node.position,e.traits,together)*dt
        if together:
            health = minf(100,health+.12*dt)
            energy = maxf(0,energy-.08*dt)
        if controlled:
            game.hp = maxf(0,health)
            game.atp = energy
        else:
            e.hp = health
            e.energy = energy
            e.atp = energy
        if health<=0:
            if controlled:
                finish("sconfitta")
                return
            game._remove_entity(id,"fronte ambientale")
            continue
        if float(state.elapsed)-float(state.harvest.get(id,-4.0))>=4.0 and needs_supply(id):
            for i in range(3):
                if state.stocks[i]>0 and e.node.position.distance_to(rules.depot(state.elapsed,i))<1.9:
                    game._award_bundle({"carbon":4,"amino":3,"lipid":3,"nucleic":2,"biomass":4,"atp":6},controlled,id)
                    state.stocks[i] -= 1
                    state.harvest[id] = state.elapsed
                    state.packets[team(id)] = int(state.packets.get(team(id),0))+1
                    break
    update_visuals()
    if game.hp<=0:
        finish("sconfitta")
        return
    var opponents: int = 0
    for id in game.entities:
        if not friendly(id,game.player_id): opponents += 1
    if opponents==0:
        finish("vittoria")
    elif float(state.elapsed)>=rules.DURATION:
        var mine: float = rules.score(game.hp,game.atp,int(state.packets.get(team(game.player_id),0)))
        var rival: float = -1
        for id in game.entities:
            if friendly(id,game.player_id): continue
            var e: Dictionary = game.entities[id]
            rival = maxf(rival,rules.score(e.hp,e.energy,int(state.packets.get(team(id),0))))
        finish("pareggio" if absf(mine-rival)<.01 else "vittoria" if mine>rival else "sconfitta")

func finish(result: String) -> void:
    state.result = result
    game._save_game()
    game._open_overlay("BATTLE ROYALE · "+result.to_upper(),"Partita conclusa · la campagna è conservata separatamente")
    game._add_overlay_label("Durata: %d:%02d · HP %.0f · ATP %.0f · punteggio %.1f" % [int(state.elapsed)/60,int(state.elapsed)%60,game.hp,game.atp,rules.score(game.hp,game.atp,int(state.packets.get(team(game.player_id),0)))])
    game._add_overlay_button("Nuovo Battle Royale",choose)
    game._add_overlay_button("Torna alla campagna",game._load_game.bind(game.SAVE_PATH))

func hud_text() -> String:
    var z: Dictionary = rules.zone(state.elapsed)
    var remaining: int = int(ceil(z.remaining))
    var message: String = "BR %02d:%02d · %d cellule · rifugio %.0f m" % [remaining/60,remaining%60,game.entities.size(),z.radius]
    if z.warning: message += " · FRONTE tra %d s" % int(ceil(z.seconds))
    elif rules.exposure(state.elapsed,game.player.position)>0:
        var env: Dictionary = rules.environment(state.elapsed,game.player.position)
        message += " · %.0f°C / pH %.1f" % [env.temperature,env.ph]
    return message

func dashboard() -> void:
    game._open_overlay("ARENA · SITUAZIONE",hud_text())
    var env: Dictionary = rules.environment(state.elapsed,game.player.position)
    game._add_overlay_label("Fronte %s · ambiente locale %.1f °C / pH %.1f. Sono valori di una simulazione ludica." % [env.front,env.temperature,env.ph])
    game._add_overlay_label("Verde: rifugio attuale. Oro: prossimo rifugio, annunciato 90 secondi prima. Bianco: tu. Azzurro: alleati. Rosso: rivali. Arancione: depositi con scorte.")
    for i in range(3):
        game._add_overlay_label("Deposito %d: %d porzioni · distanza %.0f m" % [i+1,int(state.stocks[i]),game.player.position.distance_to(rules.depot(state.elapsed,i))])
    game._add_overlay_label("Punteggio a tempo: 60% HP + 30% ATP + raccolta (massimo 10 punti). Nessun punto per uccisione. Un patto reciproco protegge del 10% e rigenera 0,12 HP/s entro 3 m, consumando 0,08 ATP/s. La difesa riduce il danno ambientale fino al 30%, senza immunità.")
    game._add_overlay_label("La divisione dà PM ma non una seconda vita. Le cellule figlie sono alleate; non puoi assumerne il controllo dopo la morte.")
    game._add_overlay_button("Statistiche raccolta e popolazioni",game._on_statistics)
    game._add_overlay_button("Alleati / sciogli il patto",cooperate)

func ring(color: Color) -> MeshInstance3D:
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for i in range(129): mesh.surface_add_vertex(Vector3(cos(TAU*i/128.0),.02,sin(TAU*i/128.0)))
    mesh.surface_end()
    var node := MeshInstance3D.new()
    node.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color
    node.material_override = mat
    visuals.add_child(node)
    return node

func rebuild() -> void:
    if is_instance_valid(visuals): visuals.queue_free()
    if is_instance_valid(radar): radar.queue_free()
    caches.clear()
    if not active(): return
    visuals = Node3D.new()
    game.add_child(visuals)
    current_ring = ring(Color(.2,.9,.7))
    warning_ring = ring(Color(1,.7,.2))
    for i in range(3):
        var marker: Node3D = ring(Color(1,.55,.12))
        marker.scale = Vector3(1.8,1,1.8)
        caches.append(marker)
    radar = preload("res://src/battle_radar.gd").new()
    radar.battle = self
    radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game.hud.add_child(radar)
    update_visuals()

func update_visuals() -> void:
    if not is_instance_valid(visuals): return
    var z: Dictionary = rules.zone(state.elapsed)
    current_ring.position = z.center
    current_ring.scale = Vector3(z.radius,1,z.radius)
    warning_ring.position = z.next_center
    warning_ring.scale = Vector3(z.next_radius,1,z.next_radius)
    warning_ring.visible = z.warning
    for i in range(3):
        caches[i].position = rules.depot(state.elapsed,i)
        caches[i].visible = state.stocks[i]>0
    var viewport: Vector2 = game.get_viewport().get_visible_rect().size
    var factor: float = minf(viewport.x/720.0,viewport.y/1280.0)
    radar.scale = Vector2.ONE*factor
    radar.position = Vector2(viewport.x-166*factor,438*factor)
    radar.queue_redraw()
