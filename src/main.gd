extends Node3D
## ORIGINI 0.67 — prima ricostruzione grafica e giocabile con Godot 4.x.
## Scene 3D reali, camera isometrica, fenotipi procedurali, UI mobile.

const CellScript = preload("res://src/cell_visual.gd")
const GenomeScript = preload("res://src/cell_genome.gd")
const PhaseScript = preload("res://src/phase_two_progress.gd")
const PhaseOneScript = preload("res://src/phase_one_progress.gd")
const Physiology = preload("res://src/cell_physiology.gd")
const OceanScript = preload("res://src/primordial_ocean.gd")
const TreeScript = preload("res://src/mutation_tree.gd")
const LineageScript = preload("res://src/lineage_view.gd")
const JoystickScript = preload("res://src/virtual_joystick.gd")
const ClassicHudScript = preload("res://src/classic_hud.gd")
const PhenotypePortraitScript = preload("res://src/phenotype_portrait.gd")
const NutrientMarkersScript = preload("res://src/nutrient_markers.gd")
const CellWorldGlyphScript = preload("res://src/cell_world_glyphs.gd")
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
var phase1_progress: Dictionary = PhaseOneScript.empty()
var zero_atp_seconds: float = 0.0
var phase_one_population: Dictionary = {}
var npc_population_cap: int = 32
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
var notice_expires: float = -1.0
var hud: Control
var classic_hud: OriginiClassicHud
var nutrient_markers: OriginiNutrientMarkers
var cell_world_glyphs: OriginiCellWorldGlyphs
var toast_back: Panel
var overlay: ColorRect
var overlay_panel: Panel
var overlay_scroll: ScrollContainer
var overlay_list: VBoxContainer
var title_label: Label
var status_label: Label
var objective_label: Label
var partner_compass_label: Label
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
    phase1_progress = PhaseOneScript.empty()
    zero_atp_seconds = 0.0
    phase_one_population = {}
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
    # Anche il primo minuto offre nutrienti visibili vicino alla cellula,
    # con materiali abiotici distribuiti nel resto dell'oceano.
    for i in range(Physiology.initial_nutrients()):
        var x: float = 0.0
        var z: float = 0.0
        if i < 22:
            # +10% starting ring compared with v0.74 (20 -> 22).
            var angle: float = TAU*float(i)/22.0+rng.randf_range(-.07,.07)
            var distance: float = rng.randf_range(1.85,3.05)
            x = cos(angle)*distance
            z = sin(angle)*distance
        elif i < 57:
            x = rng.randf_range(-4.7,4.7)
            z = rng.randf_range(-4.7,4.7)
            if Vector2(x,z).length() < 1.65:
                x += 2.2 if x >= 0 else -2.2
        else:
            x = rng.randf_range(-20.0,20.0)
            z = rng.randf_range(-20.0,20.0)
        _create_nutrient(TYPES[i % 4], Vector3(x,.19,z))
    _refresh_hud()
    _open_phase_intro(1)

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
    # Portrait classic mode shows the chemically meaningful projected icon
    # instead of duplicating it with an overlapping generic 3D sphere.
    node.visible = not (is_instance_valid(nutrient_markers) and nutrient_markers.visible)
    nutrients.append({"kind": kind, "node": node, "origin_y": at.y, "bob": rng.randf_range(0,TAU)})

func _create_entity(id: String, parent: String, gen: int, branch: String, traits: Dictionary, at: Vector3, controlled: bool = false, external: bool = false) -> void:
    if entities.has(id):
        return
    var inherited: Dictionary = GenomeScript.normalize(traits,branch)
    var node: CellVisual = CellScript.new()
    cells_root.add_child(node)
    node.position = at
    node.setup(inherited, branch, controlled)
    var screen: Vector2 = get_viewport().get_visible_rect().size
    node.visible = not (screen.y > screen.x and not camera_focus)
    node.set_growth(Physiology.growth_scale(24.0,23.0,65.0))
    var inventory: Dictionary = {"carbon":6.0,"amino":4.0,"lipid":3.0,"nucleic":1.0,"biomass":24.0}
    entities[id] = {"node":node,"parent":parent,"generation":gen,"branch":branch,
        "traits":inherited.duplicate(true),"external":external,"age":0.0,
        "biomass":24.0,"energy":46.0,"hp":100.0,"atp":65.0,
        "velocity":Vector3.ZERO,"intent_velocity":Vector3.ZERO,
        "zero_energy_seconds":0.0,"zero_atp_seconds":0.0,
        "strategy":Physiology.strategy(inherited),
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
    e["zero_atp_seconds"] = zero_atp_seconds

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
    zero_atp_seconds = maxf(0.0,float(e.get("zero_atp_seconds",0.0)))
    resources = e.get("resources", {}).duplicate(true)
    for key in NEED:
        resources[key] = clampf(float(resources.get(key,0.0)),0.0,Physiology.reserve_cap(float(NEED[key])))
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
    if is_instance_valid(tips_label) and notice_expires >= 0 and t > notice_expires:
        tips_label.visible = false
        if is_instance_valid(toast_back):
            toast_back.visible = false
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
    var position_before_movement: Vector3 = player.position
    if direction.length() > 0.12 and atp > 0.0:
        selected_target_id = ""
        selected_nutrient = null
        attack_mode = ""
        _move_player(direction.normalized(),delta)
    elif atp > 0.0 and (selected_target_id != "" or is_instance_valid(selected_nutrient)):
        _follow_attack(delta)
    var travelled: float = player.position.distance_to(position_before_movement)
    var physiology_state: Dictionary = Physiology.energy_step(atp,zero_atp_seconds,delta,
        travelled,entities[player_id]["traits"])
    atp = float(physiology_state["atp"])
    zero_atp_seconds = float(physiology_state["zero_seconds"])
    if bool(physiology_state["dead"]):
        hp = 0.0
    var player_temperature: float = _temperature_at(player.position)
    var tolerance: float = 43.0+18.0*float(entities[player_id]["traits"].get("thermotolerance",0.0))
    if player_temperature > tolerance:
        hp = maxf(0.0,hp-delta*(player_temperature-tolerance)*.075)
    # Nutrizione consentita entro il 12% oltre la soglia di divisione.
    # La cellula non supera mai il 120% della dimensione alla nascita.
    player.set_growth(Physiology.growth_scale(float(resources["biomass"]),23.0,
        float(NEED["biomass"])))
    camera.position = camera.position.lerp(player.position+camera_offset,minf(1.0,delta*3.2))
    camera.look_at(player.position+Vector3(0,.55,0))
    for n in nutrients:
        if is_instance_valid(n["node"]):
            n["node"].position.y = float(n["origin_y"]) + sin(t*1.8+float(n["bob"]))*0.04
    _collect_nearby()
    _update_npc_motion(delta)
    _update_nutrient_markers()
    _update_cell_world_glyphs()
    eco_tick += delta
    if eco_tick >= .22:
        _update_ecosystem(eco_tick)
        eco_tick = 0.0
    _advance_phase_one(delta)
    # Phase 2 is a separately unlocked mission, not a forced part of Phase 1.
    if bool(phase1_progress.get("complete",false)):
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

func _advance_phase_one(delta: float) -> void:
    if bool(phase1_progress.get("complete",false)):
        return
    phase_one_population = PhaseOneScript.population(entities)
    var was_complete: bool = bool(phase1_progress.get("complete",false))
    phase1_progress = PhaseOneScript.advance(phase1_progress,delta,generation,
        phase_one_population,t)
    if bool(phase1_progress["complete"]) and not was_complete:
        # Capture the actual distribution after a prolonged final-generation
        # competition. We do not artificially force intermediate dominance.
        _save_game()
        _open_phase_intro(2)

func _open_phase_intro(number: int) -> void:
    if number == 1:
        phase1_progress["intro_seen"] = true
        _open_overlay("FASE 1 · CONQUISTA DELLA NICCHIA",
            "Origine, replicazione autonoma e selezione naturale")
        _add_overlay_label("Parti da una singola cellula a RNA. Raccogli nutrienti, sopravvivi e dividi la tua linea.")
        _add_overlay_label("Le figlie non controllate diventeranno popolazioni indipendenti: devono nutrirsi, riprodursi e competere.")
        _add_overlay_label("MISSIONI PER COMPLETARE LA FASE 1")
        for line in PhaseOneScript.mission_lines(phase1_progress,
            PhaseOneScript.population(entities),generation):
            _add_overlay_label(line)
        _add_overlay_label("L'ultima coorte viene osservata per 75 s per confrontare popolazioni iniziali, intermedie e recenti.")
        _add_overlay_button("INIZIA · FASE 1",_close_overlay)
    else:
        phase1_progress["phase_two_intro_seen"] = true
        _open_overlay("FASE 2 · COOPERAZIONE CELLULARE",
            "Fase 1 completata: l'oceano è popolato da linee in competizione")
        _add_overlay_label("RISULTATI DEL CENSIMENTO · FINE FASE 1")
        for line in PhaseOneScript.report_lines(phase1_progress):
            _add_overlay_label(line)
        _add_overlay_label("Le percentuali derivano dalle cellule vive al termine dell'osservazione; non sono quote imposte dal gioco.")
        _add_overlay_label("NUOVE MISSIONI · FASE 2")
        for line in PhaseScript.objective_lines(phase2_progress):
            _add_overlay_label(line)
        _add_overlay_label("Crea un consorzio Bacteria–Archaea stabile e trasmissibile, senza endosimbiosi in questa fase.")
        _add_overlay_button("INIZIA · FASE 2",_close_overlay)

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
    _layout_ui()
    buttons["focus"].text = "MONDO" if camera_focus else "CELLULA"

func _move_player(direction: Vector2, delta: float) -> void:
    var traits: Dictionary = entities[player_id]["traits"]
    var speed: float = Physiology.player_speed(traits)
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
            resources["carbon"] = minf(Physiology.reserve_cap(float(NEED["carbon"])),float(resources["carbon"])+2.0*uptake)
            resources["amino"] = minf(Physiology.reserve_cap(float(NEED["amino"])),float(resources["amino"])+1.5*uptake)
        else:
            resources[kind] = minf(Physiology.reserve_cap(float(NEED[kind])),float(resources[kind])+2.15*uptake)
        resources["biomass"] = minf(Physiology.reserve_cap(float(NEED["biomass"])),float(resources["biomass"])+1.45*uptake)
        atp = minf(100.0,atp+1.35*float(entities[player_id]["traits"].get("metabolism",1.0)))
        if atp > 0.0:
            zero_atp_seconds = 0.0
    elif entities.has(cell_id):
        var e: Dictionary = entities[cell_id]
        e["biomass"] = minf(Physiology.reserve_cap(float(NEED["biomass"])),float(e["biomass"])+2.3*float(e["traits"].get("uptake",1.0)))
        e["energy"] = minf(85.0,float(e["energy"])+4.0)
        if float(e["energy"]) > 0.0:
            e["zero_energy_seconds"] = 0.0
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
        if kind != "detritus" and float(resources[kind]) >= Physiology.reserve_cap(float(NEED[kind]))-.001 and float(resources["biomass"])>=Physiology.reserve_cap(float(NEED["biomass"]))-.001:
            continue
        _consume_nutrient(i,true)
    # Redistribuzione limitata; i detriti cellulari non emergono spontaneamente.
    if nutrients.size() < Physiology.nutrient_goal():
        nutrient_respawn += eco_tick + .016
        if nutrient_respawn >= .22:
            _create_nutrient(TYPES[rng.randi_range(0,3)], Vector3(rng.randf_range(-23,23),.29,rng.randf_range(-23,23)))
            nutrient_respawn = 0.0

func _update_nutrient_markers() -> void:
    if not is_instance_valid(nutrient_markers) or not nutrient_markers.visible:
        return
    var rect: Vector2 = get_viewport().get_visible_rect().size
    var points: Array[Dictionary] = []
    var top_safe: float = classic_hud.panel_height()+29.0
    var bottom_safe: float = rect.y-189.0
    for n in nutrients:
        var node: MeshInstance3D = n["node"]
        if not is_instance_valid(node):
            continue
        var where: Vector3 = node.position+Vector3(0,.12,0)
        if camera.is_position_behind(where):
            continue
        var screen: Vector2 = camera.unproject_position(where)
        if screen.y < top_safe or screen.y > bottom_safe:
            continue
        points.append({"pos":screen,"kind":str(n["kind"]),"scale":1.0})
    nutrient_markers.configure(points,top_safe,bottom_safe,rect)

func _update_cell_world_glyphs() -> void:
    if not is_instance_valid(cell_world_glyphs) or not cell_world_glyphs.visible:
        return
    var wh: Vector2 = get_viewport().get_visible_rect().size
    var ui: float = clampf(wh.x/720.0,.62,1.65)
    var top: float = classic_hud.panel_height()+14.0*ui
    var bottom: float = wh.y-189.0*ui
    var silhouettes: Array[Dictionary] = []
    for id in entities:
        if str(id) == player_id:
            continue
        var entity: Dictionary = entities[id]
        var n: CellVisual = entity["node"]
        if not is_instance_valid(n):
            continue
        var center: Vector3 = n.position+Vector3(0,.81,0)
        if camera.is_position_behind(center):
            continue
        var point: Vector2 = camera.unproject_position(center)
        if point.y < top-80.0*ui or point.y > bottom+80.0*ui:
            continue
        silhouettes.append({"pos":point, "radius":38.0*ui,
            "traits":entity["traits"],"branch":str(entity["branch"]),
            "seed":str(id).hash()%88,"selected":false})
    if is_instance_valid(player) and entities.has(player_id):
        var center: Vector3 = player.position+Vector3(0,.81,0)
        if not camera.is_position_behind(center):
            silhouettes.append({"pos":camera.unproject_position(center),
                "radius":65.0*ui,
                "traits":entities[player_id]["traits"],
                "branch":str(entities[player_id]["branch"]),
                "selected":true,"seed":0})
    cell_world_glyphs.configure(silhouettes,top,bottom,wh,t)

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

func _update_npc_motion(delta: float) -> void:
    # Render-frame interpolation. Decision-making happens every 0.22s,
    # but motion and ATP consumption run EVERY frame: no jerky daughter NPCs.
    for id in entities.keys():
        if id == player_id or not entities.has(id):
            continue
        var e: Dictionary = entities[id]
        var c: CellVisual = e["node"]
        if not is_instance_valid(c):
            continue
        var current: Vector3 = e.get("velocity",Vector3.ZERO)
        var desired: Vector3 = e.get("intent_velocity",Vector3.ZERO)
        if float(e.get("energy",0.0)) <= 0.0:
            desired = Vector3.ZERO
        var next: Vector3 = current.move_toward(desired,Physiology.NPC_ACCELERATION*delta)
        var before: Vector3 = c.position
        c.position += next*delta
        c.position.x = clampf(c.position.x,-24.0,24.0)
        c.position.z = clampf(c.position.z,-24.0,24.0)
        var actual_distance: float = before.distance_to(c.position)
        e["velocity"] = next
        e["energy"] = Physiology.npc_energy_step(float(e["energy"]),delta,actual_distance)
        if actual_distance > .0001:
            c.rotation.y = lerp_angle(c.rotation.y,atan2(-next.z,next.x),delta*4.0)
        if float(e["energy"]) <= .001:
            e["zero_energy_seconds"] = float(e.get("zero_energy_seconds",0.0))+delta
            if float(e["zero_energy_seconds"]) >= Physiology.ZERO_ATP_DEATH_SECONDS:
                _remove_entity(str(id),"esaurimento ATP")
        else:
            e["zero_energy_seconds"] = 0.0

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
        var role: String = Physiology.strategy(e["traits"])
        e["strategy"] = role
        var target_idx: int = _nearest_nutrient(c.position,7.5)
        var dir: Vector3 = Vector3(sin(t*.39+float(str(id).hash()%77)),0,
            cos(t*.31+float(str(id).hash()%63)))
        var speed: float = Physiology.strategy_speed(e["traits"])
        if str(id) == partner_id and entities.has(player_id):
            # The bacterial consortium partner follows smoothly but remains a
            # separate organism; no teleporting or snapping onto the player.
            var separation: Vector3 = player.position-c.position
            separation.y = 0.0
            if separation.length() > 2.4:
                dir = separation
                speed = minf(maxf(speed,1.10),1.50)
            else:
                dir = Vector3.ZERO
                target_idx = -1
        else:
            var closest_threat: String = ""
            var threat_distance: float = 4.6
            var closest_prey: String = ""
            var prey_distance: float = 4.1
            for other_id in entities:
                if other_id == id:
                    continue
                var other: Dictionary = entities[other_id]
                if not is_instance_valid(other["node"]):
                    continue
                var distance: float = c.position.distance_to(other["node"].position)
                if int(other["traits"].get("protease",0)) > 0 and distance < threat_distance:
                    closest_threat = str(other_id)
                    threat_distance = distance
                if distance < prey_distance and str(other_id) != partner_id:
                    closest_prey = str(other_id)
                    prey_distance = distance
            if role == "esploratore" and closest_threat != "":
                dir = c.position-entities[closest_threat]["node"].position
                dir.y = 0.0
                target_idx = -1
            elif role == "predatore" and closest_prey != "" and float(e["energy"]) > 8.0:
                dir = entities[closest_prey]["node"].position-c.position
                dir.y = 0.0
                target_idx = -1
            elif target_idx >= 0:
                dir = nutrients[target_idx]["node"].position-c.position
                dir.y = 0.0
        if dir.length() > .02 and float(e["energy"]) > .001:
            e["intent_velocity"] = dir.normalized()*speed
        else:
            e["intent_velocity"] = Vector3.ZERO
        # Nutrient pickup uses the real, interpolated position; the decision
        # tick NEVER translates the cell anymore.
        if target_idx >= 0 and target_idx < nutrients.size():
            if c.position.distance_to(nutrients[target_idx]["node"].position) < .82:
                _consume_nutrient(target_idx,false,str(id))
        c.set_growth(Physiology.growth_scale(float(e["biomass"]),24.0,
            float(NEED["biomass"])))
        var can_replicate: bool = (float(e["biomass"]) >= 57.0
            and float(e["energy"]) >= 23.0 and float(e["age"]) >= 18.0
            and int(e["generation"]) < 16
            and entities.size() < npc_population_cap)
        if can_replicate:
            _divide_npc(str(id))
            continue
        # Real ecological competition among predators and prey.
        if int(e["generation"]) >= 3 and role == "predatore" and float(e["energy"]) > 8.0:
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
                        e["biomass"] = minf(Physiology.reserve_cap(float(NEED["biomass"])),
                            float(e["biomass"])+9.0)
                        e["energy"] = minf(85.0,float(e["energy"])+12.0)
    # The Phase 2 bacterial partner arises from an independent lineage.
    if bool(phase1_progress.get("complete",false)) and generation >= 3 and entities[player_id]["branch"] == "archaea" and not _has_external_bacteria() and t-last_external_arrival >= 12.0:
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
    # Partner biologicamente competente: adesine + trasportatori. Non
    # eredita alcun gene dalla nostra linea archeale.
    traits = GenomeScript.grant(traits,"surface_recognition",0,"linea_esterna","bacteria")
    traits = GenomeScript.grant(traits,"membrane_transport",0,"linea_esterna","bacteria")
    var new_id: String = "E-%03d" % next_id
    next_id += 1
    _create_entity(new_id,"",0,"bacteria",traits,player.position+Vector3(rng.randf_range(2.5,3.3),0,rng.randf_range(-1.4,1.4)),false,true)

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
    var player_bond_before: Dictionary = PhaseScript.normalize(phase2_progress)
    var inherited_phase: Dictionary = PhaseScript.normalize(parent.get("phase2_progress",{}))
    var older_purchased: Dictionary = parent["purchased"].duplicate(true)
    phase1_progress["autonomous_divisions"] = int(phase1_progress["autonomous_divisions"])+1
    _remove_entity(id,"scissione")
    var first_id: String = ""
    for i in range(2):
        var new_id: String = ("E-%03d" if external else "C-%03d") % next_id
        next_id += 1
        var mutated: Dictionary = _mutated_traits(traits,gen,branch)
        # Occasional heritable ecological specialization. Runner: fast escape,
        # predator: hydrolase and high attack but significantly slower.
        if gen >= 3 and rng.randf() < .52:
            if i == 0:
                mutated = GenomeScript.grant(mutated,"pili_twitch",gen,"specializzazione","%s" % branch)
                mutated["motility"] = maxf(1.20,float(mutated.get("motility",1.0)))
            else:
                mutated = GenomeScript.grant(mutated,"hydrolase_secretion",gen,"specializzazione","%s" % branch)
                mutated["attack"] = maxf(1.16,float(mutated.get("attack",1.0)))
                mutated["motility"] = minf(.83,float(mutated.get("motility",1.0)))
            mutated = GenomeScript.express(mutated,branch)
        _create_entity(new_id,id,gen,branch,mutated,pos+Vector3(-.70 if i == 0 else .70,0,.45 if i == 0 else -.45),false,external)
        var child: Dictionary = entities[new_id]
        child["biomass"] = 24.0
        child["energy"] = float(parent["energy"])*.45
        child["strategy"] = Physiology.strategy(mutated)
        child["hp"] = maxf(35.0,float(parent["hp"])*.8)
        child["purchased"] = older_purchased.duplicate(true)
        child["points"] = int(parent["points"])
        child["phase2_progress"] = inherited_phase.duplicate(true)
        if i == 0:
            first_id = new_id
    if was_partner and first_id != "":
        partner_id = first_id
        phase2_progress = player_bond_before
        phase2_progress["partner_id"] = first_id
        phase2_progress["last_partner_id"] = first_id
        phase2_progress["bonded"] = true
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
        elif next_branch == "archaea" and i == 0 and generation >= 3:
            # Garantisce un percorso FINITO ma non istantaneo verso fase 2.
            # Ogni mutazione compare in una SOLA figlia, poi si eredita.
            var required_locus: String = ""
            if not GenomeScript.has(traits,"surface_recognition"):
                required_locus = "surface_recognition"
            elif not GenomeScript.has(traits,"membrane_transport"):
                required_locus = "membrane_transport"
            elif not GenomeScript.has(traits,"eps_biosynthesis"):
                required_locus = "eps_biosynthesis"
            if required_locus != "":
                traits = GenomeScript.grant(traits,required_locus,generation+1,"variante_selezionabile",next_branch)
                highlight = "Variante maggiore: "+str(GenomeScript.GENE_INFO[required_locus]["name"])
        elif generation >= 3 and i == 1 and rng.randf() < .36:
            traits = GenomeScript.grant(traits,"surface_recognition",generation+1,"major_mutation",next_branch)
            highlight = "Major: riconoscimento cellulare"
        division_options.append({"traits":traits,"branch":next_branch,"name":highlight})
    for option in division_options:
        var tr: Dictionary = option["traits"]
        var events: Array = tr.get("genome",{}).get("history",[])
        for event in events:
            if int(event.get("generation",-1)) == generation+1:
                var locus: String = str(event.get("locus",""))
                if GenomeScript.GENE_INFO.has(locus):
                    option["name"] = "MAJOR: "+str(GenomeScript.GENE_INFO[locus]["name"])
    _open_overlay("QUALE FIGLIA CONTROLLERAI?", "Divisione completata · entrambe le cellule continueranno a vivere.")
    _add_daughter_cards()
    _add_overlay_label("Le mutazioni hanno effetti ereditabili: scegli la tua linea senza cancellare l'altra.")

func _add_daughter_cards() -> void:
    if division_options.size() != 2 or not is_instance_valid(overlay_list):
        return
    var is_portrait: bool = get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
    if is_portrait:
        var top_spacer := Control.new()
        top_spacer.custom_minimum_size = Vector2(0,65)
        overlay_list.add_child(top_spacer)
    var duo := HBoxContainer.new()
    duo.add_theme_constant_override("separation",12)
    duo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overlay_list.add_child(duo)
    var card_width: float = maxf(120.0,(overlay_scroll.size.x-30.0)/2.0)
    for i in range(2):
        var option: Dictionary = division_options[i]
        var daughter_traits: Dictionary = option["traits"]
        var parent_traits: Dictionary = entities[player_id]["traits"]
        var title: String = "FIGLIA A" if i == 0 else "FIGLIA B"
        var accent: Color = Color(.43,.88,.80) if i == 0 else Color(.79,.67,.99)
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(card_width,705.0 if is_portrait else 520.0)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var style: StyleBoxFlat = _style(Color(.024,.13,.17,.99) if i == 0 else Color(.087,.105,.20,.99),accent.darkened(.37))
        style.set_corner_radius_all(22)
        style.set_border_width_all(2)
        style.content_margin_left = 14
        style.content_margin_right = 14
        style.content_margin_top = 17
        style.content_margin_bottom = 16
        card.add_theme_stylebox_override("panel",style)
        duo.add_child(card)
        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation",10)
        card.add_child(column)
        var id_label: Label = _label(title,23)
        id_label.add_theme_color_override("font_color",accent)
        id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(id_label)
        var cell_illustration: PhenotypePortrait = PhenotypePortraitScript.new()
        cell_illustration.custom_minimum_size = Vector2(0,215 if is_portrait else 170)
        cell_illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        cell_illustration.set_cell(daughter_traits,str(option["branch"]))
        column.add_child(cell_illustration)
        var divider := HSeparator.new()
        column.add_child(divider)
        var selected_gene: String = "Variazione quantitativa"
        var genelist: Array[String] = []
        var inherited_genome: Dictionary = daughter_traits.get("genome",{})
        var new_loci: Dictionary = inherited_genome.get("loci",{})
        var old_loci: Dictionary = parent_traits.get("genome",{}).get("loci",{})
        for locus in new_loci:
            var new_allele: int = int(new_loci[locus].get("allele",0))
            var old_allele: int = int(old_loci.get(locus,{}).get("allele",0))
            if new_allele > old_allele and GenomeScript.GENE_INFO.has(locus):
                genelist.append(str(GenomeScript.GENE_INFO[locus]["name"]))
        if not genelist.is_empty():
            selected_gene = "GENE MAGGIORE · "+", ".join(genelist)
        elif str(option["branch"]) != str(entities[player_id]["branch"]):
            selected_gene = "NUOVA LINEA · "+str(option["branch"]).to_upper()
        var gene_label: Label = _label(selected_gene,15)
        gene_label.add_theme_color_override("font_color",Color(.99,.86,.58) if not genelist.is_empty() else accent)
        gene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        gene_label.custom_minimum_size = Vector2(0,55)
        column.add_child(gene_label)
        var first_stat: Label = _label("Mobilita %d%%  ·  Difesa %d%%" % [
            int(float(daughter_traits.get("motility",1.0))*100.0),
            int(float(daughter_traits.get("defense",1.0))*100.0)],14)
        first_stat.add_theme_color_override("font_color",Color(.77,.91,.91))
        first_stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        column.add_child(first_stat)
        var second_stat: Label = _label("Attacco %d%%  ·  Assorb. %d%%" % [
            int(float(daughter_traits.get("attack",1.0))*100.0),
            int(float(daughter_traits.get("uptake",1.0))*100.0)],14)
        second_stat.add_theme_color_override("font_color",Color(.77,.91,.91))
        second_stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        column.add_child(second_stat)
        # Vantaggi e costi separati come nel client web. Non confondere
        # le piccole variazioni numeriche con un nuovo locus genetico.
        var delta_caption: Label = _label("EFFETTI DELLA VARIANTE",12)
        delta_caption.add_theme_color_override("font_color",Color(.63,.82,.84))
        column.add_child(delta_caption)
        var changes: int = 0
        for key in ["motility","defense","attack","uptake","metabolism"]:
            var delta: float = float(daughter_traits.get(key,1.0))-float(parent_traits.get(key,1.0))
            if absf(delta) < .025:
                continue
            var stat_name: String = {"motility":"Mobilità","defense":"Difesa","attack":"Attacco","uptake":"Assorbimento","metabolism":"Energia"}[key]
            var positive: bool = delta > 0.0
            var label: Label = _label("%s  %s %d%%" % ["▲" if positive else "▼",stat_name,int(round(absf(delta)*100.0))],15)
            label.add_theme_color_override("font_color",Color(.54,.95,.76) if positive else Color(1,.61,.69))
            column.add_child(label)
            changes += 1
        if changes == 0:
            var same: Label = _label("≃  Nessuna variazione statistica rilevante",14)
            same.add_theme_color_override("font_color",Color(.69,.85,.89))
            same.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            column.add_child(same)
        var space := Control.new()
        space.size_flags_vertical = Control.SIZE_EXPAND_FILL
        column.add_child(space)
        var choose := Button.new()
        choose.text = "SEGUI LA FIGLIA A" if i == 0 else "SEGUI LA FIGLIA B"
        choose.custom_minimum_size = Vector2(0,56)
        _theme_button(choose,Color(.24,.68,.61) if i == 0 else Color(.55,.42,.75),
            accent,15,13)
        choose.pressed.connect(_choose_daughter.bind(i))
        column.add_child(choose)

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
    var parent_phase: Dictionary = PhaseScript.normalize(phase2_progress)
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
        if str(option["branch"]) == "archaea" and str(parent["branch"]) == "archaea":
            var descendant_phase: Dictionary = PhaseScript.normalize(parent_phase)
            if i == choice:
                var partner_alive: bool = old_partner != "" and entities.has(old_partner)
                descendant_phase = PhaseScript.inherit(descendant_phase,new_cell["traits"],
                    partner_alive,old_id,gen)
                if bool(descendant_phase["complete"]):
                    descendant_phase["partner_id"] = old_partner
                    descendant_phase["bonded"] = true
            else:
                descendant_phase = PhaseScript.release(descendant_phase)
            new_cell["phase2_progress"] = descendant_phase
        if i == choice:
            chosen_id = id
    division_options.clear()
    phase1_progress["player_divisions"] = int(phase1_progress.get("player_divisions",0))+1
    _activate_lineage(chosen_id)
    var phase2_finished: bool = bool(phase2_progress.get("complete",false))
    _close_overlay()
    _save_game()
    if phase2_finished:
        _open_overlay("FASE 2 COMPLETATA", "Un consorzio metabolico stabile ha trasmesso la capacita di cooperare a una figlia.")
        _add_overlay_label("Il genoma eredita adesine e trasportatori; il partner rimane una cellula Bacteria distinta.")
        _add_overlay_label("Traguardo: associazione procariotica cooperativa. NON endosimbiosi, nucleo o mitocondri.")
        _add_overlay_label("Puoi continuare a esplorare, dividerti, evolvere e seguire altre linee.")
        _add_overlay_button("CONTINUA IL GIOCO",_close_overlay)
    else:
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
    if not bool(phase1_progress.get("complete",false)):
        _notice("Cooperazione disponibile all'apertura della FASE 2")
        return
    if not entities.has(player_id) or entities[player_id]["branch"] != "archaea":
        _notice("La Fase 2 segue una linea Archaea; Bacteria resta separata")
        return
    if partner_id != "" and entities.has(partner_id) and bool(phase2_progress.get("bonded",false)):
        _notice("Adesione attiva: mantieni vicinanza e scambia metaboliti")
        return
    var traits: Dictionary = entities[player_id]["traits"]
    if not GenomeScript.has(traits,"surface_recognition") and not GenomeScript.has(traits,"eps_biosynthesis"):
        _notice("Per aderire serve una mutazione maggiore: recettori o EPS")
        return
    var closest: String = ""
    var distance: float = PhaseScript.BOND_RADIUS
    for id in entities:
        if id == player_id or str(entities[id]["branch"]) != "bacteria":
            continue
        var bacterial: Dictionary = entities[id]["traits"]
        if not PhaseScript.can_adhere(traits,bacterial):
            continue
        var d: float = entities[id]["node"].position.distance_to(player.position)
        if d < distance:
            closest = str(id)
            distance = d
    if closest == "":
        _notice("Nessuna Bacteria compatibile vicino. Raggiungila e riprova.")
        return
    phase2_progress = PhaseScript.bind(phase2_progress,traits,entities[closest]["traits"],closest,distance)
    if not bool(phase2_progress["bonded"]):
        _notice("Adesione non riuscita: recettori incompatibili")
        return
    partner_id = closest
    phase_two = 0.0
    _cache_current()
    if not PhaseScript.can_exchange(traits,entities[closest]["traits"]):
        _notice("Adesione stabilita. Servono trasportatori di membrana per lo scambio.")
    else:
        _notice("Adesione stabilita: mantieni la vicinanza per lo scambio metabolico")

func _on_resources() -> void:
    if not entities.has(player_id):
        return
    _open_overlay("NUTRIENTI E RISORSE", "Raccogli le sostanze necessarie per scissione ed energia.")
    for info in [
        ["Carbonio", "carbon", 24.0, "Fonte di scheletri carboniosi per biomassa"],
        ["Amminoacidi", "amino", 15.0, "Precursori per sistemi catalitici"],
        ["Lipidi", "lipid", 12.0, "Costituenti di membrana e vescicole"],
        ["Nucleotidi", "nucleic", 8.0, "Precursori dei polimeri ereditari"],
        ["Biomassa", "biomass", 65.0, "Crescita complessiva e preparazione alla divisione"]
    ]:
        var value: float = float(resources.get(str(info[1]),0.0))
        _add_overlay_label("%s   %d / %d\n%s" % [str(info[0]),int(value),int(float(info[2])),str(info[3])])
    _add_overlay_label("ATP: %d / 100  ·  HP: %d / 100" % [int(atp),int(hp)])
    _add_overlay_button("COME GIOCARE",_on_guide)

func _on_tree() -> void:
    _open_overlay("ALBERO EVOLUTIVO", "Specializza la tua linea: 288 nodi collegati, sei rami")
    overlay_scroll.visible = false
    tree_view = TreeScript.new()
    tree_view.configure(purchased, mutation_points)
    tree_view.mutation_unlocked.connect(_on_tree_mutation)
    overlay.add_child(tree_view)
    _layout_ui()
    var scale_factor: float = clampf(overlay.size.x/720.0,.62,1.65) if overlay.size.y > overlay.size.x else 1.0
    var right: float = overlay.size.x-81.0*scale_factor
    for i in range(3):
        var control := Button.new()
        control.text = ["−","+","◎"][i]
        control.position = Vector2(right,277.0*scale_factor+float(i)*59.0*scale_factor)
        control.size = Vector2(49,49)*scale_factor
        _theme_button(control,Color(.034,.18,.23,.94),Color(.32,.63,.69,.80),22,14)
        overlay.add_child(control)
        if i == 0:
            control.pressed.connect(func(): tree_view.zoom_by(.83))
        elif i == 1:
            control.pressed.connect(func(): tree_view.zoom_by(1.20))
        else:
            control.pressed.connect(func(): tree_view.center_view())

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
    # Il legame appartiene alla linea attiva: non azzerare un consorzio
    # valido quando il giocatore torna a una Archaea precedentemente legata.
    _close_overlay()
    _notice("Segui la linea %s · %s" % [id,str(entities[id]["branch"])])

func _open_main_menu() -> void:
    _open_overlay("MENU", "Evoluzione, genealogia e salvataggio")
    _add_overlay_button("Rigenera +30 HP",_on_regen)
    _add_overlay_button("Albero mutazioni",_on_tree)
    _add_overlay_button("Linee genealogiche",_on_genealogy)
    _add_overlay_button("Genoma e fenotipo",_on_genome)
    _add_overlay_button("Obiettivi",_on_goals)
    _add_overlay_button("Fase 2 · Consorzi metabolici",_on_phase_two)
    _add_overlay_button("Come giocare",_on_guide)
    _add_overlay_button("Salva partita",_save_game)
    _add_overlay_button("Carica partita",_load_game)

func _on_guide() -> void:
    _open_overlay("GUIDA ORIGINI", "Fase 1 e Fase 2 · versione giocabile 0.70")
    _add_overlay_label("MUOVITI con joystick tattile o WASD/frecce. Premi CELLULA per osservare il fenotipo da vicino.")
    _add_overlay_label("NUTRIZIONE: avvicinati ai piccoli nutrienti minerali/organici. Raccogli C, A, L, N e biomassa, poi SCISSIONE.")
    _add_overlay_label("OGNI DIVISIONE produce due figlie vive. Scegli quale controllare; l'altra prosegue come NPC. Il genoma e la genealogia sono ereditati.")
    _add_overlay_label("FASE 1: completa le divisioni, favorisci la riproduzione autonoma di almeno tre cellule e popola l'oceano.")
    _add_overlay_label("FASE 1: raggiungi il ciclo 6 e confronta le coorti dopo 75 secondi di competizione.")
    _add_overlay_label("FASE 2: si apre soltanto dopo la conclusione della Fase 1. Segui una linea Archaea, evolvi RECETTORI e TRASPORTATORI.")
    _add_overlay_label("Quando sei vicino, premi COOPERA. Mantieni il contatto per almeno 12 secondi di scambio e 25 secondi di stabilita.")
    _add_overlay_label("Lo scambio usa carbonio e l'energia batterica: raccogli nuove risorse prima di SCISSIONE. Infine scegli la figlia che mantiene il consorzio.")
    _add_overlay_label("GENOMA mostra i loci; ALBERO offre bonus numerici, ma soltanto i loci maggiori fanno apparire nuove strutture.")
    _add_overlay_label("SALVA e CARICA sono nel MENU. Puoi cambiare linea dalla genealogia. Fumaioli caldi causano danni senza termotolleranza.")
    _add_overlay_button("VEDI OBIETTIVI",_on_goals)

func _on_goals() -> void:
    if not entities.has(player_id):
        return
    var snapshot: Dictionary = PhaseOneScript.population(entities)
    if not bool(phase1_progress.get("complete",false)):
        _open_overlay("FASE 1 · CONQUISTA DELLA NICCHIA",
            "Prima la popolazione, poi l'associazione tra cellule")
        for line in PhaseOneScript.mission_lines(phase1_progress,snapshot,generation):
            _add_overlay_label(line)
        _add_overlay_label("CELLULE VIVE: %d  ·  Prime %d · Intermedie %d · Recenti %d" % [
            int(snapshot["totale"]),int(snapshot["prime"]),int(snapshot["intermedie"]),int(snapshot["recenti"])])
        _add_overlay_label("Le divisioni autonome e la competizione determinano l'effettiva distribuzione.")
        _add_overlay_button("COME GIOCARE",_on_guide)
    else:
        _open_overlay("FASE 2 · COOPERAZIONE PROCARIOTICA",
            "Cinque missioni per un consorzio metabolico ereditabile")
        for line in PhaseScript.objective_lines(phase2_progress):
            _add_overlay_label(line)
        _add_overlay_label("RIEPILOGO STATISTICO · FASE 1")
        for line in PhaseOneScript.report_lines(phase1_progress):
            _add_overlay_label(line)
        _add_overlay_button("GUIDA FASE 2",_on_phase_two)

func _on_phase_two() -> void:
    if not entities.has(player_id):
        return
    var branch: String = str(entities[player_id]["branch"])
    var traits: Dictionary = entities[player_id]["traits"]
    if not bool(phase1_progress.get("complete",false)):
        _on_goals()
        return
    _open_overlay("FASE 2 · COOPERAZIONE", "Cinque traguardi per un consorzio stabile e trasmissibile")
    for line in PhaseScript.objective_lines(phase2_progress):
        _add_overlay_label(line)
    if branch != "archaea":
        _add_overlay_label("Per questa campagna scegli una discendente Archaea. Le Bacteria restano linee separate.")
    else:
        var surface_ok: bool = GenomeScript.has(traits,"surface_recognition") or GenomeScript.has(traits,"eps_biosynthesis")
        var transporter_ok: bool = GenomeScript.has(traits,"membrane_transport")
        _add_overlay_label(("✓" if surface_ok else "○")+" Gene: recettori di riconoscimento oppure adesione EPS")
        _add_overlay_label(("✓" if transporter_ok else "○")+" Gene: trasportatore di membrana")
        _add_overlay_label("Quando dividi una Archaea, una delle figlie puo acquisire una nuova variante maggiore.")
        _add_overlay_label("Avvicinati a una Bacteria compatibile e premi COOPERA; mantenetevi abbastanza vicine.")
        _add_overlay_label("Il flusso scambia risorse con costi per entrambe le cellule. Dopo 25 s e 12 s di scambio, dividiti.")
    _add_overlay_label("Nota biologica: l'aggregazione cellulare e la sintrofia sono diverse dall'endosimbiosi.")

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
            "points":e["points"],"purchased":e["purchased"],"age":e["age"],
            "phase2_progress":e.get("phase2_progress",PhaseScript.empty()),
            "zero_atp_seconds":e.get("zero_atp_seconds",0.0)})
    var particle_data: Array = []
    for n in nutrients:
        if is_instance_valid(n["node"]):
            var position: Vector3 = n["node"].position
            particle_data.append({"kind":n["kind"],"pos":[position.x,position.y,position.z]})
    var data: Dictionary = {"version":71,"elapsed":t,"player_id":player_id,"next_id":next_id,
        "entities":cells,"genealogy":genealogy,"nutrients":particle_data,
        "partner":partner_id,"phase_two":phase_two,"phase2_progress":phase2_progress,
        "phase1_progress":phase1_progress,"zero_atp_seconds":zero_atp_seconds,
        "last_external_arrival":last_external_arrival,"world_age":world_age}
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _notice("Non esiste ancora una partita salvata")
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        _notice("Impossibile leggere il salvataggio")
        return
    var loaded: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (loaded is Dictionary) or not [67,70,71].has(int(loaded.get("version",0))):
        _notice("Salvataggio incompatibile: supportate versioni 0.67, 0.70 e 0.71")
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
        for key in ["hp","atp","energy","biomass","resources","points","purchased","age","phase2_progress","zero_atp_seconds"]:
            if record.has(key):
                target[key] = record[key]
        target["phase2_progress"] = PhaseScript.normalize(target.get("phase2_progress",{}))
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
    if int(loaded.get("version",0)) >= 70:
        phase2_progress = PhaseScript.normalize(loaded.get("phase2_progress",{}))
    else:
        # Il vecchio timer prova vicinanza, NON scambio metabolico:
        # nessun traguardo biologico e' inventato durante la migrazione.
        phase2_progress = PhaseScript.empty()
        if partner_id != "" and entities.has(partner_id) and entities[player_id]["branch"] == "archaea":
            phase2_progress["discovered"] = true
            phase2_progress["adhesion"] = true
            phase2_progress["partner_id"] = partner_id
            phase2_progress["last_partner_id"] = partner_id
            phase2_progress["bonded"] = true
            phase2_progress["contact_seconds"] = clampf(float(loaded.get("phase_two",0.0)),0.0,25.0)
        entities[player_id]["phase2_progress"] = phase2_progress.duplicate(true)
    if int(loaded.get("version",0)) >= 71:
        phase1_progress = PhaseOneScript.normalize(loaded.get("phase1_progress",{}))
    else:
        phase1_progress = PhaseOneScript.empty()
        phase1_progress["intro_seen"] = true
        # Protect completed Phase 2 campaigns saved by ORIGINI 0.70.
        if bool(phase2_progress.get("complete",false)):
            phase1_progress["complete"] = true
            phase1_progress["phase_two_intro_seen"] = true
        phase1_progress["player_divisions"] = maxi(0,int(loaded.get("next_id",1))/2)
    zero_atp_seconds = maxf(0.0,float(loaded.get("zero_atp_seconds",0.0)))
    partner_id = str(phase2_progress.get("partner_id",""))
    phase_two = float(phase2_progress.get("contact_seconds",0.0))
    last_external_arrival = float(loaded.get("last_external_arrival",-60.0))
    world_age = float(loaded.get("world_age",t))
    if not entities.has(partner_id) or entities[player_id]["branch"] != "archaea":
        partner_id = ""
        phase_two = 0.0
        phase2_progress = PhaseScript.release(phase2_progress)
    eco_tick = 0.0
    autosave_timer = 0.0
    skill_cooldown = 0.0
    regeneration_cooldown = 0.0
    division_options.clear()
    is_paused = false
    _close_overlay()
    _refresh_hud()
    _notice("Partita caricata · fasi, genoma, energia e genealogia ripristinati")

func _notice(message: String) -> void:
    if is_instance_valid(tips_label):
        tips_label.text = message
        tips_label.visible = true
        if is_instance_valid(toast_back):
            toast_back.visible = true
        tips_label.add_theme_color_override("font_color",Color(.95,.90,.71))
        notice_expires = t+5.0

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
    if str(entities[player_id]["branch"]) == "archaea":
        objective_label.text = PhaseScript.short_objective(phase2_progress)
    elif not bool(traits.get("dna",false)):
        objective_label.text = "FASE 1 · Nutriti, dividi la cellula e segui una linea con DNA stabile"
    elif str(entities[player_id]["branch"]) == "luca":
        objective_label.text = "FASE 1 · Scegli la diversificazione in Bacteria o Archaea"
    else:
        objective_label.text = "FASE 1 · Esplora una linea Bacteria e le sue mutazioni ereditarie"
    var danger_temperature: float = 43.0+18.0*float(traits.get("thermotolerance",0.0))
    if _temperature_at(player.position) > danger_temperature:
        objective_label.text = "STRESS TERMICO · Allontanati dalla sorgente o evolvi termotolleranza"
        objective_label.add_theme_color_override("font_color",Color(.98,.71,.59))
    else:
        objective_label.add_theme_color_override("font_color",Color(.83,.95,.96))
    partner_compass_label.visible = false
    if str(entities[player_id]["branch"]) == "archaea" and not bool(phase2_progress.get("complete",false)):
        var closest_id: String = ""
        var nearest: float = INF
        for id in entities:
            if str(id) == player_id or str(entities[id]["branch"]) != "bacteria":
                continue
            var d: float = entities[id]["node"].position.distance_to(player.position)
            if d < nearest:
                closest_id = str(id)
                nearest = d
        if closest_id != "":
            var delta_partner: Vector3 = entities[closest_id]["node"].position-player.position
            var arrow: String = "→" if delta_partner.x >= 0 else "←"
            if absf(delta_partner.z) > absf(delta_partner.x):
                arrow = "↓" if delta_partner.z >= 0 else "↑"
            var ready: bool = PhaseScript.can_adhere(traits,entities[closest_id]["traits"])
            partner_compass_label.text = "BACTERIA  %s  %.1f m  ·  %s" % [arrow,nearest,"adesione compatibile" if ready else "altro fenotipo"]
            partner_compass_label.visible = true
    buttons["tree"].text = "EVOLUZIONE (%d)" % mutation_points
    if is_instance_valid(classic_hud):
        var step: int = 1
        var chapter_title: String = "1/3 · PRIMA DISCENDENZA"
        var chapter_detail: String = "LA TUA PRIMA SCISSIONE"
        var chapter_fraction: float = clampf(scission_bar.value/100.0,0.0,1.0)
        if bool(traits.get("dna",false)):
            step = 2
            chapter_title = "2/3 · DIVERSIFICAZIONE"
            chapter_detail = "BACTERIA E ARCHAEA: LINEE SORELLE"
            chapter_fraction = 1.0 if str(entities[player_id]["branch"]) in ["bacteria","archaea"] else .50
        if str(entities[player_id]["branch"]) == "archaea":
            step = 3
            chapter_title = "3/3 · COOPERAZIONE CELLULARE"
            chapter_detail = "ASSOCIAZIONE PROCARIOTICA · FASE 2"
            var done: int = 0
            for key in ["discovered","adhesion","exchanged","stable","transmitted"]:
                if bool(phase2_progress.get(key,false)):
                    done += 1
            chapter_fraction = float(done)/5.0
        if bool(phase2_progress.get("complete",false)):
            chapter_title = "FASE 2 COMPLETATA · CONSORZIO STABILE"
            chapter_detail = "NUOVE GENERAZIONI · NUOVE POSSIBILITA"
            chapter_fraction = 1.0
        var elapsed_seconds: int = int(t)
        var simple_objective: String = objective_label.text
        if simple_objective.length() > 68:
            simple_objective = simple_objective.substr(0,65)+"..."
        classic_hud.configure({
            "gen":generation,"branch":stage,
            "elapsed":"%02d:%02d" % [int(elapsed_seconds/60),elapsed_seconds%60],
            "temp":_temperature_at(player.position),
            "atp":atp,"hp":hp,
            "carbon":resources["carbon"],"amino":resources["amino"],
            "lipid":resources["lipid"],"nucleic":resources["nucleic"],
            "chapter":chapter_title,"chapter_detail":chapter_detail,
            "objective":simple_objective,"chapter_progress":chapter_fraction,
            "fission":clampf(scission_bar.value/100.0,0.0,1.0),
            "can_divide":_can_divide(),
            "requirements_1":"C %d/24    A %d/15" % [int(resources["carbon"]),int(resources["amino"])],
            "requirements_2":"L %d/12    N %d/8" % [int(resources["lipid"]),int(resources["nucleic"])],
            "requirements_3":"BIO %d/65   ATP %d/30" % [int(resources["biomass"]),int(atp)]
        })
        buttons["enzymes"].text = "✦ ENZIMI\n12 ATP · PRONTI" if GenomeScript.has(traits,"hydrolase_secretion") else "✦ ENZIMI\nGENE RICHIESTO"
        buttons["lysis"].text = "✷ LISI\n18 ATP" if GenomeScript.has(traits,"hydrolase_secretion") and GenomeScript.has(traits,"surface_recognition") else "✷ LISI\nBLOCCATA"
        buttons["cooperate"].text = "∞ COOPERA\nFASE 2" if str(entities[player_id]["branch"]) == "archaea" else "∞ COOPERA\nARCHAEA"
        buttons["regen"].text = "✚ RIGENERA\n30 HP"
        buttons["menu"].text = "☰ MENU\nOPZIONI"
        scission_button.text = "◌  ◌\nDIVIDI"

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
    classic_hud = ClassicHudScript.new()
    classic_hud.name = "MobileClassicHUD"
    hud.add_child(classic_hud)
    nutrient_markers = NutrientMarkersScript.new()
    nutrient_markers.name = "WorldNutrientGlyphs"
    hud.add_child(nutrient_markers)
    hud.move_child(nutrient_markers,0)
    cell_world_glyphs = CellWorldGlyphScript.new()
    cell_world_glyphs.name = "BiologicalCellSilhouettes"
    hud.add_child(cell_world_glyphs)
    hud.move_child(cell_world_glyphs,1)
    title_label = _label("ORIGINI",21)
    hud.add_child(title_label)
    status_label = _label("ATP · HP · biomassa",15)
    hud.add_child(status_label)
    objective_label = _label("Obiettivo",15)
    hud.add_child(objective_label)
    partner_compass_label = _label("",14)
    partner_compass_label.visible = false
    hud.add_child(partner_compass_label)
    tips_label = _label("",14)
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
    _button("RISORSE",_on_resources,"nutrients")
    _button("ALBERO",_on_tree,"tree")
    _button("LINEA",_on_genealogy,"genealogy")
    _button("META",_on_goals,"goals")
    _button("SALVA",_save_game,"save")
    _button("CARICA",_load_game,"load")
    _button("GENOMA",_on_genome,"genome")
    _button("CELLULA",_toggle_focus,"focus")
    _button("MENU",_open_main_menu,"menu")
    toast_back = Panel.new()
    toast_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_back.add_theme_stylebox_override("panel",_style(Color(.018,.12,.16,.94),Color(.37,.74,.75,.85)))
    toast_back.visible = false
    hud.add_child(toast_back)
    tips_label.reparent(hud)
    hud.move_child(tips_label,hud.get_child_count()-1)
    overlay = ColorRect.new()
    overlay.color = Color(.005,.025,.040,.97)
    overlay.visible = false
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(overlay)
    _layout_ui()

func _theme_button(b: Button, bg: Color, rim: Color, font_size: int = 16, roundness: int = 16) -> void:
    var normal: StyleBoxFlat = _style(bg,rim)
    normal.set_corner_radius_all(roundness)
    normal.shadow_color = Color(.0,.01,.03,.35)
    normal.shadow_size = 4
    b.add_theme_stylebox_override("normal",normal)
    var hover: StyleBoxFlat = _style(bg.lightened(.13),rim.lightened(.18))
    hover.set_corner_radius_all(roundness)
    b.add_theme_stylebox_override("hover",hover)
    var pressed: StyleBoxFlat = _style(bg.lightened(.23),rim.lightened(.23))
    pressed.set_corner_radius_all(roundness)
    b.add_theme_stylebox_override("pressed",pressed)
    var focus_style: StyleBoxFlat = _style(Color.TRANSPARENT,rim.lightened(.28))
    focus_style.set_corner_radius_all(roundness)
    b.add_theme_stylebox_override("focus",focus_style)
    b.add_theme_color_override("font_color",Color(.92,.97,.97))
    b.add_theme_font_size_override("font_size",font_size)
    b.clip_text = true

func _layout_ui() -> void:
    if not is_instance_valid(hud):
        return
    var wh: Vector2 = get_viewport().get_visible_rect().size
    if wh.x < 1 or wh.y < 1:
        return
    hud.size = wh
    var portrait: bool = wh.y > wh.x
    classic_hud.set_viewport(wh)
    classic_hud.visible = portrait
    cell_world_glyphs.visible = portrait and not camera_focus
    cell_world_glyphs.size = wh
    for cell_id in entities:
        var e: Dictionary = entities[cell_id]
        if is_instance_valid(e["node"]):
            e["node"].visible = not (portrait and not camera_focus)
    nutrient_markers.size = wh
    nutrient_markers.visible = portrait
    for n in nutrients:
        if is_instance_valid(n["node"]):
            n["node"].visible = not portrait
    for label in [title_label,status_label,objective_label]:
        label.visible = not portrait
    for bar in [hp_bar,atp_bar,scission_bar]:
        bar.visible = not portrait

    if portrait:
        # Coordinates are mobile-first based on a 720 px portrait canvas,
        # then scaled together to retain original JavaScript-style spacing.
        var ui: float = clampf(wh.x/720.0,.62,1.65)
        var bw: float = wh.x/ui
        var bh: float = wh.y/ui
        var compact: bool = bh < 1120
        var tab_y: float = 365.0 if compact else 391.0
        var tabs: Array[String] = ["nutrients","tree","goals","genealogy"]
        var actions: Array[String] = ["regen","cooperate","focus","enzymes","lysis","menu"]
        for key in buttons:
            buttons[key].visible = tabs.has(str(key)) or actions.has(str(key)) or str(key) == "divide"
        var tab_width: float = (bw-38.0-3.0*8.0)/4.0
        for i in range(tabs.size()):
            var tab: Button = buttons[tabs[i]]
            tab.position = Vector2(19+float(i)*(tab_width+8.0),tab_y)*ui
            tab.size = Vector2(tab_width,43)*ui
            tab.text = ("RISORSE" if i == 0 else ("EVOLUZIONE" if i == 1 else ("META" if i == 2 else "LINEA"))) if i != 1 else "EVOLUZIONE (%d)" % mutation_points
            _theme_button(tab,Color(.025,.19,.225,.97),Color(.25,.67,.66,.85),14)
        var left: Array[String] = ["regen","cooperate","focus"]
        var right: Array[String] = ["enzymes","lysis","menu"]
        var action_top: float = bh-383.0
        for i in range(3):
            var b_left: Button = buttons[left[i]]
            b_left.position = Vector2(18,action_top+float(i)*68.0)*ui
            b_left.size = Vector2(151,60)*ui
            _theme_button(b_left,Color(.025,.16,.195,.94),Color(.28,.70,.69,.82),14)
            var b_right: Button = buttons[right[i]]
            b_right.position = Vector2(bw-169,action_top+float(i)*68.0)*ui
            b_right.size = Vector2(151,60)*ui
            _theme_button(b_right,Color(.16,.12,.18,.93) if i == 0 else Color(.075,.13,.17,.94),
                Color(.84,.57,.46,.85) if i == 0 else Color(.34,.52,.61,.75),14)
        joystick.radius = 62.0*ui
        joystick.size = Vector2(150,150)*ui
        joystick.position = Vector2(19,bh-181)*ui
        scission_button.position = Vector2(bw-169,bh-177)*ui
        scission_button.size = Vector2(150,145)*ui
        _theme_button(scission_button,Color(.38,.28,.57,.99),Color(.79,.66,.96,.98),21,73)
        partner_compass_label.position = Vector2(181,bh*.59)*ui
        partner_compass_label.size = Vector2(maxf(170,bw-362),34)*ui
        partner_compass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        partner_compass_label.add_theme_color_override("font_color",Color(.67,.94,.85))
        partner_compass_label.add_theme_font_size_override("font_size",14)
        toast_back.position = Vector2(173,bh*.48)*ui
        toast_back.size = Vector2(maxf(173,bw-346),78)*ui
        tips_label.position = toast_back.position+Vector2(12,12)*ui
        tips_label.size = toast_back.size-Vector2(24,22)*ui
        tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tips_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        tips_label.add_theme_font_size_override("font_size",14)
    else:
        # Preserve functional landscape support for desktop Godot and tests.
        title_label.position = Vector2(18,12)
        title_label.size = Vector2(wh.x-36,28)
        status_label.position = Vector2(18,45)
        status_label.size = Vector2(wh.x-36,25)
        objective_label.position = Vector2(18,78)
        objective_label.size = Vector2(wh.x-36,26)
        hp_bar.position = Vector2(18,116)
        hp_bar.size = Vector2(170,9)
        atp_bar.position = Vector2(196,116)
        atp_bar.size = Vector2(170,9)
        scission_bar.position = Vector2(wh.x-250,wh.y-100)
        scission_bar.size = Vector2(230,8)
        var landscape_keys: Array[String] = ["divide","regen","enzymes","lysis","cooperate","focus","menu"]
        for key in buttons:
            buttons[key].visible = landscape_keys.has(str(key))
        for i in range(landscape_keys.size()):
            var btn: Button = buttons[landscape_keys[i]]
            btn.position = Vector2(wh.x-(landscape_keys.size()-float(i))*119.0-6.0,wh.y-85)
            btn.size = Vector2(113,61)
            _theme_button(btn,Color(.031,.15,.185,.94),Color(.29,.69,.71,.81),13)
        joystick.radius = 49.0
        joystick.size = Vector2(116,116)
        joystick.position = Vector2(18,wh.y-140)
        partner_compass_label.position = Vector2(24,148)
        partner_compass_label.size = Vector2(wh.x-48,25)
        toast_back.position = Vector2(wh.x*.32,wh.y*.48)
        toast_back.size = Vector2(wh.x*.36,62)
        tips_label.position = toast_back.position+Vector2(12,8)
        tips_label.size = toast_back.size-Vector2(24,16)

    overlay.size = wh
    if is_instance_valid(overlay_scroll):
        var ov_scale: float = clampf(wh.x/720.0,.62,1.65) if portrait else 1.0
        overlay_scroll.position = Vector2(34,144)*ov_scale
        overlay_scroll.size = Vector2(maxf(100.0,wh.x-68*ov_scale),maxf(100.0,wh.y-175*ov_scale))
    if is_instance_valid(overlay_panel):
        var p_scale: float = clampf(wh.x/720.0,.62,1.65) if portrait else 1.0
        overlay_panel.position = Vector2(16,18)*p_scale
        overlay_panel.size = wh-Vector2(32,36)*p_scale
    for child in overlay.get_children():
        if child is MutationTree or child is LineageView:
            var u: float = clampf(wh.x/720.0,.62,1.65) if portrait else 1.0
            child.position = Vector2(34,145)*u
            child.size = Vector2(wh.x-68*u,wh.y-183*u)

func _open_overlay(title: String, subtitle: String) -> void:
    overlay.visible = true
    is_paused = true
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(false)
    for c in overlay.get_children():
        overlay.remove_child(c)
        c.queue_free()
    var wh: Vector2 = get_viewport().get_visible_rect().size
    var portrait: bool = wh.y > wh.x
    var u: float = clampf(wh.x/720.0,.62,1.65) if portrait else 1.0
    overlay.color = Color(.003,.016,.027,.985)
    overlay_panel = Panel.new()
    overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay_panel.position = Vector2(16,18)*u
    overlay_panel.size = wh-Vector2(32,36)*u
    var panel_style: StyleBoxFlat = _style(Color(.012,.083,.113,.99),Color(.27,.52,.57,.82))
    panel_style.set_corner_radius_all(24)
    panel_style.set_border_width_all(2)
    overlay_panel.add_theme_stylebox_override("panel",panel_style)
    overlay.add_child(overlay_panel)
    var eyebrow_text: String = "DIVISIONE COMPLETATA  ·  SCEGLI LA DISCENDENZA" if title.begins_with("QUALE FIGLIA") else "ORIGINI  ·  ARCHIVIO EVOLUTIVO"
    var eyebrow := _label(eyebrow_text,13)
    eyebrow.add_theme_color_override("font_color",Color(.43,.90,.78))
    eyebrow.position = Vector2(36,34)*u
    eyebrow.size = Vector2(wh.x/u-178,20)*u
    overlay.add_child(eyebrow)
    var heading := _label(title,23)
    heading.position = Vector2(36,57)*u
    heading.size = Vector2(wh.x/u-173,32)*u
    overlay.add_child(heading)
    var description := _label(subtitle,14)
    description.position = Vector2(36,95)*u
    description.size = Vector2(wh.x/u-65,40)*u
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay.add_child(description)
    var close := Button.new()
    close.text = "✕"
    close.position = Vector2(wh.x/u-87,40)*u
    close.size = Vector2(52,46)*u
    _theme_button(close,Color(.049,.19,.23,.97),Color(.32,.65,.69,.78),19,14)
    overlay.add_child(close)
    close.pressed.connect(_close_overlay)
    if title == "LINEA ESTINTA":
        close.visible = false
    overlay_scroll = ScrollContainer.new()
    overlay_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    overlay_scroll.position = Vector2(34,144)*u
    overlay_scroll.size = Vector2(maxf(100,wh.x-68*u),maxf(100,wh.y-175*u))
    overlay.add_child(overlay_scroll)
    overlay_list = VBoxContainer.new()
    overlay_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overlay_list.add_theme_constant_override("separation",14)
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
