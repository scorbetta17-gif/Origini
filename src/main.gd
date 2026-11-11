extends Node3D
## ORIGINI 0.67 — prima ricostruzione grafica e giocabile con Godot 4.x.
## Scene 3D reali, camera isometrica, fenotipi procedurali, UI mobile.

const CellScript = preload("res://src/cell_visual.gd")
const GenomeScript = preload("res://src/cell_genome.gd")
const PhaseScript = preload("res://src/phase_two_progress.gd")
const OceanScript = preload("res://src/primordial_ocean.gd")
const TreeScript = preload("res://src/mutation_tree.gd")
const LineageScript = preload("res://src/lineage_view.gd")
const JoystickScript = preload("res://src/virtual_joystick.gd")
const SAVE_PATH = "user://origini_067.json"
# Biomi termici localizzati: il resto dell'oceano resta temperato e spoglio.
const THERMAL_SOURCES = [Vector2(-11.0, 3.0), Vector2(16.0, -14.0)]
const THERMAL_AMPLITUDE = [92.0, 62.0]
const THERMAL_DECAY = [13.0, 9.0]
const NEED = {"carbon": 24.0, "amino": 15.0, "lipid": 12.0, "nucleic": 8.0, "biomass": 65.0}
const TYPES = ["carbon", "amino", "lipid", "nucleic"]
const TYPE_COLORS = {
    "carbon": Color(1.0, 0.65, 0.26), "amino": Color(0.74, 0.45, 1.0),
    "lipid": Color(0.98, 0.86, 0.44), "nucleic": Color(0.37, 0.87, 1.0)
}
const TRAIT_POOL = [
    ["Efficienza di trasporto", "uptake", 0.09, "metabolism", -0.03],
    ["Membrana rinforzata", "defense", 0.12, "motility", -0.05],
    ["Mobilita amplificata", "motility", 0.12, "metabolism", -0.07],
    ["Idrolasi extracellulari", "attack", 0.12, "metabolism", -0.05],
    ["Catabolismo efficace", "metabolism", 0.12, "defense", -0.03],
    ["Replicazione piu fedele", "mutation", -0.06, "metabolism", -0.02],
    ["Mutatore transitorio", "mutation", 0.13, "defense", -0.05],
    ["Rivestimento flessibile", "motility", 0.08, "defense", -0.10],
    ["Proteasi specializzate", "attack", 0.16, "metabolism", -0.08],
    ["Scambio superficiale", "uptake", 0.11, "defense", -0.05],
    ["Chaperoni", "defense", 0.07, "metabolism", -0.03],
    ["Adesione reversibile", "defense", 0.06, "motility", -0.04],
    ["Proteostasi", "defense", 0.09, "uptake", -0.04],
    ["Regolazione dell'ATP", "metabolism", 0.10, "uptake", -0.05],
    ["Secrezione ridotta", "metabolism", 0.06, "attack", -0.13],
    ["Pori di membrana", "uptake", 0.10, "defense", -0.06],
    ["Curvatura cellulare", "uptake", 0.06, "defense", -0.04],
    ["Dissipazione termica", "defense", 0.08, "metabolism", -0.04],
    ["Turnover lipidico", "defense", 0.09, "uptake", -0.03],
    ["Metabolismo parsimonioso", "metabolism", 0.09, "motility", -0.08],
    ["Segnale di chemotassi", "motility", 0.07, "metabolism", -0.03],
    ["Membrana porosa", "uptake", 0.12, "defense", -0.08],
    ["Parete compatta", "defense", 0.14, "motility", -0.08],
    ["Molecole adesive", "defense", 0.05, "uptake", 0.03],
    ["Proteasi ad ampio spettro", "attack", 0.09, "uptake", 0.03],
    ["Accrescimento lento", "defense", 0.07, "motility", -0.03],
    ["Risposta redox", "metabolism", 0.08, "defense", 0.02],
    ["Riparazione accurata", "mutation", -0.08, "metabolism", -0.04],
    ["Elevata variabilita", "mutation", 0.12, "defense", -0.04],
    ["Variante quasi neutra", "uptake", 0.008, "motility", -0.006]
]

var rng := RandomNumberGenerator.new()
var camera: Camera3D
var player: CellVisual
var player_id: String = "C-000"
var entities: Dictionary = {}
var genealogy: Array = []
var nutrients: Array = []
var ambient_particles: Array = []
var next_id: int = 1
var generation: int = 0
var resources: Dictionary = {"carbon": 6.0, "amino": 4.0, "lipid": 3.0, "nucleic": 1.0, "biomass": 23.0}
var atp: float = 66.0
var hp: float = 100.0
var skill_cooldown: float = 0.0
var regeneration_cooldown: float = 0.0
var mutation_points: int = 0
var purchased: Dictionary = {}
var phase_two: float = 0.0 # Legacy alias for progress bar
var phase2_progress: Dictionary = PhaseScript.empty()
var partner_id: String = ""
var metabolism_particles: Array[MeshInstance3D] = []
var metabolism_particle_material: StandardMaterial3D
var division_options: Array = []
var selected_target_id: String = ""
var selected_nutrient: MeshInstance3D = null
var nutrient_respawn: float = 0.0
var world_age: float = 0.0
var last_external_arrival: float = -60.0
var camera_offset := Vector3(0.0, 7.5, 8.7)
var camera_focus: bool = false
var world_radius: float = 25.0
var attack_mode: String = ""
var move_vector: Vector2 = Vector2.ZERO
var touch_index: int = -1
var touch_origin: Vector2 = Vector2.ZERO
var is_paused: bool = false
var t: float = 0.0
var eco_tick: float = 0.0
var autosave_timer: float = 0.0
var hud: Control
var overlay: ColorRect
var overlay_scroll: ScrollContainer
var overlay_list: VBoxContainer
var title_label: Label
var status_label: Label
var objective_label: Label
var tips_label: Label
var scission_bar: ProgressBar
var hp_bar: ProgressBar
var atp_bar: ProgressBar
var joystick
var scission_button: Button
var buttons: Dictionary = {}
var tree_view: MutationTree
var lineage_view: LineageView
var world_root: Node3D
var nutrient_root: Node3D
var cells_root: Node3D

func _ready() -> void:
    rng.randomize()
    _make_3d_scene()
    _build_ui()
    _setup_metabolic_visuals()
    _new_game()
    get_viewport().size_changed.connect(_layout_ui)

func _new_game() -> void:
    for child in cells_root.get_children():
        cells_root.remove_child(child)
        child.queue_free()
    for child in nutrient_root.get_children():
        nutrient_root.remove_child(child)
        child.queue_free()
    entities.clear()
    genealogy.clear()
    nutrients.clear()
    player = null
    resources = {"carbon": 6.0,"amino":4.0,"lipid":3.0,"nucleic":1.0,"biomass":23.0}
    atp = 66.0
    hp = 100.0
    mutation_points = 0
    purchased.clear()
    player_id = "C-000"
    next_id = 1
    generation = 0
    partner_id = ""
    phase_two = 0.0
    phase2_progress = PhaseScript.empty()
    t = 0.0
    world_age = 0.0
    last_external_arrival = -60.0
    nutrient_respawn = 0.0
    eco_tick = 0.0
    autosave_timer = 0.0
    regeneration_cooldown = 0.0
    skill_cooldown = 0.0
    selected_target_id = ""
    selected_nutrient = null
    attack_mode = ""
    division_options.clear()
    is_paused = false
    camera_focus = false
    camera_offset = Vector3(0,7.5,8.7)
    if is_instance_valid(camera):
        camera.fov = 34.0
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(true)
        joystick.reset_input()
    var starter: Dictionary = _base_traits()
    _create_entity("C-000", "", 0, "pre_luca", starter, Vector3.ZERO, true)
    # Materiali abiotici: nessun frammento di DNA o detrito cellulare prima delle cellule.
    for i in range(44):
        _create_nutrient(TYPES[i % 4], Vector3(rng.randf_range(-22.0,22.0),.19,rng.randf_range(-22.0,22.0)))
    _close_overlay()
    _refresh_hud()

func _base_traits() -> Dictionary:
    var starter: Dictionary = {"motility": 1.0, "attack": 1.0, "defense": 1.0, "mutation": 0.0,
        "metabolism": 1.0, "uptake": 1.0, "archaella": 0, "dna": false, "eps": false,
        "adhesion": false, "flagella": 0, "envelope": "none", "mutations": [], "signature": 0.0,
        "thermotolerance": 0.0, "pili": 0, "receptors": 0, "protease": 0, "vesicles": 0,
        "transporters": 0, "elongation": 0.0, "genome":GenomeScript.origin()}
    return GenomeScript.normalize(starter,"pre_luca")

func _make_3d_scene() -> void:
    world_root = Node3D.new()
    world_root.name = "Biomi_3D"
    add_child(world_root)
    nutrient_root = Node3D.new()
    nutrient_root.name = "Nutrienti_3D"
    add_child(nutrient_root)
    cells_root = Node3D.new()
    cells_root.name = "Cellule_3D"
    add_child(cells_root)
    var we := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.023, 0.052, 0.064)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.44, 0.61, 0.61)
    env.ambient_light_energy = .88
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, 28, -15)
    sun.light_color = Color(0.56, 0.76, 0.79)
    sun.light_energy = 1.02
    add_child(sun)
    camera = Camera3D.new()
    # Prospettiva vera: la dimensione apparente varia con la distanza.
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 34.0
    camera.near = .08
    camera.far = 115.0
    camera.position = camera_offset
    add_child(camera)
    camera.look_at(Vector3(0,0,0))
    camera.current = true
    var cell_fill := OmniLight3D.new()
    cell_fill.light_color = Color(.79,.88,.82)
    cell_fill.light_energy = .41
    cell_fill.omni_range = 9.0
    cell_fill.shadow_enabled = false
    cell_fill.position = Vector3(-3.3,2.7,-3.8)
    camera.add_child(cell_fill)
    var biome: Node3D = OceanScript.new()
    biome.name = "Fondale_minimale"
    world_root.add_child(biome)
    biome.call("setup",rng)

func _solid(color: Color, emission: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    color.a = alpha
    mat.albedo_color = color
    mat.roughness = 0.55
    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission
    if alpha < .99:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return mat

func _pebble(pos: Vector3, dimension: Vector3, tint: Color, emissive: float = 0.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 10
    mesh.rings = 6
    var inst := MeshInstance3D.new()
    inst.mesh = mesh
    inst.position = pos
    inst.scale = dimension
    inst.material_override = _solid(tint, emissive)
    world_root.add_child(inst)
    return inst

func _rock(pos: Vector3, size: float, color: Color) -> void:
    _pebble(Vector3(pos.x,pos.y+size*.22,pos.z), Vector3(size*1.3,size*.48,size), color)
    if rng.randf() < .33:
        _pebble(Vector3(pos.x+size*.18,size*.58,pos.z), Vector3(size*.40,size*.59,size*.46), color.lightened(.10))

func _vent(pos: Vector3, height: float) -> void:
    # Piccola fumarola minerale: niente lava o luci arancioni al suolo.
    var chimney := CylinderMesh.new()
    chimney.bottom_radius = .36
    chimney.top_radius = .20
    chimney.height = height
    chimney.radial_segments = 11
    var part := MeshInstance3D.new()
    part.mesh = chimney
    part.position = pos+Vector3(0,height*.5,0)
    part.material_override = _solid(Color(.16,.19,.18))
    world_root.add_child(part)
    _pebble(pos+Vector3(0,height,0),Vector3(.22,.06,.24),Color(.24,.28,.25))
    for i in range(10):
        var plume := _pebble(pos+Vector3(rng.randf_range(-.35,.35),height+rng.randf_range(.18,1.7),rng.randf_range(-.35,.35)),Vector3.ONE*rng.randf_range(.018,.045),Color(.29,.40,.39))
        ambient_particles.append(plume)

func _create_nutrient(kind: String, at: Vector3) -> void:
    var sphere := SphereMesh.new()
    sphere.radius = .13 if kind == "detritus" else (.085 if kind != "nucleic" else .067)
    sphere.height = .145
    sphere.radial_segments = 12
    sphere.rings = 7
    var node := MeshInstance3D.new()
    node.mesh = sphere
    node.position = at
    node.material_override = _solid(Color(.39,.37,.31) if kind == "detritus" else TYPE_COLORS[kind].lerp(Color(.24,.33,.32),.70), .0)
    nutrient_root.add_child(node)
    nutrients.append({"kind": kind, "node": node, "origin_y": at.y, "bob": rng.randf_range(0,TAU)})

func _create_entity(id: String, parent: String, gen: int, branch: String, traits: Dictionary, at: Vector3, controlled: bool = false, external: bool = false) -> void:
    if entities.has(id):
        return
    var inherited: Dictionary = GenomeScript.normalize(traits,branch)
    var node: CellVisual = CellScript.new()
    cells_root.add_child(node)
    node.position = at
    node.setup(inherited, branch, controlled)
    node.set_growth(.72 if branch == "pre_luca" and gen == 0 else .78)
    var inventory: Dictionary = {"carbon":6.0,"amino":4.0,"lipid":3.0,"nucleic":1.0,"biomass":24.0}
    entities[id] = {"node":node,"parent":parent,"generation":gen,"branch":branch,
        "traits":inherited.duplicate(true),"external":external,"age":0.0,
        "biomass":24.0,"energy":46.0,"hp":100.0,"atp":65.0,
        "resources":inventory,"points":0,"purchased":{},"fission_count":0,
        "phase2_progress":PhaseScript.empty()}
    genealogy.append({"id":id,"parent":parent,"generation":gen,"branch":branch,
        "name":("Origine" if id == "C-000" else ("Estranea " + id if external and parent == "" else id)),
        "alive":true,"status":"viva","cause":"","traits":inherited.duplicate(true),"external":external})
    if controlled:
        player = node
        player_id = id
        generation = gen

func _cache_current() -> void:
    if not entities.has(player_id):
        return
    var e: Dictionary = entities[player_id]
    e["hp"] = hp
    e["atp"] = atp
    e["resources"] = resources.duplicate(true)
    e["points"] = mutation_points
    e["purchased"] = purchased.duplicate(true)
    e["biomass"] = float(resources.get("biomass",22.0))
    e["phase2_progress"] = phase2_progress.duplicate(true)

func _activate_lineage(id: String) -> void:
    if not entities.has(id):
        return
    if is_instance_valid(player):
        player.set_selected(false)
    player_id = id
    var e: Dictionary = entities[id]
    player = e["node"]
    player.set_selected(true)
    generation = int(e["generation"])
    hp = clampf(float(e.get("hp",100.0)),0.0,100.0)
    atp = clampf(float(e.get("atp",65.0)),0.0,100.0)
    resources = e.get("resources", {}).duplicate(true)
    for key in NEED:
        resources[key] = clampf(float(resources.get(key,0.0)),0.0,float(NEED[key])*1.1)
    mutation_points = int(e.get("points",0))
    purchased = e.get("purchased", {}).duplicate(true)
    phase2_progress = PhaseScript.normalize(e.get("phase2_progress",{}))
    partner_id = str(phase2_progress.get("partner_id",""))
    phase_two = float(phase2_progress["contact_seconds"])
    if partner_id != "" and (not entities.has(partner_id) or str(e.get("branch","")) != "archaea"):
        partner_id = ""
        phase2_progress = PhaseScript.release(phase2_progress)
    selected_target_id = ""
    selected_nutrient = null
    attack_mode = ""
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(true)
        joystick.reset_input()

func _remove_entity(id: String, cause: String) -> void:
    if not entities.has(id):
        return
    var rec: Dictionary = entities[id]
    var at: Vector3 = rec["node"].position if is_instance_valid(rec["node"]) else Vector3.ZERO
    if is_instance_valid(rec["node"]):
        rec["node"].queue_free()
    entities.erase(id)
    for entry in genealogy:
        if str(entry["id"]) == id:
            entry["alive"] = false
            entry["status"] = "divisa" if cause == "scissione" else "estinta"
            entry["cause"] = cause
            break
    if id == selected_target_id:
        selected_target_id = ""
        attack_mode = ""
    if id == partner_id:
        partner_id = ""
        phase_two = 0.0
        phase2_progress = PhaseScript.release(phase2_progress)
    if cause != "scissione":
        # I detriti cellulari hanno un'origine tracciabile.
        for i in range(3):
            _create_nutrient("detritus", at + Vector3(rng.randf_range(-.7,.7),.28,rng.randf_range(-.7,.7)))
        if bool(rec["traits"].get("dna",false)):
            _create_nutrient("detritus", at + Vector3(.25,.28,-.15))

func _register_death(id: String, reason: String = "morte") -> void:
    _remove_entity(id,reason)

func _process(delta: float) -> void:
    if is_paused or not is_instance_valid(player) or not entities.has(player_id):
        return
    delta = minf(delta,.07)
    t += delta
    regeneration_cooldown = maxf(0.0,regeneration_cooldown-delta)
    skill_cooldown = maxf(0.0,skill_cooldown-delta)
    autosave_timer += delta
    var direction: Vector2 = Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direction.y += 1.0
    direction += move_vector
    if direction.length() > 0.12:
        selected_target_id = ""
        selected_nutrient = null
        attack_mode = ""
        _move_player(direction.normalized(),delta)
    elif selected_target_id != "" or is_instance_valid(selected_nutrient):
        _follow_attack(delta)
    atp = maxf(0.0,atp-delta*.28)
    var player_temperature: float = _temperature_at(player.position)
    var tolerance: float = 43.0+18.0*float(entities[player_id]["traits"].get("thermotolerance",0.0))
    if player_temperature > tolerance:
        hp = maxf(0.0,hp-delta*(player_temperature-tolerance)*.075)
    if atp < 1.0:
        hp = maxf(0.0,hp-delta*.55)
    # Cresce con la biomassa, ma la dimensione massima e' limitata.
    player.set_growth(.72 + .41 * clampf((float(resources["biomass"])-23.0)/42.0,0.0,1.0))
    camera.position = camera.position.lerp(player.position+camera_offset,minf(1.0,delta*3.2))
    camera.look_at(player.position+Vector3(0,.55,0))
    for n in nutrients:
        if is_instance_valid(n["node"]):
            n["node"].position.y = float(n["origin_y"]) + sin(t*1.8+float(n["bob"]))*0.04
    _collect_nearby()
    eco_tick += delta
    if eco_tick >= .22:
        _update_ecosystem(eco_tick)
        eco_tick = 0.0
    # Phase 2: riconoscimento, adesione, metaboliti, stabilita e discendenza.
    _advance_phase_two(delta)
    _update_metabolic_visuals()
    _cache_current()
    if hp <= 0:
        _game_over()
    if autosave_timer > 24.0:
        _save_game()
        autosave_timer = 0.0
    _refresh_hud()

func _setup_metabolic_visuals() -> void:
    # Traccianti discreti del flusso di metaboliti: non rappresentano un
    # ponte cellulare permanente, un mitocondrio o fusione di membrane.
    var orb := SphereMesh.new()
    orb.radius = .044
    orb.height = .088
    orb.radial_segments = 10
    orb.rings = 6
    metabolism_particle_material = StandardMaterial3D.new()
    metabolism_particle_material.albedo_color = Color(.52,.77,.67,.72)
    metabolism_particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    metabolism_particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    metabolism_particle_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    metabolism_particles.clear()
    for i in range(4):
        var n := MeshInstance3D.new()
        n.name = "Metabolite_%d" % i
        n.mesh = orb
        n.material_override = metabolism_particle_material
        n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        n.visible = false
        world_root.add_child(n)
        metabolism_particles.append(n)

func _update_metabolic_visuals() -> void:
    var active: bool = entities.has(player_id) and partner_id != "" and entities.has(partner_id)
    if active:
        var archaeal: Dictionary = entities[player_id]["traits"]
        var bacterial: Dictionary = entities[partner_id]["traits"]
        active = bool(phase2_progress.get("bonded",false)) and PhaseScript.can_exchange(archaeal,bacterial)
        active = active and player.position.distance_to(entities[partner_id]["node"].position) <= PhaseScript.EXCHANGE_RADIUS
    for i in range(metabolism_particles.size()):
        var n: MeshInstance3D = metabolism_particles[i]
        n.visible = active
        if not active:
            continue
        var bacterial_pos: Vector3 = entities[partner_id]["node"].position
        var alpha: float = fposmod(t*.27+float(i)/float(metabolism_particles.size()),1.0)
        n.position = player.position.lerp(bacterial_pos,alpha)+Vector3(0,.72+sin(alpha*PI)*.24,0)
        n.scale = Vector3.ONE*(.72+.28*sin(alpha*PI))

func _advance_phase_two(delta: float) -> void:
    if not entities.has(player_id) or str(entities[player_id]["branch"]) != "archaea":
        return
    for id in entities:
        if str(id) == player_id:
            continue
        if str(entities[id]["branch"]) != "bacteria":
            continue
        var distance: float = player.position.distance_to(entities[id]["node"].position)
        phase2_progress = PhaseScript.observe(phase2_progress,"bacteria",str(id),distance)
    if partner_id == "":
        return
    if not entities.has(partner_id) or str(entities[partner_id]["branch"]) != "bacteria":
        partner_id = ""
        phase2_progress = PhaseScript.release(phase2_progress)
        phase_two = 0.0
        return
    var partner: Dictionary = entities[partner_id]
    var distance: float = player.position.distance_to(partner["node"].position)
    var before_stable: bool = bool(phase2_progress.get("stable",false))
    var before_exchange: bool = bool(phase2_progress.get("exchanged",false))
    var result: Dictionary = PhaseScript.advance(phase2_progress,delta,distance,
        entities[player_id]["traits"],partner["traits"],
        float(resources.get("carbon",0.0)),float(partner.get("energy",0.0)))
    phase2_progress = result["progress"]
    resources["carbon"] = maxf(0.0,float(resources["carbon"])-float(result["carbon_cost"]))
    atp = minf(100.0,atp+float(result["atp_gain"]))
    partner["energy"] = clampf(float(partner["energy"])+float(result["bacterial_energy_delta"]),0.0,85.0)
    partner["biomass"] = minf(72.0,float(partner["biomass"])+float(result["bacterial_biomass_gain"]))
    phase_two = float(phase2_progress["contact_seconds"])
    if not bool(phase2_progress["bonded"]):
        partner_id = ""
    if bool(phase2_progress["exchanged"]) and not before_exchange:
        _notice("Scambio metabolico riuscito: 12 secondi effettivi")
    if bool(phase2_progress["stable"]) and not before_stable:
        _notice("Consorzio stabile! Trasmettilo a una figlia tramite scissione")

func _temperature_at(where: Vector3) -> float:
    # Modello locale e ludico del gradiente, non ricostruzione di un oceano storico.
    var result: float = 29.0
    for i in range(THERMAL_SOURCES.size()):
        var xy: Vector2 = THERMAL_SOURCES[i]
        var distance_squared: float = Vector2(where.x-xy.x,where.z-xy.y).length_squared()
        result += THERMAL_AMPLITUDE[i]*exp(-distance_squared/THERMAL_DECAY[i])
    return result

func _toggle_focus() -> void:
    camera_focus = not camera_focus
    # Tre quarti: il volume 3D diventa leggibile anche nelle mutazioni laterali.
    camera_offset = Vector3(1.3,2.1,3.4) if camera_focus else Vector3(0,7.5,8.7)
    camera.fov = 38.0 if camera_focus else 34.0
    buttons["focus"].text = "MONDO" if camera_focus else "CELLULA"

func _move_player(direction: Vector2, delta: float) -> void:
    var traits: Dictionary = entities[player_id]["traits"]
    var motility: float = float(traits.get("motility", 1.0))
    var archaella: int = int(traits.get("archaella",0))
    var motorized: bool = archaella > 0 or int(traits.get("flagella",0)) > 0
    var tethered: bool = int(traits.get("pili",0)) > 0
    var speed: float = 3.40 * motility * (1.0 if motorized else (.87 if tethered else .78))
    player.position.x += direction.x * speed * delta
    player.position.z += direction.y * speed * delta
    player.position.x = clampf(player.position.x, -25,25)
    player.position.z = clampf(player.position.z, -25,25)
    if direction.length() > .2:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.y,direction.x), delta*4)

func _consume_nutrient(index: int, controlled: bool, cell_id: String = "") -> void:
    if index < 0 or index >= nutrients.size():
        return
    var n: Dictionary = nutrients[index]
    var kind: String = str(n["kind"])
    if controlled:
        var uptake: float = float(entities[player_id]["traits"].get("uptake",1.0))
        if kind == "detritus":
            resources["carbon"] = minf(float(NEED["carbon"])*1.1,float(resources["carbon"])+2.0*uptake)
            resources["amino"] = minf(float(NEED["amino"])*1.1,float(resources["amino"])+1.5*uptake)
        else:
            resources[kind] = minf(float(NEED[kind])*1.1,float(resources[kind])+2.15*uptake)
        resources["biomass"] = minf(float(NEED["biomass"])*1.1,float(resources["biomass"])+1.45*uptake)
        atp = minf(100.0,atp+1.35*float(entities[player_id]["traits"].get("metabolism",1.0)))
    elif entities.has(cell_id):
        var e: Dictionary = entities[cell_id]
        e["biomass"] = minf(72.0,float(e["biomass"])+2.3*float(e["traits"].get("uptake",1.0)))
        e["energy"] = minf(85.0,float(e["energy"])+4.0)
    if is_instance_valid(n["node"]):
        n["node"].queue_free()
    nutrients.remove_at(index)

func _collect_nearby() -> void:
    for i in range(nutrients.size()-1,-1,-1):
        var n: Dictionary = nutrients[i]
        if not is_instance_valid(n["node"]):
            nutrients.remove_at(i)
            continue
        if player.position.distance_to(n["node"].position) > 1.08:
            continue
        var kind: String = str(n["kind"])
        if kind != "detritus" and float(resources[kind]) >= float(NEED[kind])*1.1-.001 and float(resources["biomass"])>=float(NEED["biomass"])*1.1-.001:
            continue
        _consume_nutrient(i,true)
    # Redistribuzione limitata; i detriti cellulari non emergono spontaneamente.
    if nutrients.size() < 85:
        nutrient_respawn += eco_tick + .016
        if nutrient_respawn >= .22:
            _create_nutrient(TYPES[rng.randi_range(0,3)], Vector3(rng.randf_range(-23,23),.29,rng.randf_range(-23,23)))
            nutrient_respawn = 0.0

func _nearest_nutrient(at: Vector3, max_distance: float) -> int:
    var result: int = -1
    var best: float = max_distance
    for j in range(nutrients.size()):
        var node: MeshInstance3D = nutrients[j]["node"]
        if not is_instance_valid(node):
            continue
        var distance: float = at.distance_to(node.position)
        if distance < best:
            result = j
            best = distance
    return result

func _update_ecosystem(dt: float) -> void:
    var ids: Array = entities.keys()
    for id in ids:
        if id == player_id or not entities.has(id):
            continue
        var e: Dictionary = entities[id]
        var c: CellVisual = e["node"]
        if not is_instance_valid(c):
            continue
        e["age"] = float(e["age"])+dt
        var local_temperature: float = _temperature_at(c.position)
        var limit_temperature: float = 43.0+18.0*float(e["traits"].get("thermotolerance",0.0))
        if local_temperature > limit_temperature:
            e["hp"] = float(e["hp"])-dt*(local_temperature-limit_temperature)*.075
            if float(e["hp"]) <= 0.0:
                _remove_entity(str(id),"stress termico")
                continue
        e["energy"] = maxf(0.0,float(e["energy"])-dt*.19)
        var target_idx: int = _nearest_nutrient(c.position,6.5)
        var dir: Vector3 = Vector3(sin(t*.39+float(str(id).hash()%77)),0,cos(t*.31+float(str(id).hash()%63)))
        if target_idx >= 0:
            dir = nutrients[target_idx]["node"].position-c.position
            dir.y = 0
        var speed: float = 1.0*clampf(float(e["traits"].get("motility",1.0)),.55,2.6)
        if dir.length() > .02:
            c.position += dir.normalized()*dt*speed
        c.position.x = clampf(c.position.x,-24.0,24.0)
        c.position.z = clampf(c.position.z,-24.0,24.0)
        if target_idx >= 0 and target_idx < nutrients.size():
            if c.position.distance_to(nutrients[target_idx]["node"].position) < .78:
                _consume_nutrient(target_idx,false,str(id))
        c.set_growth(.72+.41*clampf((float(e["biomass"])-24.0)/45.0,0.0,1.0))
        if float(e["biomass"]) >= 64.0 and float(e["energy"]) >= 28.0 and int(e["generation"]) < 24 and entities.size() < 20:
            _divide_npc(str(id))
            continue
        # Competizione emergente: necessita di capacita' litica ereditaria.
        if int(e["generation"]) >= 3 and GenomeScript.has(e["traits"],"hydrolase_secretion") and float(e["energy"]) > 8.0:
            var nearest_id: String = ""
            var best: float = 1.12
            for other_id in entities:
                if other_id == id:
                    continue
                var other: Dictionary = entities[other_id]
                var dist: float = c.position.distance_to(other["node"].position)
                if dist < best:
                    nearest_id = str(other_id)
                    best = dist
            if nearest_id != "":
                if nearest_id == player_id:
                    hp = maxf(0.0,hp-dt*5.0/maxf(.5,float(entities[player_id]["traits"].get("defense",1.0))))
                else:
                    var prey: Dictionary = entities[nearest_id]
                    prey["hp"] = float(prey["hp"])-dt*5.0/maxf(.5,float(prey["traits"].get("defense",1.0)))
                    if float(prey["hp"]) <= 0:
                        _remove_entity(nearest_id,"predazione")
                        e["biomass"] = minf(72.0,float(e["biomass"])+9.0)
                        e["energy"] = minf(85.0,float(e["energy"])+12.0)
    # I partner batterici sono linee indipendenti, non figli della tua Archaea.
    if generation >= 3 and entities[player_id]["branch"] == "archaea" and not _has_external_bacteria() and t-last_external_arrival >= 20.0:
        _create_external_bacterium()

func _has_external_bacteria() -> bool:
    for id in entities:
        if bool(entities[id].get("external",false)) and entities[id]["branch"] == "bacteria":
            return true
    return false

func _create_external_bacterium() -> void:
    last_external_arrival = t
    var traits: Dictionary = _base_traits()
    traits = GenomeScript.grant(traits,"dna_stabilization",0,"linea_esterna","bacteria")
    traits = GenomeScript.grant(traits,"diderm_envelope",0,"linea_esterna","bacteria")
    var new_id: String = "E-%03d" % next_id
    next_id += 1
    _create_entity(new_id,"",0,"bacteria",traits,player.position+Vector3(rng.randf_range(5,8),0,rng.randf_range(-4,4)),false,true)

func _divide_npc(id: String) -> void:
    if not entities.has(id):
        return
    var parent: Dictionary = entities[id]
    var pos: Vector3 = parent["node"].position
    var gen: int = int(parent["generation"])+1
    var branch: String = str(parent["branch"])
    var traits: Dictionary = parent["traits"]
    var external: bool = bool(parent["external"])
    var was_partner: bool = partner_id == id
    var previous_phase: float = phase_two
    var older_purchased: Dictionary = parent["purchased"].duplicate(true)
    _remove_entity(id,"scissione")
    var first_id: String = ""
    for i in range(2):
        var new_id: String = ("E-%03d" if external else "C-%03d") % next_id
        next_id += 1
        var mutated: Dictionary = _mutated_traits(traits,gen,branch)
        _create_entity(new_id,id,gen,branch,mutated,pos+Vector3(-.70 if i == 0 else .70,0,.45 if i == 0 else -.45),false,external)
        var child: Dictionary = entities[new_id]
        child["biomass"] = 24.0
        child["energy"] = float(parent["energy"])*.45
        child["hp"] = maxf(35.0,float(parent["hp"])*.8)
        child["purchased"] = older_purchased.duplicate(true)
        child["points"] = int(parent["points"])
        if i == 0:
            first_id = new_id
    if was_partner and first_id != "":
        partner_id = first_id
        phase_two = previous_phase

func _mutated_traits(source: Dictionary, child_generation: int, branch: String) -> Dictionary:
    var traits: Dictionary = GenomeScript.normalize(source,branch)
    # Mutazioni minori: piccoli modificatori numerici, nessuna struttura 3D inventata.
    if rng.randf() < clampf(.64+float(traits.get("mutation",0.0)),.10,.95):
        var mutation: Array = TRAIT_POOL[rng.randi_range(0,TRAIT_POOL.size()-1)]
        var key: String = str(mutation[1])
        var side: String = str(mutation[3])
        var base_key: float = 0.0 if key == "mutation" else 1.0
        var base_side: float = 0.0 if side == "mutation" else 1.0
        traits[key] = clampf(float(traits.get(key,base_key))+float(mutation[2]), -.30 if key == "mutation" else .35,.35 if key == "mutation" else 4.0)
        traits[side] = clampf(float(traits.get(side,base_side))+float(mutation[4]), -.30 if side == "mutation" else .35,.35 if side == "mutation" else 4.0)
        var history: Array = traits.get("mutations",[]).duplicate()
        history.append(str(mutation[0]))
        traits["mutations"] = history
    # Mutazioni maggiori: nuovi loci ereditabili, che sono anche la sorgente dei moduli fisici.
    if child_generation >= 2 and rng.randf() < .28:
        var options: Array[String] = GenomeScript.random_candidates(branch,traits)
        if not options.is_empty():
            var locus: String = options[rng.randi_range(0,options.size()-1)]
            traits = GenomeScript.grant(traits,locus,child_generation,"major_mutation",branch)
    return GenomeScript.express(traits,branch)

func _can_divide() -> bool:
    for key in NEED:
        if float(resources[key]) < float(NEED[key]) - 0.001:
            return false
    return atp >= 30.0

func _divide_pressed() -> void:
    if not _can_divide():
        _notice("Mancano sostanze o ATP per la scissione")
        return
    _cache_current()
    division_options.clear()
    var parent: Dictionary = entities[player_id]
    for i in range(2):
        var traits: Dictionary = _mutated_traits(parent["traits"],generation+1,str(parent["branch"]))
        var next_branch: String = str(parent["branch"])
        var highlight: String = "Variazione ereditaria"
        if next_branch == "pre_luca" and generation >= 1 and i == 0:
            next_branch = "luca"
            traits = GenomeScript.grant(traits,"dna_stabilization",generation+1,"milestone_ludica",next_branch)
            highlight = "Major: stabilizzazione del DNA (locus ereditabile)"
        elif next_branch == "luca" and generation >= 2:
            next_branch = "bacteria" if i == 0 else "archaea"
            var envelope_locus: String = "monoderm_envelope" if i == 0 else "archaeal_envelope"
            traits = GenomeScript.grant(traits,envelope_locus,generation+1,"divergenza_ludica",next_branch)
            highlight = "Major: involucro Bacteria" if i == 0 else "Major: involucro Archaea"
        elif generation >= 3 and i == 1 and rng.randf() < .36:
            traits = GenomeScript.grant(traits,"surface_recognition",generation+1,"major_mutation",next_branch)
            traits = GenomeScript.grant(traits,"eps_biosynthesis",generation+1,"major_mutation",next_branch)
            highlight = "Major: riconoscimento cellulare e EPS"
        division_options.append({"traits":traits,"branch":next_branch,"name":highlight})
    for option in division_options:
        var tr: Dictionary = option["traits"]
        var events: Array = tr.get("genome",{}).get("history",[])
        for event in events:
            if int(event.get("generation",-1)) == generation+1:
                var locus: String = str(event.get("locus",""))
                if GenomeScript.GENE_INFO.has(locus):
                    option["name"] = "MAJOR: "+str(GenomeScript.GENE_INFO[locus]["name"])
    _open_overlay("SCISSIONE CELLULARE", "Scegli una discendente. La sorella segue la propria linea.")
    _add_overlay_button("FIGLIA A · %s" % str(division_options[0]["name"]),func():_choose_daughter(0))
    _add_overlay_button("FIGLIA B · %s" % str(division_options[1]["name"]),func():_choose_daughter(1))
    _add_overlay_label("Le mutazioni sono casuali; la tua scelta seleziona la discendenza.")

func _choose_daughter(choice: int) -> void:
    if choice < 0 or choice > 1 or division_options.size() != 2 or not entities.has(player_id):
        _close_overlay()
        return
    _cache_current()
    var old_id: String = player_id
    var parent: Dictionary = entities[old_id]
    var old_pos: Vector3 = parent["node"].position
    var gen: int = generation+1
    var old_partner: String = partner_id
    var old_phase: float = phase_two
    var old_resources: Dictionary = resources.duplicate(true)
    var old_hp: float = hp
    var old_atp: float = atp
    var old_points: int = mutation_points
    var old_owned: Dictionary = purchased.duplicate(true)
    _remove_entity(old_id,"scissione")
    var chosen_id: String = ""
    for i in range(2):
        var id: String = "C-%03d" % next_id
        next_id += 1
        var option: Dictionary = division_options[i]
        _create_entity(id,old_id,gen,str(option["branch"]),option["traits"],old_pos+Vector3(-.74 if i==0 else .74,0,.20),false)
        var new_cell: Dictionary = entities[id]
        var split_stock: Dictionary = old_resources.duplicate(true)
        for key in TYPES:
            split_stock[key] = float(old_resources[key])*.44
        split_stock["biomass"] = 23.0
        new_cell["resources"] = split_stock
        new_cell["atp"] = old_atp*.55
        new_cell["hp"] = maxf(30.0,old_hp*.85)
        new_cell["energy"] = old_atp*.55
        new_cell["points"] = old_points+2
        new_cell["purchased"] = old_owned.duplicate(true)
        if i == choice:
            chosen_id = id
    division_options.clear()
    _activate_lineage(chosen_id)
    partner_id = old_partner if entities[player_id]["branch"] == "archaea" and entities.has(old_partner) else ""
    phase_two = old_phase if partner_id != "" else 0.0
    _close_overlay()
    _save_game()
    _notice("Scissione completata · %s · +2 punti" % chosen_id)

func _on_regen() -> void:
    if hp >= 99.99 or regeneration_cooldown > 0:
        _notice("Rigenerazione non necessaria o in ricarica")
        return
    var total: float = float(resources["carbon"])+float(resources["amino"])+float(resources["lipid"])+float(resources["nucleic"])
    if total < 8.0:
        _notice("Occorrono almeno 8 unita di riserve organiche")
        return
    for k in TYPES:
        resources[k] = float(resources[k]) * .9
    hp = minf(100.0,hp+30.0)
    regeneration_cooldown = 13.5
    _cache_current()
    _notice("+30 HP · consumato il 10% delle riserve")

func _on_skill(mode: String) -> void:
    if skill_cooldown > 0.0:
        _notice("Abilita' in ricarica")
        return
    var genome_traits: Dictionary = entities[player_id]["traits"]
    if not GenomeScript.has(genome_traits,"hydrolase_secretion"):
        _notice("Manca il locus maggiore per enzimi proteolitici")
        return
    if mode == "lysis" and not GenomeScript.has(genome_traits,"surface_recognition"):
        _notice("La lisi selettiva richiede anche recettori di riconoscimento")
        return
    var attack_strength: float = float(genome_traits.get("attack",1.0))
    var best: String = ""
    var dist: float = 8.0
    if mode == "lysis" or attack_strength >= 1.10:
        for id in entities:
            if id == player_id:
                continue
            var d: float = player.position.distance_to(entities[id]["node"].position)
            if d < dist:
                dist = d
                best = str(id)
    selected_target_id = best
    selected_nutrient = null
    attack_mode = mode
    if best == "" and mode == "enzyme":
        var best_index: int = _nearest_nutrient(player.position,9.0)
        if best_index >= 0:
            selected_nutrient = nutrients[best_index]["node"]
            _notice("Idrolisi automatica: materiale organico vicino")
            return
    if best == "":
        attack_mode = ""
        _notice("Nessun bersaglio nella portata di ricerca")
        return
    _notice("Bersaglio: %s · %s" % [best,mode.to_upper()])

func _follow_attack(delta: float) -> void:
    if selected_target_id == "" and is_instance_valid(selected_nutrient):
        var direction: Vector3 = selected_nutrient.position-player.position
        if direction.length() > 1.05:
            _move_player(Vector2(direction.x,direction.z).normalized(),delta)
        else:
            var nutrient_index: int = -1
            for i in range(nutrients.size()):
                if nutrients[i]["node"] == selected_nutrient:
                    nutrient_index = i
                    break
            if nutrient_index >= 0:
                _consume_nutrient(nutrient_index,true)
            selected_nutrient = null
            attack_mode = ""
        return
    if not entities.has(selected_target_id):
        selected_target_id = ""
        attack_mode = ""
        return
    var target: Dictionary = entities[selected_target_id]
    var prey_node: CellVisual = target["node"]
    if not is_instance_valid(prey_node):
        selected_target_id = ""
        attack_mode = ""
        return
    var delta_3d: Vector3 = prey_node.position-player.position
    if delta_3d.length() > 1.45:
        _move_player(Vector2(delta_3d.x,delta_3d.z).normalized(),delta)
        return
    if skill_cooldown > 0:
        return
    var cost: float = 15.0 if attack_mode == "lysis" else 9.0
    if atp < cost:
        selected_target_id = ""
        attack_mode = ""
        _notice("ATP insufficiente")
        return
    atp -= cost
    skill_cooldown = 2.3 if attack_mode == "lysis" else 2.7
    var power: float = 32.0 if attack_mode == "lysis" else 16.0
    var defense: float = maxf(.4,float(target["traits"].get("defense",1.0)))
    var damage: float = power*float(entities[player_id]["traits"].get("attack",1.0))/defense
    target["hp"] = float(target["hp"])-damage
    if float(target["hp"]) <= 0:
        var prey_id: String = selected_target_id
        _remove_entity(prey_id,"predazione")
        resources["carbon"] = minf(float(NEED["carbon"])*1.1,float(resources["carbon"])+4.5)
        resources["amino"] = minf(float(NEED["amino"])*1.1,float(resources["amino"])+3.2)
        resources["biomass"] = minf(float(NEED["biomass"])*1.1,float(resources["biomass"])+6.0)
        selected_target_id = ""
        attack_mode = ""
        _notice("Predazione completata · detriti rilasciati")
    else:
        _notice("Danno %.0f · HP preda %.0f" % [damage,maxf(0.0,float(target["hp"]))])

func _on_cooperate() -> void:
    if entities[player_id]["branch"] != "archaea":
        _notice("La cooperazione della Fase 2 richiede una linea Archaea")
        return
    var traits: Dictionary = entities[player_id]["traits"]
    if not GenomeScript.has(traits,"surface_recognition") and not GenomeScript.has(traits,"eps_biosynthesis"):
        _notice("Occorre un locus maggiore per adesione o EPS")
        return
    var closest: String = ""
    var dist: float = 6.0
    for id in entities:
        if id == player_id or entities[id]["branch"] != "bacteria":
            continue
        var d: float = entities[id]["node"].position.distance_to(player.position)
        if d < dist:
            closest = id
            dist = d
    if closest == "":
        _notice("Avvicinati a una cellula Bacteria compatibile")
        return
    partner_id = closest
    phase_two = 0.0
    _notice("Protoconsorzio avviato · mantieni la vicinanza")

func _on_tree() -> void:
    _open_overlay("ALBERO EVOLUTIVO", "Specializza la tua linea: 288 nodi collegati, sei rami")
    overlay_scroll.visible = false
    tree_view = TreeScript.new()
    tree_view.configure(purchased, mutation_points)
    tree_view.mutation_unlocked.connect(_on_tree_mutation)
    overlay.add_child(tree_view)
    _layout_ui()

func _on_tree_mutation(id: int,stat: String,value: float,cost: int) -> void:
    if purchased.has(str(id)) or mutation_points < cost:
        return
    purchased[str(id)] = true
    mutation_points -= cost
    if not entities.has(player_id):
        return
    var traits: Dictionary = entities[player_id]["traits"]
    traits[stat] = clampf(float(traits.get(stat,0.0 if stat=="mutation" else 1.0))+value,-.30,4.0)
    # Il vecchio albero a 288 nodi conferisce SOLO bonus passivi:
    # non crea flagelli, archaella o EPS senza mutazioni maggiori nel genoma.
    traits = GenomeScript.express(traits,str(entities[player_id]["branch"]))
    entities[player_id]["traits"] = traits
    _cache_current()
    tree_view.configure(purchased,mutation_points)
    _refresh_hud()

func _on_genome() -> void:
    if not entities.has(player_id):
        return
    var tr: Dictionary = entities[player_id]["traits"]
    var entries: Array[String] = GenomeScript.describe(tr)
    _open_overlay("GENOMA CELLULARE", "Loci maggiori ereditabili → strutture e funzioni")
    _add_overlay_label("Genotipo: %d loci attivi  |  Mutazioni minori: %d" % [entries.size(),tr.get("mutations",[]).size()])
    for entry in entries:
        _add_overlay_label(entry)
    _add_overlay_label("I piccoli bonus statistici non introducono strutture: l'albero passivo agisce separatamente.")
    _add_overlay_label("Nota: i loci rappresentano moduli funzionali astratti, non sequenze genomiche ricostruite.")

func _on_genealogy() -> void:
    _open_overlay("LINEE EVOLUTIVE", "Madre, figlie e popolazioni esterne in una sola mappa")
    overlay_scroll.visible = false
    lineage_view = LineageScript.new()
    lineage_view.configure(genealogy,player_id)
    lineage_view.lineage_requested.connect(_switch_lineage)
    overlay.add_child(lineage_view)
    _layout_ui()

func _switch_lineage(id: String) -> void:
    if id == player_id or not entities.has(id):
        _notice("Linea non viva oppure gia' controllata")
        return
    _cache_current()
    _activate_lineage(id)
    partner_id = ""
    phase_two = 0.0
    _close_overlay()
    _notice("Segui la linea %s · %s" % [id,str(entities[id]["branch"])])

func _open_main_menu() -> void:
    _open_overlay("MENU", "Evoluzione, genealogia e salvataggio")
    _add_overlay_button("Rigenera +30 HP",_on_regen)
    _add_overlay_button("Albero mutazioni",_on_tree)
    _add_overlay_button("Linee genealogiche",_on_genealogy)
    _add_overlay_button("Genoma e fenotipo",_on_genome)
    _add_overlay_button("Obiettivi",_on_goals)
    _add_overlay_button("Salva partita",_save_game)
    _add_overlay_button("Carica partita",_load_game)

func _on_goals() -> void:
    var branch: String = entities[player_id]["branch"]
    _open_overlay("CAMPAGNA EVOLUTIVA", "Pre-LUCA → LUCA → Bacteria / Archaea → cooperazione")
    _add_overlay_label("LINEA CORRENTE: %s   ·   GENERAZIONE %d" % [branch.to_upper(),generation])
    _add_overlay_label("1. Sistema ereditario a DNA: %s" % ("✓" if bool(entities[player_id]["traits"].get("dna",false)) else "DA SCOPRIRE"))
    _add_overlay_label("2. Divergenza delle linee: %s" % ("✓" if branch == "archaea" or branch=="bacteria" else "DA RAGGIUNGERE"))
    _add_overlay_label("3. Protoconsorzio: %s" % ("IN CORSO" if partner_id!="" else "DA INIZIARE"))
    _add_overlay_label("4. Stabilita della relazione: %.0f / 25 s" % phase_two)
    _add_overlay_label("La formazione del mitocondrio e del nucleo rimane in un capitolo futuro.")

func _game_over() -> void:
    is_paused = true
    selected_target_id = ""
    selected_nutrient = null
    move_vector = Vector2.ZERO
    _cache_current()
    for rec in genealogy:
        if str(rec.get("id","")) == player_id:
            rec["alive"] = false
            rec["status"] = "estinta"
            rec["cause"] = "morte"
            break
    _open_overlay("LINEA ESTINTA", "La tua cellula non e sopravvissuta. Puoi ricominciare o ricaricare il salvataggio.")
    _add_overlay_button("NUOVA PARTITA",_new_game)
    _add_overlay_button("RICARICA SALVATAGGIO",_load_game)

func _on_joystick_changed(v: Vector2) -> void:
    move_vector = v
    if v.length() > .14:
        selected_target_id = ""
        selected_nutrient = null
        attack_mode = ""

func _save_game() -> void:
    _cache_current()
    var cells: Array = []
    for id in entities:
        var e: Dictionary = entities[id]
        var position: Vector3 = e["node"].position
        cells.append({"id":id,"parent":e["parent"],"generation":e["generation"],
            "branch":e["branch"],"traits":e["traits"],"external":e["external"],
            "pos":[position.x,position.y,position.z],"hp":e["hp"],"atp":e["atp"],
            "energy":e["energy"],"biomass":e["biomass"],"resources":e["resources"],
            "points":e["points"],"purchased":e["purchased"],"age":e["age"]})
    var particle_data: Array = []
    for n in nutrients:
        if is_instance_valid(n["node"]):
            var position: Vector3 = n["node"].position
            particle_data.append({"kind":n["kind"],"pos":[position.x,position.y,position.z]})
    var data: Dictionary = {"version":67,"elapsed":t,"player_id":player_id,"next_id":next_id,
        "entities":cells,"genealogy":genealogy,"nutrients":particle_data,
        "partner":partner_id,"phase_two":phase_two,"last_external_arrival":last_external_arrival}
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _notice("Non esiste ancora un salvataggio 0.67")
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        _notice("Impossibile leggere il salvataggio")
        return
    var loaded: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (loaded is Dictionary) or int(loaded.get("version",0)) != 67:
        _notice("Salvataggio incompatibile")
        return
    var cell_list: Array = loaded.get("entities",[])
    var controlled: String = str(loaded.get("player_id",""))
    var seen: Dictionary = {}
    for e in cell_list:
        if not(e is Dictionary) or str(e.get("id","")) == "" or seen.has(str(e.get("id",""))):
            _notice("Salvataggio non valido: ID duplicato")
            return
        seen[str(e["id"])] = true
    if not seen.has(controlled):
        _notice("Salvataggio non valido: cellula giocatore assente")
        return
    for child in cells_root.get_children():
        cells_root.remove_child(child)
        child.queue_free()
    for child in nutrient_root.get_children():
        nutrient_root.remove_child(child)
        child.queue_free()
    entities.clear()
    genealogy.clear()
    nutrients.clear()
    player = null
    var saved_history: Array = loaded.get("genealogy",[])
    for record in cell_list:
        var xyz: Array = record.get("pos",[0,0,0])
        if xyz.size() != 3:
            continue
        var id: String = str(record["id"])
        _create_entity(id,str(record.get("parent","")),int(record.get("generation",0)),str(record.get("branch","pre_luca")),record.get("traits",_base_traits()),Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2])),false,bool(record.get("external",false)))
        var target: Dictionary = entities[id]
        for key in ["hp","atp","energy","biomass","resources","points","purchased","age"]:
            if record.has(key):
                target[key] = record[key]
    genealogy = saved_history
    for p in loaded.get("nutrients",[]):
        if not(p is Dictionary) or not (TYPES.has(str(p.get("kind",""))) or str(p.get("kind",""))=="detritus"):
            continue
        var pos: Array = p.get("pos",[0,.29,0])
        if pos.size() == 3:
            _create_nutrient(str(p["kind"]),Vector3(float(pos[0]),float(pos[1]),float(pos[2])))
    _activate_lineage(controlled)
    t = maxf(0.0,float(loaded.get("elapsed",0.0)))
    next_id = maxi(1,int(loaded.get("next_id",1)))
    partner_id = str(loaded.get("partner",""))
    phase_two = float(loaded.get("phase_two",0.0))
    last_external_arrival = float(loaded.get("last_external_arrival",-60.0))
    if not entities.has(partner_id) or entities[player_id]["branch"] != "archaea":
        partner_id = ""
        phase_two = 0.0
    eco_tick = 0.0
    autosave_timer = 0.0
    skill_cooldown = 0.0
    regeneration_cooldown = 0.0
    division_options.clear()
    is_paused = false
    _close_overlay()
    _refresh_hud()
    _notice("Salvataggio 0.67 caricato con genealogia e HP per linea")

func _notice(message: String) -> void:
    if is_instance_valid(tips_label):
        tips_label.text = message

func _refresh_hud() -> void:
    if not is_instance_valid(player) or not entities.has(player_id):
        return
    var traits: Dictionary = entities[player_id]["traits"]
    var stage: String = "CELLULA PRIMORDIALE" if entities[player_id]["branch"] == "pre_luca" else str(entities[player_id]["branch"]).to_upper()
    title_label.text = "ORIGINI  ·  %s  ·  GEN %d" % [stage,generation]
    status_label.text = "HP %d/100  ATP %d/100  Biomassa %d/%d  T %.0f C  |  C %d A %d L %d N %d" % [int(hp),int(atp),int(resources["biomass"]),int(NEED["biomass"]),_temperature_at(player.position),int(resources["carbon"]),int(resources["amino"]),int(resources["lipid"]),int(resources["nucleic"])]
    var minimum: float = 1.0
    for k in NEED:
        minimum = minf(minimum,float(resources[k])/float(NEED[k]))
    minimum = minf(minimum,atp/30.0)
    scission_bar.value = clampf(minimum * 100.0,0.0,100.0)
    hp_bar.value = clampf(hp,0.0,100.0)
    atp_bar.value = clampf(atp,0.0,100.0)
    scission_button.text = "SCISSIONE  ✓" if _can_divide() else "SCISSIONE · %d%%" % int(scission_bar.value)
    if entities[player_id]["branch"]=="archaea":
        objective_label.text = "FASE 2 · Stabilizza un consorzio con Bacteria (%.0f/25 s)" % phase_two
    elif not bool(traits.get("dna",false)):
        objective_label.text = "OBIETTIVO · Raggiungi LUCA: eredita DNA nella tua linea"
    elif entities[player_id]["branch"]=="luca":
        objective_label.text = "OBIETTIVO · Diversifica Bacteria e Archaea"
    else:
        objective_label.text = "OBIETTIVO · Evolvi una linea complessa · Esplora i biomi"
    if phase_two>=25.0:
        objective_label.text = "FASE 2 COMPLETATA · Consorzio metabolico stabile"
    var danger_temperature: float = 43.0+18.0*float(traits.get("thermotolerance",0.0))
    if _temperature_at(player.position) > danger_temperature:
        objective_label.text = "STRESS TERMICO · Allontanati dalla sorgente o evolvi termotolleranza"
        objective_label.add_theme_color_override("font_color",Color(.98,.71,.59))
    else:
        objective_label.add_theme_color_override("font_color",Color(.83,.95,.96))
    buttons["tree"].text = "ALBERO (%d)" % mutation_points

func _style(color: Color, outline: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.border_color = outline
    s.set_border_width_all(1)
    s.set_corner_radius_all(13)
    s.content_margin_left = 10.0
    s.content_margin_right = 10.0
    s.content_margin_top = 6.0
    s.content_margin_bottom = 6.0
    return s

func _label(text: String, font: int = 15) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size",font)
    l.add_theme_color_override("font_color",Color(.83,.95,.96))
    return l

func _button(text: String, action: Callable, key: String) -> Button:
    var b := Button.new()
    b.text = text
    b.add_theme_font_size_override("font_size",16)
    b.add_theme_color_override("font_color",Color(.94,.99,.98))
    b.add_theme_stylebox_override("normal",_style(Color(.035,.17,.21,.93), Color(.28,.7,.77,.76)))
    b.add_theme_stylebox_override("hover",_style(Color(.08,.30,.37),Color(.51,.9,.92)))
    b.add_theme_stylebox_override("pressed",_style(Color(.08,.41,.42),Color(.74,.96,.87)))
    b.pressed.connect(action)
    hud.add_child(b)
    buttons[key] = b
    return b

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Control.new()
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(hud)
    title_label = _label("ORIGINI",21)
    hud.add_child(title_label)
    status_label = _label("ATP · HP · biomassa",15)
    hud.add_child(status_label)
    objective_label = _label("Obiettivo",15)
    hud.add_child(objective_label)
    tips_label = _label("",11)
    tips_label.visible = false
    hud.add_child(tips_label)
    for stat in ["HP", "ATP"]:
        var bar := ProgressBar.new()
        bar.min_value = 0
        bar.max_value = 100
        bar.show_percentage = false
        hud.add_child(bar)
        if stat == "HP":
            hp_bar = bar
        else:
            atp_bar = bar
    joystick = JoystickScript.new()
    joystick.direction_changed.connect(_on_joystick_changed)
    hud.add_child(joystick)
    scission_bar = ProgressBar.new()
    scission_bar.min_value = 0
    scission_bar.max_value = 100
    scission_bar.show_percentage = false
    hud.add_child(scission_bar)
    scission_button = _button("SCISSIONE",_divide_pressed,"divide")
    _button("RIGENERA  +30 HP",_on_regen,"regen")
    _button("ENZIMI",func():_on_skill("enzyme"),"enzymes")
    _button("LISI",func():_on_skill("lysis"),"lysis")
    _button("COOPERA",_on_cooperate,"cooperate")
    _button("ALBERO",_on_tree,"tree")
    _button("LINEE",_on_genealogy,"genealogy")
    _button("OBIETTIVO",_on_goals,"goals")
    _button("SALVA",_save_game,"save")
    _button("CARICA",_load_game,"load")
    _button("GENOMA",_on_genome,"genome")
    _button("CELLULA",_toggle_focus,"focus")
    _button("MENU",_open_main_menu,"menu")
    overlay = ColorRect.new()
    overlay.color = Color(.005,.025,.040,.97)
    overlay.visible = false
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(overlay)
    _layout_ui()

func _layout_ui() -> void:
    if not is_instance_valid(hud):
        return
    var wh: Vector2 = get_viewport().get_visible_rect().size
    hud.size = wh
    var portrait: bool = wh.y > wh.x
    title_label.position = Vector2(20,14)
    title_label.size = Vector2(wh.x-40,30)
    status_label.position = Vector2(20,48)
    status_label.size = Vector2(wh.x-40,29)
    status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    objective_label.position = Vector2(20,79)
    objective_label.size = Vector2(wh.x-40,25)
    tips_label.visible = false
    hp_bar.position = Vector2(20,112)
    hp_bar.size = Vector2(minf(wh.x*.16,175),8)
    atp_bar.position = Vector2(30+hp_bar.size.x,112)
    atp_bar.size = Vector2(minf(wh.x*.16,175),8)
    joystick.size = Vector2(112,112)
    joystick.position = Vector2(22,wh.y-150)
    scission_bar.size = Vector2(minf(wh.x*.27,235),7)
    scission_bar.position = Vector2(wh.x-scission_bar.size.x-16,wh.y-89)
    # Gli strumenti secondari restano nel menu, ma le azioni sono conservate.
    var primary: Array[String] = ["divide","enzymes","lysis","cooperate","focus","menu"]
    for key in buttons:
        buttons[key].visible = primary.has(str(key))
    if portrait:
        var w: float = minf((wh.x-28.0)/3.0,132.0)
        for i in range(primary.size()):
            var b: Button = buttons[primary[i]]
            b.position = Vector2(wh.x - 3*w - 12 + float(i%3)*w,wh.y-146 + float(i/3)*58)
            b.size = Vector2(w-5,49)
            b.add_theme_font_size_override("font_size",12)
    else:
        var w: float = minf(108.0,(wh.x-160.0)/6.0)
        for i in range(primary.size()):
            var b: Button = buttons[primary[i]]
            b.position = Vector2(wh.x-(6.0*w+18.0)+float(i)*w,wh.y-70)
            b.size = Vector2(w-6,51)
            b.add_theme_font_size_override("font_size",13)
    overlay.size = wh
    if is_instance_valid(overlay_scroll):
        overlay_scroll.position = Vector2(14,92)
        overlay_scroll.size = Vector2(maxf(100.0,wh.x-28),maxf(100.0,wh.y-107))
    for child in overlay.get_children():
        if child is MutationTree or child is LineageView:
            child.position = Vector2(10,92)
            child.size = Vector2(wh.x-20,wh.y-116)

func _open_overlay(title: String, subtitle: String) -> void:
    overlay.visible = true
    is_paused = true
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(false)
    for c in overlay.get_children():
        overlay.remove_child(c)
        c.queue_free()
    var heading := _label(title,23)
    heading.position = Vector2(20,11)
    heading.size.x = overlay.size.x-140
    overlay.add_child(heading)
    var description := _label(subtitle,14)
    description.position = Vector2(20,45)
    description.size.x = overlay.size.x-40
    overlay.add_child(description)
    var close := Button.new()
    close.text = "CHIUDI ✕"
    close.position = Vector2(overlay.size.x-120,8)
    close.size = Vector2(106,40)
    close.add_theme_stylebox_override("normal",_style(Color(.12,.29,.34),Color(.46,.77,.79)))
    overlay.add_child(close)
    close.pressed.connect(_close_overlay)
    if title == "LINEA ESTINTA":
        close.visible = false
    overlay_scroll = ScrollContainer.new()
    overlay_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    overlay_scroll.position = Vector2(14,92)
    overlay_scroll.size = Vector2(maxf(100,overlay.size.x-28),maxf(100,overlay.size.y-107))
    overlay.add_child(overlay_scroll)
    overlay_list = VBoxContainer.new()
    overlay_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overlay_list.add_theme_constant_override("separation",10)
    overlay_scroll.add_child(overlay_list)

func _add_overlay_label(message: String) -> void:
    var l: Label = _label(message,16)
    l.custom_minimum_size = Vector2(0,45)
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_list.add_child(l)

func _add_overlay_button(text: String, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0,54)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.clip_text = true
    b.add_theme_font_size_override("font_size",15)
    b.add_theme_stylebox_override("normal",_style(Color(.07,.24,.29),Color(.32,.79,.8)))
    b.pressed.connect(action)
    overlay_list.add_child(b)

func _close_overlay() -> void:
    if is_instance_valid(overlay):
        overlay.visible = false
    is_paused = false
    move_vector = Vector2.ZERO
    touch_index = -1
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(true)
        joystick.reset_input()
