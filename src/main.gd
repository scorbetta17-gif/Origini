extends Node3D
## ORIGINI — campagna unica: Cellula Zero → grado LECA.
## Scene 3D reali, camera isometrica, fenotipi procedurali, UI mobile.

const Evolution = preload("res://src/evolution_progress.gd")
const Statistics = preload("res://src/game_statistics.gd")
const Ecology = preload("res://src/niche_ecology.gd")
const Balance = preload("res://src/mutation_balance.gd")
const SubstrateScript = preload("res://src/substrate_patch.gd")
var substrates: Array[Node3D] = []
var selected_substrate: Node3D
var substrate_respawn: float = 0.0
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
const PHASE_TWO_CHECKPOINT = "user://origini_phase_two.json"
var cooperation_target: String = ""
var exchange_active: bool = false
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
var mutation_points: float = 0.0
var evolution: Dictionary = {}
var ecology: Dictionary = {}
var ecological_profiles: Dictionary = {}
var statistics: Dictionary = Statistics.origin()
var cycle_age: float = 0.0
var division_active: bool = false
var ecology_syncing: bool = false
var cohort_timer: float = 0.0
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
# Overhead orthographic gameplay, unlike the prior low perspective.
var camera_offset := Vector3(0.0,24.0,13.0)
const ISOMETRIC_CAMERA_SIZE: float = 19.5
var camera_focus: bool = false
var world_radius: float = preload("res://src/seabed_palette.gd").WORLD_RADIUS
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
var collectives: Node
var events: Node
var next_particle_uid: int = 1
var campaign: Node
var journey: Node
var habitats: Node
var battle: Node

func _ready() -> void:
    rng.randomize()
    _make_3d_scene()
    _build_ui()
    _setup_metabolic_visuals()
    battle = preload("res://src/battle_royale.gd").new()
    battle.game = self
    add_child(battle)
    journey = preload("res://src/campaign_journey.gd").new()
    journey.game = self
    add_child(journey)
    habitats = preload("res://src/campaign_habitats.gd").new()
    habitats.game = self
    add_child(habitats)
    campaign = preload("res://src/campaign_world.gd").new()
    campaign.game = self
    add_child(campaign)
    campaign.reset()
    if events == null:
        events = preload("res://src/campaign_events.gd").new()
        events.game = self
        add_child(events)
    events.reset()
    if collectives == null:
        collectives = preload("res://src/campaign_collectives.gd").new()
        collectives.game = self
        add_child(collectives)
    collectives.reset()
    _new_game()
    get_viewport().size_changed.connect(_layout_ui)

func _new_game(arena: bool = false) -> void:
    if is_instance_valid(battle): battle.reset()
    world_radius = preload("res://src/seabed_palette.gd").WORLD_RADIUS
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
    statistics = Statistics.origin()
    evolution = Evolution.origin()
    ecology = Ecology.origin()
    ecological_profiles.clear()
    cycle_age = 0.0
    division_active = false
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
    cooperation_target = ""
    exchange_active = false
    attack_mode = ""
    division_options.clear()
    is_paused = false
    camera_focus = false
    camera_offset = Vector3(0,24.0,13.0)
    if is_instance_valid(camera):
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = ISOMETRIC_CAMERA_SIZE
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
        _create_nutrient(Balance.NUTRIENT_CYCLE[i % Balance.NUTRIENT_CYCLE.size()], Vector3(x,.19,z))
    _reset_substrates()
    campaign.reset()
    if events == null:
        events = preload("res://src/campaign_events.gd").new()
        events.game = self
        add_child(events)
    events.reset()
    if collectives == null:
        collectives = preload("res://src/campaign_collectives.gd").new()
        collectives.game = self
        add_child(collectives)
    collectives.reset()
    journey.reset(arena)
    habitats.rebuild(not arena)
    if not arena:
        habitats.seed_world()
        collectives.seed_donors()
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
    # FONDAMENTALE: vista dall'alto in proiezione ortografica isometrica.
    # Tutti gli affioramenti, i vulcani e le fessure sono geometria 3D vera.
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = ISOMETRIC_CAMERA_SIZE
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
    # Il pickup fisico (vista landscape/macro) cresce del 10% come l'icona 2D.
    sphere.radius = .143 if kind == "detritus" else (.0935 if kind != "nucleic" else .0737)
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
    nutrients.append({"uid":next_particle_uid,"kind": kind, "node": node, "origin_y": at.y, "bob": rng.randf_range(0,TAU)})
    next_particle_uid += 1

func _create_entity(id: String, parent: String, gen: int, branch: String, traits: Dictionary, at: Vector3, controlled: bool = false, external: bool = false) -> void:
    if entities.has(id):
        return
    var inherited: Dictionary = Balance.normalize(GenomeScript.normalize(traits,branch))
    var node: CellVisual = CellScript.new()
    cells_root.add_child(node)
    node.position = at
    node.setup(inherited, branch, controlled)
    node.visible = true
    node.set_growth(Physiology.growth_scale(24.0,23.0,65.0))
    var inventory: Dictionary = {"carbon":6.0,"amino":4.0,"lipid":3.0,"nucleic":1.0,"biomass":24.0}
    entities[id] = {"node":node,"parent":parent,"generation":gen,"branch":branch,
        "traits":inherited.duplicate(true),"external":external,"age":0.0,
        "biomass":24.0,"energy":46.0,"hp":100.0,"atp":65.0,
        "velocity":Vector3.ZERO,"intent_velocity":Vector3.ZERO,
        "zero_energy_seconds":0.0,"zero_atp_seconds":0.0,
        "strategy":Physiology.strategy(inherited),
        "resources":inventory,"points":0,"purchased":{},"fission_count":0,
        "phase2_progress":PhaseScript.empty(), "evolution":Evolution.origin(),
        "ecotype":id, "cycle_age":0.0,"census_position":at}
    if not ecology_syncing:
        var ecotype: String = str(entities[parent].get("ecotype",parent)) if entities.has(parent) else id
        entities[id]["ecotype"] = ecotype
        Ecology.register_birth(ecology,ecotype,at)
        ecological_profiles[ecotype] = inherited.duplicate(true)
        ecological_profiles[ecotype]["ecological_branch"] = branch
        ecological_profiles[ecotype]["ecological_generation"] = gen
        ecological_profiles[ecotype]["founder_id"] = id
    if is_instance_valid(battle) and battle.active() and not ecology_syncing:
        battle.state.teams[id] = battle.team(parent) if parent!="" else id
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
    e["evolution"] = evolution.duplicate(true)
    e["cycle_age"] = cycle_age
    e["hp"] = hp
    e["atp"] = atp
    e["energy"] = atp
    e["resources"] = resources.duplicate(true)
    e["points"] = mutation_points
    e["purchased"] = purchased.duplicate(true)
    e["biomass"] = float(resources.get("biomass",22.0))
    e["phase2_progress"] = phase2_progress.duplicate(true)
    e["zero_atp_seconds"] = zero_atp_seconds
    e["strategy"] = Physiology.strategy(e["traits"])

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
    mutation_points = maxf(0.0,float(e.get("points",0)))
    evolution = Evolution.normalize(e.get("evolution",{}))
    cycle_age = maxf(0.0,float(e.get("cycle_age",0)))
    purchased = e.get("purchased", {}).duplicate(true)
    phase2_progress = PhaseScript.normalize(e.get("phase2_progress",{}))
    partner_id = str(phase2_progress.get("partner_id",""))
    phase_two = float(phase2_progress["contact_seconds"])
    if partner_id != "" and (not entities.has(partner_id) or str(e.get("branch","")) != "archaea"):
        partner_id = ""
        phase2_progress = PhaseScript.release(phase2_progress)
    selected_target_id = ""
    selected_nutrient = null
    selected_substrate = null
    cooperation_target = ""
    exchange_active = false
    attack_mode = ""
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(true)
        joystick.reset_input()

func _remove_entity(id: String, cause: String) -> void:
    if not entities.has(id):
        return
    if battle.active() and cause not in ["scissione","internalizzazione"]: battle.scoring.death(battle.state,id)
    var rec: Dictionary = entities[id]
    var at: Vector3 = rec["node"].position if is_instance_valid(rec["node"]) else Vector3.ZERO
    if is_instance_valid(rec["node"]):
        rec["node"].queue_free()
    if not ecology_syncing:
        Ecology.register_death(ecology,str(rec.get("ecotype",id)),at)
    entities.erase(id)
    for entry in genealogy:
        if str(entry["id"]) == id:
            entry["alive"] = false
            entry["status"] = "divisa" if cause == "scissione" else ("endosimbionte" if cause == "internalizzazione" else "estinta")
            entry["cause"] = cause
            break
    if id == selected_target_id:
        selected_target_id = ""
        attack_mode = ""
    if id == partner_id:
        partner_id = ""
        phase_two = 0.0
        phase2_progress = PhaseScript.release(phase2_progress)
    if cause != "scissione" and cause != "internalizzazione":
        # I detriti cellulari hanno un'origine tracciabile.
        for i in range(3):
            _create_nutrient("detritus", at + Vector3(rng.randf_range(-.7,.7),.28,rng.randf_range(-.7,.7)))
        if bool(rec["traits"].get("dna",false)):
            _create_nutrient("detritus", at + Vector3(.25,.28,-.15))

func _register_death(id: String, reason: String = "morte") -> void:
    _remove_entity(id,reason)

func _process(delta: float) -> void:
    _expire_notice()
    if is_instance_valid(player):
        world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso").update_focus(player.position)
    if division_active or is_paused or not is_instance_valid(player) or not entities.has(player_id):
        return
    delta = minf(delta,.07)
    t += delta
    if not events.dormant(player_id): cycle_age += delta
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
        selected_substrate = null
        cooperation_target = ""
        attack_mode = ""
        _move_player(direction.normalized(),delta)
    elif atp > 0.0 and cooperation_target != "":
        _approach_partner(delta)
    elif atp > 0.0 and (selected_target_id != "" or is_instance_valid(selected_nutrient) or is_instance_valid(selected_substrate)):
        _follow_attack(delta)
    else:
        _move_player(Vector2.ZERO,delta)
    var travelled: float = player.position.distance_to(position_before_movement)
    var physiology_state: Dictionary = Physiology.energy_step(atp,zero_atp_seconds,delta,
        travelled,events.resting_traits(player_id))
    atp = float(physiology_state["atp"])
    zero_atp_seconds = float(physiology_state["zero_seconds"])
    if bool(physiology_state["dead"]):
        hp = 0.0
    var player_temperature: float = _temperature_at(player.position)
    var tolerance: float = 43.0+18.0*float(entities[player_id]["traits"].get("thermotolerance",0.0))
    if not battle.active() and player_temperature > tolerance:
        hp = maxf(0.0,hp-delta*(player_temperature-tolerance)*.075/maxf(.65,float(entities[player_id]["traits"].get("vitality",1.0))))
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
    _respawn_nutrients(delta)
    _update_npc_motion(delta)
    _update_nutrient_markers()
    _update_cell_world_glyphs()
    eco_tick += delta
    if eco_tick >= .22:
        _update_ecosystem(eco_tick)
        eco_tick = 0.0
    if hp<=0.0:
        _game_over()
        return
    if battle.active():
        battle.advance(delta)
        if not str(battle.state.result).is_empty(): return
    else:
        _advance_phase_two(delta)
        _advance_niches(delta)
        campaign.advance(delta)
        events.advance(delta)
        collectives.advance(delta)
    _update_metabolic_visuals()
    _cache_current()
    if hp <= 0:
        _game_over()
        return
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
    var active: bool = exchange_active and entities.has(player_id) and partner_id != "" and entities.has(partner_id)
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
        _save_game(PHASE_TWO_CHECKPOINT)
        _open_phase_intro(2)

func _open_phase_intro(_number: int) -> void:
    _open_overlay("ORIGINI · UNA LINEA NELL’OCEANO", "Dalla Cellula Zero al grado LECA · una campagna continua")
    _add_overlay_label("Nutriti, esplora e dividi la cellula. La scissione animata dà 2 PM, fino a 3 con adattabilità: le frazioni si conservano.")
    _add_overlay_label("Spendi i punti nell’albero: ogni specializzazione offre vantaggi e costi. Le figlie ereditano il genoma; non ci sono carte casuali da scegliere.")
    _add_overlay_label("Conquista nicchie con almeno 30 cellule/km². Una densità pari a 1,5 volte la rivale maggiore dà dominanza; altrimenti puoi coesistere.")
    _add_overlay_label("Le popolazioni fuori campo sono coorti simulate, non migliaia di modelli 3D. Una nuova linea deve riconquistare le nicchie; le precedenti restano.")
    _add_overlay_label("La progressione richiede molte divisioni e capacità stabili. I punti e la scala cartografica sono astrazioni di gioco, non una ricostruzione storica.")
    _add_overlay_button("ENTRA NELL’OCEANO",_close_overlay)

func _advance_phase_two(delta: float) -> void:
    exchange_active = false
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
    exchange_active = bool(result["exchange_active"])
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
    if is_instance_valid(battle) and battle.active(): return float(battle.rules.environment(battle.state.elapsed,where).temperature)
    # Modello locale e ludico del gradiente, non ricostruzione di un oceano storico.
    var result: float = 29.0
    for i in range(THERMAL_SOURCES.size()):
        var xy: Vector2 = THERMAL_SOURCES[i]
        var distance_squared: float = Vector2(where.x-xy.x,where.z-xy.y).length_squared()
        result += THERMAL_AMPLITUDE[i]*exp(-distance_squared/THERMAL_DECAY[i])
    return result

func _toggle_focus() -> void:
    camera_focus = not camera_focus
    # Macro 3D ravvicinato solo su richiesta. Ritorno al vero isometrico.
    camera_offset = Vector3(1.3,2.1,3.4) if camera_focus else Vector3(0,24.0,13.0)
    if camera_focus:
        camera.projection = Camera3D.PROJECTION_PERSPECTIVE
        camera.fov = 38.0
    else:
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = ISOMETRIC_CAMERA_SIZE
    _layout_ui()
    buttons["focus"].text = "MONDO" if camera_focus else "CELLULA"

func _move_player(direction: Vector2, delta: float) -> void:
    if battle.active() and battle.combat.busy(battle,player_id): direction=Vector2.ZERO
    if events.dormant(player_id):
        entities[player_id]["velocity"] = Vector3.ZERO
        return
    var traits: Dictionary = entities[player_id]["traits"]
    var speed: float = Physiology.player_speed(traits,partner_id != "" and bool(phase2_progress.get("bonded",false)))*collectives.speed(player_id)
    # Short overdamped input filter: exact integration, no overshoot or long glide.
    var velocity: Vector3 = entities[player_id].get("velocity",Vector3.ZERO)
    var target := Vector3(direction.x,0,direction.y)*speed
    if atp <= 0:
        velocity = Vector3.ZERO
        target = Vector3.ZERO
    var dt: float = maxf(delta,0.0)
    var decay: float = exp(-dt/.075)
    player.position += target*dt+(velocity-target)*.075*(1.0-decay)
    entities[player_id]["velocity"] = target+(velocity-target)*decay
    player.position.x = clampf(player.position.x, -world_radius,world_radius)
    player.position.z = clampf(player.position.z, -world_radius,world_radius)
    if direction.length() > .2:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.y,direction.x), delta*4)

func _consume_nutrient(index: int, controlled: bool, cell_id: String = "") -> void:
    if index < 0 or index >= nutrients.size():
        return
    var n: Dictionary = nutrients[index]
    if battle.active():
        var intake_team: String = battle.team(player_id if controlled else cell_id)
        battle.state.packets[intake_team] = int(battle.state.packets.get(intake_team,0))+1
    var intake_id: String = player_id if controlled else cell_id
    var intake_before: Dictionary = resources.duplicate(true) if controlled else entities[cell_id].resources.duplicate(true)
    var kind: String = str(n["kind"])
    if controlled:
        var previous_stock: Dictionary = resources.duplicate(true)
        var uptake: float = float(entities[player_id]["traits"].get("uptake",1.0))*collectives.intake(player_id)
        if kind == "detritus":
            resources["carbon"] = minf(Physiology.reserve_cap(float(NEED["carbon"])),float(resources["carbon"])+2.0*uptake)
            resources["amino"] = minf(Physiology.reserve_cap(float(NEED["amino"])),float(resources["amino"])+1.5*uptake)
        else:
            resources[kind] = minf(Physiology.reserve_cap(float(NEED[kind])),float(resources[kind])+2.15*uptake)
        resources["biomass"] = minf(Physiology.reserve_cap(float(NEED["biomass"])),float(resources["biomass"])+1.45*uptake)
        atp = minf(100.0,atp+(6.0 if kind=="carbon" else (3.0 if kind=="detritus" else .75))*sqrt(float(entities[player_id]["traits"].get("metabolism",1.0)))*Physiology.energy_yield_multiplier(entities[player_id]["traits"]))
        if atp > 0.0:
            zero_atp_seconds = 0.0
        Statistics.record_intake(statistics,previous_stock,resources)
        statistics.particles += 1
    elif entities.has(cell_id):
        var e: Dictionary = entities[cell_id]
        var uptake_npc: float = float(e["traits"].get("uptake",1.0))*collectives.intake(cell_id)
        e["biomass"] = minf(Physiology.reserve_cap(float(NEED["biomass"])),float(e["biomass"])+2.3*uptake_npc)
        var stock: Dictionary = e["resources"]
        if kind == "detritus":
            stock["carbon"] = minf(Physiology.reserve_cap(float(NEED["carbon"])),float(stock["carbon"])+2.0*uptake_npc)
            stock["amino"] = minf(Physiology.reserve_cap(float(NEED["amino"])),float(stock["amino"])+1.5*uptake_npc)
        else:
            stock[kind] = minf(Physiology.reserve_cap(float(NEED[kind])),float(stock.get(kind,0.0))+2.15*uptake_npc)
        stock["biomass"] = e["biomass"]
        e["resources"] = stock
        e["energy"] = minf(100.0 if battle.active() else 85.0,float(e["energy"])+(6.0 if kind=="carbon" else 3.0)*Physiology.energy_yield_multiplier(e["traits"]))
        e["atp"] = e["energy"]
        if float(e["energy"]) > 0.0:
            e["zero_energy_seconds"] = 0.0
    if battle.active(): battle.scoring.intake(battle.state,intake_id,intake_before,resources if controlled else entities[cell_id].resources)
    if is_instance_valid(n["node"]):
        n["node"].queue_free()
    nutrients.remove_at(index)

func _award_bundle(bundle: Dictionary, controlled: bool, cell_id: String = "") -> void:
    if not controlled and not entities.has(cell_id):
        return
    var before_stock: Dictionary = resources.duplicate(true) if controlled else entities[cell_id].resources.duplicate(true)
    var stock: Dictionary = resources if controlled else entities[cell_id]["resources"]
    var traits: Dictionary = entities[player_id if controlled else cell_id]["traits"]
    var uptake: float = clampf(float(traits.get("uptake",1.0)),.50,1.80)
    for key in NEED:
        stock[key] = minf(Physiology.reserve_cap(float(NEED[key])),float(stock.get(key,0))+float(bundle.get(key,0))*uptake)
    if battle.active(): battle.scoring.intake(battle.state,player_id if controlled else cell_id,before_stock,stock)
    if controlled:
        resources = stock
        Statistics.record_intake(statistics,before_stock,resources)
        atp = minf(100.0,atp+float(bundle.get("atp",0))*Physiology.energy_yield_multiplier(traits))
        if atp>0:
            zero_atp_seconds = 0.0
    else:
        var entity: Dictionary = entities[cell_id]
        entity["resources"] = stock
        entity["biomass"] = stock["biomass"]
        entity["energy"] = minf(100.0 if battle.active() else 85.0,float(entity["energy"])+float(bundle.get("atp",0))*Physiology.energy_yield_multiplier(traits))
        entity["atp"] = entity["energy"]

func _spawn_substrate(at: Vector3, portions: int = 3, kind: String = "") -> void:
    var patch: Node3D = SubstrateScript.new()
    patch.name = "Substrato_organico"
    world_root.add_child(patch)
    var terrain: Node = world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
    patch.position = Vector3(at.x,terrain.surface_height(Vector2(at.x,at.z))+.04,at.z)
    patch.setup(int(absf(at.x*731+at.z*997))+441,portions,kind)
    substrates.append(patch)

func _reset_substrates(saved: Array = [], from_save: bool = false) -> void:
    selected_substrate = null
    for patch in substrates:
        if is_instance_valid(patch):
            patch.queue_free()
    substrates.clear()
    substrate_respawn = 0.0
    if from_save:
        for record in saved.slice(0,6):
            if record is Dictionary and record.get("pos",[]) is Array and record["pos"].size()==3:
                _spawn_substrate(Vector3(float(record["pos"][0]),0,float(record["pos"][2])),clampi(int(record.get("portions",3)),1,3),str(record.get("kind","")))
    else:
        for p in [Vector3(3.8,0,1.5),Vector3(-4,0,2),Vector3(4,0,-5),Vector3(-7,0,-6),Vector3(8,0,8),Vector3(0,0,12)]:
            _spawn_substrate(p,3,SubstrateScript.KINDS[substrates.size()%3])

func _maintain_substrates(delta: float) -> void:
    if not is_instance_valid(player):
        return
    substrate_respawn += maxf(delta,0.0)
    if substrates.size()<6 and substrate_respawn>=20.0:
        _spawn_substrate(_nearby_nutrient_position())
        substrate_respawn = 0.0
    for patch in substrates:
        if is_instance_valid(patch) and patch.position.distance_squared_to(player.position)>2500:
            var at: Vector3 = _nearby_nutrient_position()
            var terrain: Node = world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
            patch.position = Vector3(at.x,terrain.surface_height(Vector2(at.x,at.z))+.04,at.z)

func _digest_substrate(patch: Node3D) -> bool:
    return _digest_for(patch,player_id)

func _digest_for(patch: Node3D, id: String) -> bool:
    if not entities.has(id) or events.dormant(id) or not is_instance_valid(patch) or not substrates.has(patch): return false
    var controlled: bool = id == player_id
    if (controlled and skill_cooldown>0) or (not controlled and t<float(events.state.npc_cooldown.get(id,0))): return false
    var e: Dictionary = entities[id]
    var energy: float = atp if controlled else float(e.energy)
    if not GenomeScript.has(e.traits,"hydrolase_secretion") or energy<Balance.ENZYME_COST: return false
    var offset: Vector3 = patch.position-e.node.position
    offset.y = 0
    if offset.length()>1.55: return false
    if controlled: atp -= Balance.ENZYME_COST
    else: e.energy -= Balance.ENZYME_COST
    _award_bundle(patch.reward(),controlled,id)
    if controlled:
        statistics.substrates += 1
        journey.digested()
        events.on_digest(patch)
        skill_cooldown = 2.0
        _notice("%s: fino a 5 molecole recuperate (limite delle riserve)" % patch.LABELS[patch.kind])
    else: events.state.npc_cooldown[id] = t+2.0
    patch.set_portions(patch.portions-1)
    if patch.portions<=0:
        substrates.erase(patch)
        patch.queue_free()
        if selected_substrate == patch:
            selected_substrate = null
            attack_mode = ""
        substrate_respawn = 0.0
    return true

func _collect_nearby() -> void:
    for i in range(nutrients.size()-1,-1,-1):
        var n: Dictionary = nutrients[i]
        if not is_instance_valid(n["node"]):
            nutrients.remove_at(i)
            continue
        if player.position.distance_to(n["node"].position) > 1.08:
            continue
        var kind: String = str(n["kind"])
        if kind != "detritus" and float(resources[kind]) >= Physiology.reserve_cap(float(NEED[kind]))-.001 and float(resources["biomass"])>=Physiology.reserve_cap(float(NEED["biomass"]))-.001 and atp >= 95.0:
            continue
        _consume_nutrient(i,true)
func _respawn_nutrients(delta: float) -> void:
    if battle.active(): return
    _maintain_substrates(delta)
    _recycle_distant_nutrients()
    # Donor settlements retain their food; exploration gets a bounded local supply.
    if player.position.length()>40:
        var local_food: int=0
        for n in nutrients:
            if n.node.position.distance_to(player.position)<30: local_food+=1
        while local_food<40 and nutrients.size()<124:
            _create_nutrient(Balance.NUTRIENT_CYCLE[rng.randi_range(0,Balance.NUTRIENT_CYCLE.size()-1)],_nearby_nutrient_position())
            local_food+=1
    # Accumulate elapsed simulation time exactly once, independent of FPS.
    # eco_tick is cumulative and must never be added again on every frame.
    if nutrients.size() >= Physiology.nutrient_goal():
        nutrient_respawn = 0.0
        return
    nutrient_respawn += maxf(0.0,delta)
    while nutrient_respawn + .000001 >= .22 and nutrients.size() < Physiology.nutrient_goal():
        _create_nutrient(Balance.NUTRIENT_CYCLE[rng.randi_range(0,Balance.NUTRIENT_CYCLE.size()-1)], _nearby_nutrient_position())
        nutrient_respawn = maxf(0.0,nutrient_respawn-.22)
    if nutrients.size() >= Physiology.nutrient_goal():
        nutrient_respawn = 0.0

func _nearby_nutrient_position() -> Vector3:
    var center: Vector3 = player.position if is_instance_valid(player) else Vector3.ZERO
    if is_instance_valid(habitats) and center.length()<34 and rng.randf()<.55:
        return habitats.food_position()
    var angle: float = rng.randf()*TAU
    var distance: float = rng.randf_range(5.0,20.0)
    return Vector3(clampf(center.x+cos(angle)*distance,-world_radius+1,world_radius-1),
        .29,clampf(center.z+sin(angle)*distance,-world_radius+1,world_radius-1))

func _recycle_distant_nutrients() -> void:
    if not is_instance_valid(player):
        return
    # Preserve biological remains and resources close to autonomous cells.
    for nutrient in nutrients:
        if events.carried(int(nutrient.get("uid",-1))): continue
        if str(nutrient["kind"]) == "detritus" or not is_instance_valid(nutrient["node"]):
            continue
        var node: Node3D = nutrient["node"]
        if node.position.distance_squared_to(player.position)<1600.0:
            continue
        var occupied: bool = false
        for entity in entities.values():
            if is_instance_valid(entity["node"]) and entity["node"].position.distance_squared_to(node.position)<36.0:
                occupied = true
                break
        if not occupied:
            node.position = _nearby_nutrient_position()
            nutrient["origin_y"] = .29

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
        points.append({"pos":screen,"kind":str(n["kind"]),"scale":1.155})
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
        var npc_growth: float = Physiology.growth_scale(float(entity.get("biomass",24.0)),24.0,float(NEED["biomass"]))/.72
        silhouettes.append({"pos":point, "radius":38.0*ui*npc_growth,
            "traits":entity["traits"],"branch":str(entity["branch"]),
            "seed":str(id).hash()%88,"selected":false})
    if is_instance_valid(player) and entities.has(player_id):
        var center: Vector3 = player.position+Vector3(0,.81,0)
        if not camera.is_position_behind(center):
            var controlled_growth: float = Physiology.growth_scale(float(resources["biomass"]),23.0,float(NEED["biomass"]))/.72
            silhouettes.append({"pos":camera.unproject_position(center),
                "radius":65.0*ui*controlled_growth,
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
        if id == player_id or not entities.has(id) or float(entities[id].get("hp",0))<=0.0:
            continue
        var e: Dictionary = entities[id]
        var c: CellVisual = e["node"]
        if not is_instance_valid(c):
            continue
        var current: Vector3 = e.get("velocity",Vector3.ZERO)
        var desired: Vector3 = e.get("intent_velocity",Vector3.ZERO)
        if float(e.get("energy",0.0)) <= 0.0 or events.dormant(str(id)) or (battle.active() and battle.combat.busy(battle,str(id))):
            current = Vector3.ZERO
            desired = Vector3.ZERO
        var next: Vector3 = current.move_toward(desired,Physiology.NPC_ACCELERATION*delta)
        var before: Vector3 = c.position
        c.position += next*delta
        c.position.x = clampf(c.position.x,-world_radius+1,world_radius-1)
        c.position.z = clampf(c.position.z,-world_radius+1,world_radius-1)
        var actual_distance: float = before.distance_to(c.position)
        e["velocity"] = next
        e["energy"] = Physiology.npc_energy_step(float(e["energy"]),delta,actual_distance,events.resting_traits(str(id)))
        e["atp"] = e["energy"]
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
        if id == player_id or not entities.has(id) or float(entities[id].get("hp",0))<=0.0:
            continue
        var e: Dictionary = entities[id]
        var c: CellVisual = e["node"]
        if not is_instance_valid(c):
            continue
        if not events.dormant(str(id)):
            e["age"] = float(e["age"])+dt
            e["cycle_age"] = float(e.get("cycle_age",0))+dt
        var local_temperature: float = _temperature_at(c.position)
        var limit_temperature: float = 43.0+18.0*float(e["traits"].get("thermotolerance",0.0))
        if not battle.active() and local_temperature > limit_temperature:
            e["hp"] = float(e["hp"])-dt*(local_temperature-limit_temperature)*.075
            if float(e["hp"]) <= 0.0:
                _remove_entity(str(id),"stress termico")
                continue
        if events.dormant(str(id)):
            e["intent_velocity"] = Vector3.ZERO
            continue
        var role: String = Physiology.strategy(e["traits"])
        e["strategy"] = role
        var target_idx: int = _nearest_nutrient(c.position,7.5)
        var dir: Vector3 = Vector3(sin(t*.39+float(str(id).hash()%77)),0,
            cos(t*.31+float(str(id).hash()%63)))
        var speed: float = Physiology.strategy_speed(e["traits"],str(id)==partner_id and bool(phase2_progress.get("bonded",false)))
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
                if target_idx>=0 and float(e["energy"])<18.0 and nutrients[target_idx]["node"].position.distance_to(player.position)<2.8:
                    dir = nutrients[target_idx]["node"].position-c.position
        else:
            var closest_threat: String = ""
            var threat_distance: float = 4.6
            var closest_prey: String = ""
            var prey_distance: float = 4.1
            for other_id in entities:
                if other_id == id or (battle.active() and battle.friendly(str(id),str(other_id))) or (str(id)==partner_id and str(other_id)==player_id):
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
        if not battle.active():
            dir = events.npc_target(str(id),dir)
            speed *= collectives.speed(str(id))
        if battle.active():
            dir = battle.npc_goal(str(id),dir)
            speed = Physiology.player_speed(e.traits)*.85
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
        if can_replicate and not battle.active():
            _divide_npc(str(id))
            continue
        if battle.active():
            if int(e.traits.get("arena_profile",-1))==0:
                for other in entities:
                    if not battle.friendly(str(id),str(other)) and c.position.distance_to(entities[other].node.position)<1.6:
                        battle.combat.request(battle,str(id),str(other))
                        break
            continue
        # Real ecological competition among predators and prey.
        if int(e["generation"]) >= 3 and role == "predatore" and float(e["energy"]) > 8.0:
            var nearest_id: String = ""
            var best: float = 1.12
            for other_id in entities:
                if other_id == id or (battle.active() and battle.friendly(str(id),str(other_id))) or (str(id)==partner_id and str(other_id)==player_id):
                    continue
                var other: Dictionary = entities[other_id]
                var dist: float = c.position.distance_to(other["node"].position)
                if dist < best:
                    nearest_id = str(other_id)
                    best = dist
            if nearest_id != "":
                if nearest_id == player_id:
                    var was_alive: bool = hp>0.0
                    var before_hp: float = hp
                    hp = maxf(0.0,hp-dt*5.0/maxf(.5,float(entities[player_id]["traits"].get("defense",1.0)))/maxf(.65,float(entities[player_id]["traits"].get("vitality",1.0))))
                    if battle.active(): battle.record_hit(player_id,str(id),before_hp-hp)
                    if was_alive and hp<=0.0:
                        _award_bundle(Balance.KILL_REWARD,false,str(id))
                else:
                    var prey: Dictionary = entities[nearest_id]
                    var dealt: float = dt*5.0/maxf(.5,float(prey["traits"].get("defense",1.0)))
                    if battle.active(): battle.record_hit(nearest_id,str(id),minf(float(prey["hp"]),dealt))
                    prey["hp"] = float(prey["hp"])-dealt
                    if float(prey["hp"]) <= 0:
                        _remove_entity(nearest_id,"predazione")
                        _award_bundle(Balance.KILL_REWARD,false,str(id))
    # The Phase 2 bacterial partner arises from an independent lineage.
    if not battle.active() and generation >= 3 and entities[player_id]["branch"] == "archaea" and _compatible_partner(24.0)=="" and entities.size()<npc_population_cap and t-last_external_arrival >= 20.0:
        last_external_arrival = t

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
    _create_entity(new_id,"",0,"bacteria",traits,_world_position(player.position+Vector3(rng.randf_range(2.5,3.3),0,rng.randf_range(-1.4,1.4))),false,true)

func _divide_npc(id: String) -> void:
    if not entities.has(id):
        return
    var parent: Dictionary = entities[id]
    var pos: Vector3 = parent["node"].position
    var gen: int = int(parent["generation"])+1
    var branch: String = str(parent["branch"])
    var traits: Dictionary = parent["traits"]
    var external: bool = bool(parent["external"])
    var parent_ecotype: String = str(parent.get("ecotype",id))
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
        # Independent lineages can diversify without the player controlling
        # them. Bacteria and Archaea arise as sisters from a shared stage,
        # never one after the other.
        var daughter_branch: String = branch
        if branch == "pre_luca" and gen >= 2 and rng.randf() < .38:
            daughter_branch = "luca"
        elif branch == "luca" and gen >= 3 and rng.randf() < .46:
            daughter_branch = "bacteria" if i == 0 else "archaea"
        if not external: daughter_branch = branch
        var mutated: Dictionary = _mutated_traits(traits,gen,daughter_branch) if external else traits.duplicate(true)
        if daughter_branch == "luca" and branch == "pre_luca":
            mutated = GenomeScript.grant(mutated,"dna_stabilization",gen,"ramificazione_autonoma","luca")
        elif daughter_branch != branch and branch == "luca":
            var envelope_gene: String = "monoderm_envelope" if daughter_branch == "bacteria" else "archaeal_envelope"
            mutated = GenomeScript.grant(mutated,envelope_gene,gen,"ramificazione_autonoma",daughter_branch)
        # Occasional heritable ecological specialization. Runner: fast escape,
        # predator: hydrolase and high attack but significantly slower.
        if external and gen >= 3 and rng.randf() < .52:
            if i == 0:
                mutated = GenomeScript.grant(mutated,"pili_twitch",gen,"specializzazione",daughter_branch)
                mutated["motility"] = maxf(1.20,float(mutated.get("motility",1.0)))
            else:
                mutated = GenomeScript.grant(mutated,"hydrolase_secretion",gen,"specializzazione",daughter_branch)
                mutated["attack"] = maxf(1.16,float(mutated.get("attack",1.0)))
                mutated["motility"] = minf(.83,float(mutated.get("motility",1.0)))
            mutated = GenomeScript.express(mutated,daughter_branch)
        mutated = events.variation(parent,mutated,pos,gen,i)
        var local_variant: bool = GenomeScript.has(mutated,"hydrolase_secretion") and not GenomeScript.has(traits,"hydrolase_secretion")
        _create_entity(new_id,id,gen,daughter_branch,mutated,pos+Vector3(-.70 if i == 0 else .70,0,.45 if i == 0 else -.45),false,external)
        var child: Dictionary = entities[new_id]
        Ecology.register_death(ecology,str(child["ecotype"]),child["node"].position)
        child["ecotype"] = new_id if local_variant else parent_ecotype
        Ecology.register_birth(ecology,str(child["ecotype"]),child["node"].position)
        child["evolution"] = parent.get("evolution",Evolution.origin()).duplicate(true)
        child["biomass"] = 24.0
        child["energy"] = float(parent["energy"])*.45
        child["atp"] = child["energy"]
        var sibling_stock: Dictionary = parent["resources"].duplicate(true)
        for ingredient in TYPES:
            sibling_stock[ingredient] = float(parent["resources"].get(ingredient,0.0))*.44
        sibling_stock["biomass"] = 24.0
        child["resources"] = sibling_stock
        child["strategy"] = Physiology.strategy(mutated)
        child["hp"] = maxf(35.0,float(parent["hp"])*.8)
        child["purchased"] = older_purchased.duplicate(true)
        child["points"] = float(parent["points"])
        child["phase2_progress"] = inherited_phase.duplicate(true)
        if i == 0:
            first_id = new_id
    var children: Array=[]
    for child_id in entities:
        if entities[child_id].parent==id: children.append(child_id)
    collectives.division(id,children)
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
        traits = Balance.shift(traits,key,float(mutation[2])*.35)
        traits = Balance.shift(traits,side,float(mutation[4])*.35)
        traits["point_mutation_progress"] = int(traits.get("point_mutation_progress",0))+1
        var history: Array = traits.get("mutations",[]).duplicate()
        history.append(str(mutation[0]))
        traits["mutations"] = history
    # Mutazioni maggiori: nuovi loci ereditabili, che sono anche la sorgente dei moduli fisici.
    if child_generation >= 2 and int(traits.get("point_mutation_progress",0))>=5:
        var options: Array[String] = GenomeScript.random_candidates(branch,traits)
        if not options.is_empty():
            var locus: String = options[rng.randi_range(0,options.size()-1)]
            traits = GenomeScript.grant(traits,locus,child_generation,"major_mutation",branch)
            traits["point_mutation_progress"] = int(traits["point_mutation_progress"])-5
    return GenomeScript.express(traits,branch)

func _can_divide() -> bool:
    if events.dormant(player_id): return false
    if hp<=0.0 or division_active or cycle_age < (35.0 if generation == 0 else 75.0):
        return false
    for key in NEED:
        if float(resources[key]) < float(NEED[key]) - 0.001:
            return false
    return atp >= 30.0

func _divide_pressed() -> void:
    if division_active or hp<=0.0:
        return
    var reason: String = _division_block_reason()
    if reason != "":
        _notice(reason)
        return
    _close_overlay()
    _cache_current()
    division_options.clear()
    var parent: Dictionary = entities[player_id]
    for i in range(2):
        division_options.append({"traits":parent["traits"].duplicate(true),"branch":parent["branch"],"name":"Genoma ereditato"})
    division_active = true
    is_paused = true
    move_vector = Vector2.ZERO
    var tween: Tween = create_tween()
    tween.tween_method(func(value: float):
        if is_instance_valid(player):
            player.set_division_progress(value),0.0,1.0,2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_callback(func():
        division_active = false
        _choose_daughter(0))

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
    if bool(phase1_progress.get("complete",false)):
        _advance_phase_two(0.0)
    var parent_phase: Dictionary = PhaseScript.normalize(phase2_progress)
    var old_resources: Dictionary = resources.duplicate(true)
    var old_hp: float = hp
    var old_atp: float = atp
    var old_points: float = mutation_points
    var credit: float = 2.0*Balance.points_multiplier(parent["traits"])
    var next_evolution: Dictionary = Evolution.on_division(evolution,_evolution_context())
    var old_ecotype: String = str(parent.get("ecotype",old_id))
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
        new_cell["hp"] = old_hp # health is a fraction of each daughter, not an automatic injury
        new_cell["energy"] = old_atp*.55
        new_cell["points"] = old_points+credit
        new_cell["evolution"] = next_evolution.duplicate(true)
        new_cell["cycle_age"] = 0.0
        Ecology.register_death(ecology,str(new_cell["ecotype"]),new_cell["node"].position)
        new_cell["ecotype"] = old_ecotype
        Ecology.register_birth(ecology,old_ecotype,new_cell["node"].position)
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
    var daughters: Array = []
    for child_id in entities:
        if entities[child_id].parent==old_id: daughters.append(child_id)
    campaign.after_division(old_id,daughters)
    collectives.division(old_id,daughters)
    division_options.clear()
    statistics.divisions += 1
    phase1_progress["player_divisions"] = int(phase1_progress.get("player_divisions",0))+1
    _activate_lineage(chosen_id)
    if battle.active(): battle.inherit_score(old_id,chosen_id)
    _close_overlay()
    journey.after_division()
    _save_game()
    _notice("Scissione completata · %s · +%.2f PM" % [chosen_id,credit])

func _on_regen() -> void:
    if hp<=0.0:
        return
    if atp <= 0.0:
        _notice("ATP esaurito: non puoi rigenerare finché non assorbi nutrienti")
        return
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
    if mode == "enzyme" and journey.enzyme_action(): return
    cooperation_target = ""
    if atp <= 0.0:
        _notice("ATP esaurito: nessuna capacità attivabile")
        return
    if skill_cooldown > 0.0:
        _notice("Abilita' in ricarica")
        return
    var genome_traits: Dictionary = entities[player_id]["traits"]
    if not GenomeScript.has(genome_traits,"hydrolase_secretion"):
        if generation>=1:
            _on_tree()
            tree_view.focus_node(88)
        else:
            _notice("Enzimi acquistabili dopo la prima divisione: 2 punti")
        return
    if mode == "lysis" and not GenomeScript.has(genome_traits,"surface_recognition"):
        _notice("La lisi selettiva richiede anche recettori di riconoscimento")
        return
    selected_substrate = null
    if mode=="enzyme":
        for patch in substrates:
            if is_instance_valid(patch) and Vector2(patch.position.x-player.position.x,patch.position.z-player.position.z).length()<10.0:
                if selected_substrate==null or Vector2(patch.position.x-player.position.x,patch.position.z-player.position.z).length()<Vector2(selected_substrate.position.x-player.position.x,selected_substrate.position.z-player.position.z).length():
                    selected_substrate = patch
        if selected_substrate!=null:
            selected_target_id = ""
            selected_nutrient = null
            attack_mode = mode
            _notice("Digestione del substrato: 6 ATP per porzione")
            return
    var attack_strength: float = float(genome_traits.get("attack",1.0))
    var best: String = ""
    var dist: float = 8.0
    if mode == "lysis" or attack_strength >= 1.10:
        for id in entities:
            if id == player_id or str(id)==partner_id:
                continue
            var d: float = player.position.distance_to(entities[id]["node"].position)
            if d < dist:
                dist = d
                best = str(id)
    selected_target_id = best
    selected_nutrient = null
    attack_mode = mode
    if best == "":
        attack_mode = ""
        _notice("Nessun bersaglio nella portata di ricerca")
        return
    _notice("Bersaglio: %s · %s" % [best,mode.to_upper()])

func _follow_attack(delta: float) -> void:
    if events.dormant(player_id): return
    if is_instance_valid(selected_substrate):
        var offset: Vector3 = selected_substrate.position-player.position
        offset.y = 0
        if offset.length()>1.55:
            _move_player(Vector2(offset.x,offset.z).normalized(),delta)
        else:
            _digest_substrate(selected_substrate)
        return
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
    if battle.active() and battle.friendly(player_id,selected_target_id):
        selected_target_id = ""
        _notice("Cellula alleata: sciogli prima il patto")
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
    if battle.active():
        battle.combat.request(battle,player_id,selected_target_id)
        return
    if skill_cooldown > 0:
        return
    var cost: float = Balance.LYSIS_COST if attack_mode == "lysis" else Balance.ENZYME_COST
    if atp < cost:
        selected_target_id = ""
        attack_mode = ""
        _notice("ATP insufficiente")
        return
    atp -= cost
    skill_cooldown = 2.3 if attack_mode == "lysis" else 2.7
    var power: float = 36.0 if attack_mode == "lysis" else 20.0
    var defense: float = maxf(.4,float(target["traits"].get("defense",1.0)))
    var damage: float = power*float(entities[player_id]["traits"].get("attack",1.0))/defense/maxf(.65,float(target["traits"].get("vitality",1.0)))
    if battle.active(): battle.record_hit(selected_target_id,player_id,minf(float(target["hp"]),damage))
    target["hp"] = float(target["hp"])-damage
    if float(target["hp"]) <= 0:
        var prey_id: String = selected_target_id
        _remove_entity(prey_id,"predazione")
        _award_bundle(Balance.KILL_REWARD,true)
        statistics.kills += 1
        selected_target_id = ""
        attack_mode = ""
        _notice("Predazione completata · detriti rilasciati")
    else:
        _notice("Danno %.0f · HP preda %.0f" % [damage,maxf(0.0,float(target["hp"]))])

func _on_cooperate() -> void:
    if battle.active():
        battle.cooperate()
        return
    if atp <= 0.0:
        _notice("ATP esaurito: non puoi instaurare un nuovo legame")
        return
    if not entities.has(player_id) or entities[player_id]["branch"] != "archaea":
        _notice("La cooperazione richiede una linea archeale ospite")
        return
    if partner_id != "" and entities.has(partner_id) and bool(phase2_progress.get("bonded",false)):
        _on_phase_two()
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
        if not PhaseScript.can_adhere(traits,bacterial) or int(bacterial.get("transporters",0))<=0:
            continue
        var d: float = entities[id]["node"].position.distance_to(player.position)
        if d < distance:
            closest = str(id)
            distance = d
    if closest == "":
        _seek_partner()
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
    journey.explain()
    _open_overlay("SPECIALIZZAZIONI", "Bonus e costi · punti guadagnati per scissione")
    overlay_scroll.visible = false
    tree_view = TreeScript.new()
    tree_view.configure(purchased, int(floor(mutation_points)), entities[player_id]["traits"],generation)
    tree_view.mutation_unlocked.connect(_on_tree_mutation)
    overlay.add_child(tree_view)
    _layout_ui()
    var scale_factor: float = clampf(overlay.size.x/720.0,.62,1.65) if overlay.size.y > overlay.size.x else 1.0
    var right: float = overlay.size.x-81.0*scale_factor
    var capacities := Button.new()
    capacities.text = "CAPACITÀ → LECA"
    capacities.position = Vector2(470,140)*scale_factor
    capacities.size = Vector2(205,44)*scale_factor
    capacities.pressed.connect(_on_evolution)
    overlay.add_child(capacities)
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

func _on_tree_mutation(id: int,stat: String,_value: float,cost: int) -> void:
    if purchased.has(str(id)) or mutation_points < cost or not entities.has(player_id):
        return
    var validator := TreeScript.new()
    validator.configure(purchased,int(floor(mutation_points)),entities[player_id]["traits"],generation)
    var valid: bool = validator._available(id) and cost==validator._cost(id) and stat==validator.STATS[id/48]
    validator.free()
    if not valid:
        return
    var traits: Dictionary = entities[player_id]["traits"]
    var before_traits: Dictionary = traits.duplicate(true)
    var branch: String = str(entities[player_id]["branch"])
    if id % 48 >= 40:
        var locus: String = tree_view.major_locus(id)
        if GenomeScript.allele(traits,locus) < int(GenomeScript.GENE_INFO[locus]["max"]):
            traits = GenomeScript.grant(traits,locus,generation,"albero_gene_maggiore",branch)
    purchased[str(id)] = true
    mutation_points -= cost
    # All nodes retain the quantified bonus. Major icons ALSO have a real
    # heritable gene with a visible phenotypic module when applicable.
    traits = Balance.tree_effect(traits,stat,id%48>=40)
    traits = GenomeScript.express(traits,branch)
    entities[player_id]["traits"] = traits
    for record in genealogy:
        if str(record.get("id","")) == player_id:
            record["traits"] = traits.duplicate(true)
            break
    if id % 48 >= 40:
        var old_position: Vector3 = player.position
        var old_rotation: Vector3 = player.rotation
        player.setup(traits,branch,true)
        player.position = old_position
        player.rotation = old_rotation
        player.set_growth(Physiology.growth_scale(float(resources["biomass"]),23.0,
            float(NEED["biomass"])))
    _differentiate_lineage()
    _cache_current()
    tree_view.configure(purchased,int(floor(mutation_points)),traits,generation)
    if id == 88: journey.purchased_enzyme(before_traits)
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
    _add_overlay_label("I nodi piccoli danno bonus numerici; i grandi contengono loci maggiori con conseguenze fenotipiche.")
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
    if battle.active():
        _notice("Battle Royale: controlli solo la tua cellula")
        return
    id = campaign.follow(id)
    if id == player_id or not entities.has(id) or float(entities[id].get("hp",0))<=0.0:
        _notice("Linea non viva oppure gia' controllata")
        return
    _cache_current()
    if hp<=0.0:
        _remove_entity(player_id,"morte")
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
    _add_overlay_button("Statistiche e popolazioni",_on_statistics)
    _add_overlay_button("Battle Royale",battle.choose)
    if battle.active():
        _add_overlay_button("Torna alla campagna",_load_game.bind(SAVE_PATH))
    if not battle.active():
        _add_overlay_button("Mappa e primo insediamento",campaign.open_map)
        _add_overlay_button("Dormienza / risveglio · minimo 12 s",events.toggle_rest)
        _add_overlay_button("Frammenta filamento",collectives.fragment)
    _add_overlay_button("Obiettivi",_on_goals)
    _add_overlay_button("Consorzi metabolici",_on_phase_two)
    _add_overlay_button("Capacità evolutive",_on_evolution)
    _add_overlay_button("Come giocare",_on_guide)
    if journey.active(): _add_overlay_button("Salta guida iniziale",journey.skip)
    _add_overlay_button("Salva partita",_save_game)
    _add_overlay_button("Carica partita",_load_game.bind(battle.PATH if battle.active() else SAVE_PATH))
    if FileAccess.file_exists(PHASE_TWO_CHECKPOINT):
        _add_overlay_button("Carica archivio storico",_load_game.bind(PHASE_TWO_CHECKPOINT))

func _on_guide() -> void:
    _open_phase_intro(1)

func _on_goals() -> void:
    if battle.active():
        battle.dashboard()
        return
    if not entities.has(player_id):
        return
    _open_overlay("NICCHIE E LINEA EVOLUTIVA", "25 nicchie · 5,29 km² cartografici · densità, coesistenza e dominanza")
    _add_overlay_label("Le cellule visibili fondano popolazioni. Le coorti fuori campo si riproducono, competono e migrano secondo habitat e capacità portante.")
    var lineage: String = str(entities[player_id].get("ecotype",player_id))
    var local: Dictionary = Ecology.summary(ecology,lineage,player.position)
    _add_overlay_label("Nicchia %s · %s" % [Ecology.niche_id(player.position),str(local.get("habitat",""))])
    _add_overlay_label("Densità %.1f cellule/km² · %s" % [float(local.get("density",0.0)),_niche_label(str(local.get("status","")))])
    var occupied: int = 0
    for z in range(5):
        for x in range(5):
            var pos := Vector3(-920+x*460,0,-920+z*460)
            var info: Dictionary = Ecology.summary(ecology,lineage,pos)
            if bool(info.get("dominant",false)) or bool(info.get("coexistence",false)):
                occupied += 1
            _add_overlay_label("%d:%d · %.1f cell/km² · %s" % [x,z,float(info.get("density",0)),_niche_label(str(info.get("status","")))])
    _add_overlay_label("Nicchie consolidate: %d/25 · Divisioni della linea: %d · PM %.2f" % [occupied,int(evolution.get("divisions",0)),mutation_points])
    _add_overlay_button("FONDA LA TUA PRIMA POPOLAZIONE · MAPPA",campaign.open_map)
    _add_overlay_button("STATISTICHE · RNA, DNA E POPOLAZIONI",_on_statistics)
    _add_overlay_button("CAPACITÀ EVOLUTIVE",_on_evolution)
    _add_overlay_button("ALBERO DELLE SPECIALIZZAZIONI",_on_tree)

func _world_position(at: Vector3) -> Vector3:
    return Vector3(clampf(at.x,-world_radius,world_radius),at.y,clampf(at.z,-world_radius,world_radius))

func _compatible_partner(radius: float = INF) -> String:
    var best: String = ""
    for id in entities:
        var e: Dictionary = entities[id]
        if str(id)==player_id or str(e["branch"])!="bacteria" or float(e["hp"])<=0:
            continue
        if not bool(e["traits"].get("adhesion",false)) or int(e["traits"].get("transporters",0))<=0:
            continue
        var distance: float = player.position.distance_to(e["node"].position)
        if distance<radius:
            best = str(id)
            radius = distance
    return best

func _seek_partner() -> void:
    if str(entities[player_id]["branch"])!="archaea":
        return
    cooperation_target = _compatible_partner(24.0)
    if cooperation_target=="": cooperation_target = collectives.nearest_donor()
    if cooperation_target=="":
        _notice("Popolazione locale assente: cerca altre linee batteriche sulla mappa")
        _close_overlay()
        return
    selected_target_id = ""
    selected_nutrient = null
    selected_substrate = null
    _close_overlay()
    _notice("Avvicinamento al partner · il joystick annulla la ricerca")

func _approach_partner(delta: float) -> void:
    if not entities.has(cooperation_target):
        cooperation_target = ""
        return
    var offset: Vector3 = entities[cooperation_target]["node"].position-player.position
    if offset.length()>2.8:
        _move_player(Vector2(offset.x,offset.z).normalized(),delta)
    else:
        cooperation_target = ""
        _on_cooperate()

func _release_partner() -> void:
    phase2_progress = PhaseScript.release(phase2_progress)
    partner_id = ""
    cooperation_target = ""
    exchange_active = false
    phase_two = 0.0
    _cache_current()
    _on_phase_two()

func _toggle_exchange() -> void:
    phase2_progress["exchange_enabled"] = not bool(phase2_progress.get("exchange_enabled",true))
    exchange_active = false
    _cache_current()
    _close_overlay()
    _notice("Scambio ripreso" if bool(phase2_progress["exchange_enabled"]) else "Scambio sospeso: raccogli le risorse per dividerti")

func _follow_archaeal_lineage() -> void:
    for id in entities:
        if str(entities[id]["branch"])=="archaea" and float(entities[id]["hp"])>0:
            _switch_lineage(str(id))
            return
    # An independent immigrant: never convert a bacterium into an archaeon.
    if entities.size()>=npc_population_cap:
        _notice("Popolazione al limite: consulta LINEE o attendi un posto nella nicchia")
        return
    var traits: Dictionary = _base_traits()
    traits = GenomeScript.grant(traits,"dna_stabilization",3,"linea_indipendente","archaea")
    traits = GenomeScript.grant(traits,"archaeal_envelope",3,"linea_indipendente","archaea")
    var id: String = "E-%03d" % next_id
    next_id += 1
    _create_entity(id,"",3,"archaea",traits,_world_position(player.position+Vector3(5,0,0)),false,true)
    _switch_lineage(id)

func _on_phase_two() -> void:
    if not entities.has(player_id):
        return
    var traits: Dictionary = entities[player_id]["traits"]
    _open_overlay("CONSORZIO ESTERNO", "Riconoscimento → adesione → scambio → stabilita → trasmissione")
    for line in PhaseScript.objective_lines(phase2_progress):
        _add_overlay_label(line)
    if str(entities[player_id]["branch"])!="archaea":
        _add_overlay_label("Segui una linea Archaea per questa missione. La tua cellula attuale rimane nell'oceano.")
        _add_overlay_button("SEGUI UNA LINEA ARCHEALE",_follow_archaeal_lineage)
        _add_overlay_label("Se non ne sopravvive una, incontrerai una linea indipendente: nessuna Bacteria viene trasformata.")
        return
    var anchor: bool = bool(traits.get("adhesion",false)) or bool(traits.get("eps",false))
    var transport: bool = int(traits.get("transporters",0))>0
    _add_overlay_label(("✓" if anchor else "○")+" Recettori/EPS · "+("✓" if transport else "○")+" Trasportatori")
    if not anchor or not transport:
        _add_overlay_label("Acquisisci recettori e trasportatori nell’albero delle mutazioni.")
        _add_overlay_button("APRI EVOLUZIONE",_on_tree)
    if partner_id!="" and entities.has(partner_id):
        var e: Dictionary = entities[partner_id]
        _add_overlay_label("PARTNER %s · energia %.0f/85 · distanza %.1f/3,7" % [partner_id,float(e["energy"]),player.position.distance_to(e["node"].position)])
        _add_overlay_label("Scambio %.1f/12 s · contatto %.1f/25 s" % [minf(12,float(phase2_progress["exchange_seconds"])),minf(25,float(phase2_progress["contact_seconds"]))])
        _add_overlay_label("Costo: 0,10 C/s. Il partner fornisce metaboliti energetici. Sospendi lo scambio per conservare il carbonio prima della scissione.")
        if float(e["energy"])<4.0:
            _add_overlay_label("Partner esausto: raggiungete nutrienti o scegli un altro partner.")
        _add_overlay_button("SOSPENDI SCAMBIO" if bool(phase2_progress.get("exchange_enabled",true)) else "RIPRENDI SCAMBIO",_toggle_exchange)
        _add_overlay_button("SEPARA IL CONSORZIO",_release_partner)
        if bool(phase2_progress.get("active_stable",false)):
            _add_overlay_label("Consorzio pronto: raccogli C24, AA15, L12, N8, biomassa65 e ATP30, poi DIVIDI.")
            if _can_divide():
                _add_overlay_button("DIVIDI E TRASMETTI",_divide_pressed)
    elif anchor:
        _add_overlay_button("CERCA PARTNER COMPATIBILE",_seek_partner)
    _add_overlay_button("TORNA ALL'OCEANO",_close_overlay)
    _add_overlay_label("Il consorzio resta esterno. Internalizzazione e mitocondrio richiedono capacità separate nell’albero.")

func _game_over() -> void:
    if battle.active():
        battle.player_death()
        return
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
    _add_overlay_button("SEGUI UNA LINEA SOPRAVVISSUTA",_on_genealogy)
    _add_overlay_button("NUOVA PARTITA",_new_game)
    _add_overlay_button("RICARICA SALVATAGGIO",_load_game)

func _on_joystick_changed(v: Vector2) -> void:
    move_vector = v
    if v.length() > .14:
        selected_target_id = ""
        selected_nutrient = null
        attack_mode = ""

func _save_game(path: String = SAVE_PATH) -> void:
    if battle.active() and path==SAVE_PATH: path = battle.PATH
    if division_active:
        return
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
            "evolution":e.get("evolution",{}),"ecotype":e.get("ecotype",id),"cycle_age":e.get("cycle_age",0.0),
            "sister_ids":e.get("sister_ids",[]),"rest":e.get("rest",{}),
            "phase2_progress":e.get("phase2_progress",PhaseScript.empty()),
            "zero_atp_seconds":e.get("zero_atp_seconds",0.0),
            "zero_energy_seconds":e.get("zero_energy_seconds",0.0)})
    var particle_data: Array = []
    for n in nutrients:
        if is_instance_valid(n["node"]):
            var position: Vector3 = n["node"].position
            particle_data.append({"uid":n.get("uid",0),"kind":n["kind"],"pos":[position.x,position.y,position.z]})
    var substrate_data: Array = []
    for patch in substrates:
        if is_instance_valid(patch):
            substrate_data.append({"pos":[patch.position.x,patch.position.y,patch.position.z],"portions":patch.portions,"kind":patch.kind})
    var data: Dictionary = {"substrates":substrate_data,"substrate_respawn":substrate_respawn,"version":80,"elapsed":t,"player_id":player_id,"next_id":next_id,
        "entities":cells,"genealogy":genealogy,"nutrients":particle_data,
        "partner":partner_id,"phase_two":phase_two,"phase2_progress":phase2_progress,
        "phase1_progress":phase1_progress,"zero_atp_seconds":zero_atp_seconds,
        "last_external_arrival":last_external_arrival,"world_age":world_age,
        "ecology":ecology,"ecological_profiles":ecological_profiles,"statistics":statistics,"battle":battle.state,"journey":journey.state,"campaign_world":campaign.state,"campaign_events":events.state,"next_particle_uid":next_particle_uid,"collectives":collectives.state}
    var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()

func _valid_save(data: Dictionary) -> bool:
    if data.has("battle") and not battle.rules.valid(data.battle): return false
    for key in ["ecology","ecological_profiles","statistics"]:
        if data.has(key) and not data[key] is Dictionary:
            return false
    for key in ["entities","genealogy","nutrients","substrates"]:
        if data.has(key) and not data[key] is Array:
            return false
    for key in ["phase1_progress","phase2_progress"]:
        if data.has(key) and not data[key] is Dictionary:
            return false
    var seen: Dictionary = {}
    for record in data.get("entities",[]):
        if not record is Dictionary:
            return false
        var id: String = str(record.get("id",""))
        if id=="" or seen.has(id):
            return false
        seen[id] = true
        var pos = record.get("pos",null)
        if not pos is Array or pos.size()!=3:
            return false
        for number in pos:
            if not (number is float or number is int) or not is_finite(float(number)):
                return false
        for key in ["traits","resources","purchased","phase2_progress","evolution"]:
            if record.has(key) and not record[key] is Dictionary:
                return false
        for key in ["generation","hp","atp","energy","biomass","points","age"]:
            if record.has(key) and (not (record[key] is float or record[key] is int) or not is_finite(float(record[key]))):
                return false
        for value in record.get("resources",{}).values():
            if not (value is float or value is int) or not is_finite(float(value)):
                return false
    return seen.has(str(data.get("player_id","")))

func _load_game(path: String = SAVE_PATH) -> void:
    if not FileAccess.file_exists(path):
        _notice("Non esiste ancora una partita salvata")
        return
    var file: FileAccess = FileAccess.open(path,FileAccess.READ)
    if file == null:
        _notice("Impossibile leggere il salvataggio")
        return
    var loaded: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (loaded is Dictionary) or not [67,70,71,80].has(int(loaded.get("version",0))):
        _notice("Salvataggio incompatibile: supportate versioni 0.67–0.80")
        return
    if division_active:
        _notice("Attendi il completamento della scissione")
        return
    if not _valid_save(loaded):
        _notice("Salvataggio non valido: la partita attuale e stata conservata")
        return
    var loading_battle: bool = bool(loaded.get("battle",{}).get("enabled",false))
    if loading_battle != battle.active(): _save_game()
    battle.reset()
    battle.state = loaded.get("battle",{}).duplicate(true)
    world_radius = 40.0 if battle.active() else preload("res://src/seabed_palette.gd").WORLD_RADIUS
    var cell_list: Array = loaded["entities"]
    var controlled: String = str(loaded["player_id"])
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
    ecology_syncing = true
    var saved_history: Array = loaded.get("genealogy",[])
    for record in cell_list:
        var xyz: Array = record.get("pos",[0,0,0])
        if xyz.size() != 3:
            continue
        var id: String = str(record["id"])
        _create_entity(id,str(record.get("parent","")),int(record.get("generation",0)),str(record.get("branch","pre_luca")),record.get("traits",_base_traits()),Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2])),false,bool(record.get("external",false)))
        var target: Dictionary = entities[id]
        for key in ["hp","atp","energy","biomass","resources","points","purchased","age","phase2_progress","zero_atp_seconds","zero_energy_seconds","evolution","ecotype","cycle_age","sister_ids","rest"]:
            if record.has(key):
                target[key] = record[key]
        target["phase2_progress"] = PhaseScript.normalize(target.get("phase2_progress",{}))
        if not record.has("evolution"):
            target["evolution"] = _legacy_evolution(target)
    ecology_syncing = false
    ecology = Ecology.normalize(loaded.get("ecology",{}))
    ecological_profiles = loaded.get("ecological_profiles",{}).duplicate(true)
    for id in entities:
        var e: Dictionary = entities[id]
        var lineage: String = str(e.get("ecotype",id))
        ecological_profiles[lineage] = e["traits"].duplicate(true)
        if not loaded.has("ecology"):
            Ecology.register_birth(ecology,lineage,e["node"].position)
    if int(loaded.get("ecology",{}).get("version",1))<2 and loaded.has("ecology"):
        for e in entities.values():
            var old_key: String = Ecology.grid_id(e.node.position)
            var new_key: String = Ecology.niche_id(e.node.position)
            var pops: Dictionary = ecology.niches[old_key].populations
            if old_key!=new_key and int(pops.get(e.ecotype,0))>0:
                pops[e.ecotype]=int(pops[e.ecotype])-1
                if int(pops[e.ecotype])==0: pops.erase(e.ecotype)
                Ecology.register_birth(ecology,e.ecotype,e.node.position)
    genealogy = saved_history
    for p in loaded.get("nutrients",[]):
        if not(p is Dictionary) or not (TYPES.has(str(p.get("kind",""))) or str(p.get("kind",""))=="detritus"):
            continue
        var pos: Array = p.get("pos",[0,.29,0])
        if pos.size() == 3:
            _create_nutrient(str(p["kind"]),Vector3(float(pos[0]),float(pos[1]),float(pos[2])))
            if p.has("uid"): nutrients[-1]["uid"] = int(p.uid)
    _activate_lineage(controlled)
    _reset_substrates(loaded.get("substrates",[]),loaded.has("substrates"))
    substrate_respawn = clampf(float(loaded.get("substrate_respawn",0)),0,20)
    t = maxf(0.0,float(loaded.get("elapsed",0.0)))
    statistics = Statistics.normalize(loaded.get("statistics",{}),t)
    next_id = maxi(1,int(loaded.get("next_id",1)))
    for rec in genealogy+cell_list:
        if rec is Dictionary:
            next_id = maxi(next_id,str(rec.get("id","")).get_slice("-",1).to_int()+1)
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
        # Legacy 0.70 saves already engaged in Phase 2 must not lose
        # their accumulated biological association during migration.
        var existing_phase_two: bool = false
        for milestone in ["discovered","adhesion","exchanged","stable","transmitted","complete"]:
            if bool(phase2_progress.get(milestone,false)):
                existing_phase_two = true
        if existing_phase_two:
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
    campaign.restore(loaded.get("campaign_world",{}))
    next_particle_uid = maxi(next_particle_uid,int(loaded.get("next_particle_uid",1)))
    events.restore(loaded.get("campaign_events",{}))
    collectives.restore(loaded.get("collectives",{"seeded":true}))
    journey.restore(loaded.get("journey",null))
    habitats.rebuild(not battle.active())
    _refresh_hud()
    battle.rebuild()
    if battle.active() and not str(battle.state.result).is_empty():
        battle.finish(str(battle.state.result))
        return
    if not battle.active() and bool(phase1_progress.get("complete",false)) and not FileAccess.file_exists(PHASE_TWO_CHECKPOINT):
        _save_game(PHASE_TWO_CHECKPOINT)
    _notice("Partita caricata · fasi, genoma, energia e genealogia ripristinati")

func _notice(message: String) -> void:
    if is_instance_valid(tips_label):
        tips_label.text = message
        tips_label.visible = true
        if is_instance_valid(toast_back):
            toast_back.visible = true
        tips_label.add_theme_color_override("font_color",Color(.95,.90,.71))
        notice_expires = float(Time.get_ticks_msec())/1000.0+3.5

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
    minimum = minf(minimum,cycle_age/(35.0 if generation==0 else 75.0))
    if not _can_divide():
        minimum = minf(minimum,.99)
    scission_bar.value = clampf(minimum * 100.0,0.0,100.0)
    hp_bar.value = clampf(hp,0.0,100.0)
    atp_bar.value = clampf(atp,0.0,100.0)
    scission_button.text = "SCISSIONE  ✓" if _can_divide() else "SCISSIONE · %d%%" % int(scission_bar.value)
    objective_label.text = "NICCHIE · GEN %d · %.2f PM · Ciclo %.0f/%.0f s" % [generation,mutation_points,cycle_age,35.0 if generation==0 else 75.0]
    var danger_temperature: float = 43.0+18.0*float(traits.get("thermotolerance",0.0))
    if _temperature_at(player.position) > danger_temperature:
        objective_label.text = "STRESS TERMICO · Allontanati dalla sorgente o evolvi termotolleranza"
        objective_label.add_theme_color_override("font_color",Color(.98,.71,.59))
    else:
        objective_label.add_theme_color_override("font_color",Color(.83,.95,.96))
    partner_compass_label.visible = false
    if str(entities[player_id]["branch"]) == "archaea" and not bool(phase2_progress.get("complete",false)):
        var closest_id: String = partner_id if entities.has(partner_id) else _compatible_partner()
        var nearest: float = player.position.distance_to(entities[closest_id]["node"].position) if closest_id!="" else INF
        if closest_id != "":
            var delta_partner: Vector3 = entities[closest_id]["node"].position-player.position
            var arrow: String = "→" if delta_partner.x >= 0 else "←"
            if absf(delta_partner.z) > absf(delta_partner.x):
                arrow = "↓" if delta_partner.z >= 0 else "↑"
            var ready: bool = PhaseScript.can_adhere(traits,entities[closest_id]["traits"])
            partner_compass_label.text = "BACTERIA  %s  %.1f m  ·  %s" % [arrow,nearest,"adesione compatibile" if ready else "altro fenotipo"]
            partner_compass_label.visible = true
    buttons["tree"].text = "EVOLUZIONE (%.1f)" % mutation_points
    if is_instance_valid(classic_hud):
        var chapter_title: String = "ORIGINI · EVOLUZIONE CONTINUA"
        var chapter_detail: String = "NICCHIE · SPECIALIZZAZIONE · EREDITÀ"
        var chapter_fraction: float = clampf(float(evolution.get("unlocks",{}).size())/23.0,0.0,1.0)
        var phase_label: String = "CELLULA ZERO → GRADO LECA"
        var elapsed_seconds: int = int(t)
        var simple_objective: String = objective_label.text
        if simple_objective.length() > 68:
            simple_objective = simple_objective.substr(0,65)+"..."
        if is_instance_valid(journey) and journey.active():
            simple_objective = journey.objective()
        if is_instance_valid(habitats) and not battle.active():
            chapter_detail = habitats.description(player.position)
        if battle.active():
            chapter_title = "BATTLE ROYALE · SOPRAVVIVENZA"
            chapter_detail = battle.hud_text()
            simple_objective = battle.objective_text()
            phase_label = "ARENA ECOLOGICA"
            chapter_fraction = float(battle.state.elapsed)/battle.rules.DURATION
        classic_hud.configure({
            "gen":generation,"branch":stage,"phase_title":phase_label,
            "zero_atp":zero_atp_seconds,
            "elapsed":"%02d:%02d" % [int(elapsed_seconds/60),elapsed_seconds%60],
            "temp":_temperature_at(player.position),
            "atp":atp,"hp":hp,
            "carbon":resources["carbon"],"amino":resources["amino"],
            "lipid":resources["lipid"],"nucleic":resources["nucleic"],
            "chapter":chapter_title,"chapter_detail":chapter_detail,
            "objective":simple_objective,"chapter_progress":chapter_fraction,
            "fission":clampf(scission_bar.value/100.0,0.0,1.0),
            "can_divide":_can_divide(),"division_status":_division_block_reason(),
            "requirements_1":"C %d/24    A %d/15" % [int(resources["carbon"]),int(resources["amino"])],
            "requirements_2":"L %d/12    N %d/8" % [int(resources["lipid"]),int(resources["nucleic"])],
            "requirements_3":"BIO %d/65   ATP %d/30" % [int(resources["biomass"]),int(atp)]
        })
        buttons["enzymes"].text = "✦ ENZIMI\n6 ATP · PRONTI" if GenomeScript.has(traits,"hydrolase_secretion") else ("✦ ENZIMI\nACQUISTA · 2 P" if generation>=1 else "✦ ENZIMI\nDALLA GEN 1")
        buttons["lysis"].text = "✷ LISI\n10 ATP" if GenomeScript.has(traits,"hydrolase_secretion") and GenomeScript.has(traits,"surface_recognition") else "✷ LISI\nBLOCCATA"
        buttons["cooperate"].text = ("∞ CONSORZIO\nGESTISCI" if partner_id!="" else "∞ COOPERA\nPARTNER") if str(entities[player_id]["branch"]) == "archaea" else "∞ COOPERA\nBLOCCATA"
        if battle.active():
            buttons["cooperate"].text = "COOPERA\nALLEATI / SEPARATI"
        buttons["regen"].text = "✚ RIGENERA\n30 HP"
        buttons["menu"].text = "☰ MENU\nOPZIONI"
        scission_button.text = "◌  ◌\nDIVIDI"
    if is_instance_valid(journey):
        if journey.active(): objective_label.text = journey.objective()
        journey.update_ui()

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
    b.pressed.connect(func():
        if not division_active:
            action.call())
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
    cell_world_glyphs.visible = false # Actual 3D cell phenotypes in every camera mode.
    cell_world_glyphs.size = wh
    for cell_id in entities:
        var e: Dictionary = entities[cell_id]
        if is_instance_valid(e["node"]):
            e["node"].visible = true
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
            tab.text = ("RISORSE" if i == 0 else ("EVOLUZIONE" if i == 1 else ("META" if i == 2 else "LINEA"))) if i != 1 else "EVOLUZIONE (%.1f)" % mutation_points
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
        toast_back.position = Vector2(48,bh-465)*ui
        toast_back.size = Vector2(bw-96,58)*ui
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
        toast_back.position = Vector2(wh.x*.25,wh.y-165)
        toast_back.size = Vector2(wh.x*.50,58)
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
    b.pressed.connect(func():
        if not division_active:
            action.call())
    overlay_list.add_child(b)

func _close_overlay() -> void:
    if battle.active() and not str(battle.state.result).is_empty():
        battle.finish(str(battle.state.result))
        return
    if hp<=0.0:
        _game_over()
        return
    if is_instance_valid(overlay):
        overlay.visible = false
    is_paused = false
    move_vector = Vector2.ZERO
    touch_index = -1
    if is_instance_valid(joystick):
        joystick.set_controls_enabled(true)
        joystick.reset_input()

# The census includes active individuals and off-screen cohorts exactly once.
func _advance_niches(delta: float) -> void:
    for id in entities.keys():
        var e: Dictionary = entities[id]
        var at: Vector3 = e["node"].position
        var previous: Vector3 = e.get("census_position",at)
        var lineage: String = str(e.get("ecotype",id))
        if Ecology.niche_id(previous) != Ecology.niche_id(at):
            Ecology.register_death(ecology,lineage,previous)
            Ecology.register_birth(ecology,lineage,at)
        e["census_position"] = at
        if id != player_id and id != partner_id and not events.dormant(str(id)) and not collectives.linked(str(id)) and player.position.distance_to(at)>42.0:
            # Demotion retains population and genealogy. It is not a death.
            campaign.archive(str(id))
            e["node"].queue_free()
            entities.erase(id)
    for id in entities:
        var e: Dictionary = entities[id]
        Ecology.register_death(ecology,str(e.get("ecotype",id)),e["node"].position)
    Ecology.advance(ecology,delta,ecological_profiles)
    for id in entities:
        var e: Dictionary = entities[id]
        Ecology.register_birth(ecology,str(e.get("ecotype",id)),e["node"].position)
    cohort_timer += delta
    if cohort_timer >= 5.0:
        cohort_timer = 0.0
        _materialize_cohorts()

func _materialize_cohorts() -> void:
    campaign.materialize(Ecology.niche_id(player.position))
    var niche: Dictionary = ecology.niches[Ecology.niche_id(player.position)]
    var represented: Dictionary = {}
    for id in entities:
        var e: Dictionary = entities[id]
        if Ecology.niche_id(e.node.position) == Ecology.niche_id(player.position):
            var lineage: String = str(e.get("ecotype",id))
            represented[lineage] = int(represented.get(lineage,0))+1
    var created: int = 0
    for lineage in niche.populations:
        if created>=4 or entities.size()>=npc_population_cap:
            break
        if int(niche.populations[lineage])<=int(represented.get(lineage,0)):
            continue
        var traits: Dictionary = ecological_profiles.get(lineage,_base_traits()).duplicate(true)
        var branch: String = str(traits.get("ecological_branch","pre_luca"))
        var id: String = "P-%03d" % next_id
        next_id += 1
        var at: Vector3 = _world_position(player.position+Vector3(rng.randf_range(-8,8),0,rng.randf_range(-8,8)))
        if Ecology.niche_id(at) != Ecology.niche_id(player.position):
            at = player.position
        ecology_syncing = true
        _create_entity(id,str(traits.get("founder_id",lineage)),int(traits.get("ecological_generation",0))+1,branch,traits,at,false,true)
        ecology_syncing = false
        entities[id]["ecotype"] = lineage
        entities[id]["evolution"] = traits.get("ecological_evolution",Evolution.origin()).duplicate(true)
        created += 1

func _differentiate_lineage() -> void:
    var e: Dictionary = entities[player_id]
    var previous: String = str(e.get("ecotype",player_id))
    var descendant: String = "%s-v%d-%d" % [player_id,purchased.size(),evolution.get("unlocks",{}).size()]
    if descendant == previous:
        return
    Ecology.differentiate(ecology,previous,descendant,player.position)
    e["ecotype"] = descendant
    ecological_profiles[descendant] = e["traits"].duplicate(true)
    ecological_profiles[descendant]["ecological_branch"] = e.branch
    ecological_profiles[descendant]["ecological_generation"] = generation
    ecological_profiles[descendant]["founder_id"] = player_id
    ecological_profiles[descendant]["ecological_evolution"] = evolution.duplicate(true)

func _evolution_context() -> Dictionary:
    var u: Dictionary = evolution.get("unlocks",{})
    var alive: bool = partner_id != "" and entities.has(partner_id)
    var internal: bool = u.get("internal_symbiont",false) and evolution.has("endosymbiont")
    return {"division_id":player_id,"external_partner_alive":alive,
        "partner_id":str(entities[partner_id].get("ecotype",partner_id)) if alive else "",
        "partner_branch":"bacteria" if alive else "",
        "exchange_active":alive and bool(phase2_progress.get("active_stable",false)),
        "internal_transmitted":internal and atp>=30.0,
        "protein_import":u.get("protein_import",false),
        "metabolic_integration":u.get("metabolic_integration",false),
        "coordinated_division":u.get("coordinated_division",false),
        "membrane_traffic_functional":u.get("membrane_traffic",false),
        "nuclear_transport_functional":u.get("nucleus",false)}

func _on_evolution() -> void:
    _open_overlay("CAPACITÀ EVOLUTIVE", "Una linea · percorsi alternativi · PM condivisi con le specializzazioni")
    overlay_scroll.visible = false
    var view = preload("res://src/evolution_tree.gd").new()
    view.name = "EvolutionCapabilities"
    view.configure(evolution,mutation_points,entities[player_id]["traits"],_evolution_context())
    view.capability_requested.connect(_unlock_capability)
    overlay.add_child(view)
    view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    view.offset_left = 18
    view.offset_right = -18
    view.offset_top = 180
    view.offset_bottom = -20
    view.call_deferred("fit_graph")

func _unlock_capability(id: String) -> void:
    if not entities.has(player_id):
        return
    var entry: Dictionary = Evolution._find(id)
    if entry.is_empty() or mutation_points<float(entry.cost) or not Evolution.can_unlock(evolution,id,entities[player_id]["traits"],_evolution_context()):
        return
    evolution["evidence"] = _evolution_context()
    var updated: Dictionary = Evolution.unlock(evolution,id)
    if not updated.unlocks.get(id,false):
        return
    mutation_points -= float(entry.cost)
    evolution = updated
    var e: Dictionary = entities[player_id]
    var branch: String = str(e.branch)
    if id == "luca": branch = "luca"
    if id == "bacteria": branch = "bacteria"
    if id == "archaea": branch = "archaea"
    var traits: Dictionary = e.traits
    var gene_map: Dictionary = {"dna_archive":"dna_stabilization","bacteria":"monoderm_envelope","archaea":"archaeal_envelope","bioenergetics":"membrane_transport","cytoskeleton":"surface_recognition","prokaryotic_groups":"eps_biosynthesis"}
    if gene_map.has(id):
        traits = GenomeScript.grant(traits,gene_map[id],generation,"capacita_evolutiva",branch)
    if id == "internal_symbiont":
        # Store donor provenance as a relationship, not a second genealogical parent.
        evolution["endosymbiont"] = {"donor_id":partner_id,"donor_lineage":entities[partner_id].get("ecotype",partner_id),"host_id":player_id,"acquired_generation":generation}
        _remove_entity(partner_id,"internalizzazione")
    traits["evolution_capabilities"] = evolution.unlocks.duplicate(true)
    e.traits = GenomeScript.express(traits,branch)
    e.branch = branch
    var at: Vector3 = player.position
    player.setup(e.traits,branch,true)
    player.position = at
    _differentiate_lineage()
    _cache_current()
    for rec in genealogy:
        if rec.get("id","") == player_id:
            rec["traits"] = e.traits.duplicate(true)
            rec["branch"] = branch
    _save_game()
    _on_evolution()

func _legacy_evolution(e: Dictionary) -> Dictionary:
    var result: Dictionary = Evolution.origin()
    result["divisions"] = maxi(0,int(e.get("generation",0)))
    var branch: String = str(e.get("branch","pre_luca"))
    if branch in ["luca","bacteria","archaea"]:
        for id in ["rna_inheritance","translation","dna_archive","bioenergetics","luca"]:
            result.unlocks[id] = true
    if branch in ["bacteria","archaea"]:
        result.unlocks[branch] = true
    result["migration"] = "existing_branch_only_no_internal_symbiosis"
    return Evolution.normalize(result)

func _niche_label(value: String) -> String:
    return {"dominant":"dominante","coexistence":"coesistenza","sparse":"da consolidare"}.get(value,value)

func _expire_notice() -> void:
    if notice_expires>=0 and float(Time.get_ticks_msec())/1000.0>=notice_expires:
        tips_label.visible = false
        toast_back.visible = false
        notice_expires = -1.0

func _division_block_reason() -> String:
    if events.dormant(player_id): return "Risvegliati prima della scissione"
    for key in NEED:
        if float(resources.get(key,0))<float(NEED[key])-.001:
            return "Raccogli tutti i nutrienti necessari"
    if atp<30.0:
        return "Servono almeno 30 ATP per dividerti"
    var remaining: float = (35.0 if generation==0 else 75.0)-cycle_age
    if remaining>0.0:
        return "Divisione pronta tra %d s" % int(ceil(remaining))
    return ""

func _on_statistics(scope: int = 0, filter: int = 0) -> void:
    if not entities.has(player_id): return
    _open_overlay("STATISTICHE", "Popolazioni delle nicchie e attività della partita")
    var selector := OptionButton.new()
    selector.add_item("Nicchia attuale")
    selector.add_item("Intera mappa · 25 nicchie")
    selector.selected = scope
    selector.custom_minimum_size.y = 48
    selector.item_selected.connect(func(index: int): _on_statistics(index,filter))
    overlay_list.add_child(selector)
    var data: Dictionary = Statistics.census(ecology,ecological_profiles,player.position,scope==1)
    _add_overlay_label("%d cellule · %.4f km² · occupazione %.1f%%" % [data.total,data.area,data.occupied_percent])
    _add_overlay_label("Occupazione = cellule / capacità (%d). Composizione = quota delle cellule presenti. Due cellule su 48 occupano il 4,2%%, ma possono essere il 100%% della popolazione." % data.capacity)
    for group in data.groups:
        var count: int = int(data.groups[group])
        if count==0 and group=="Non classificate": continue
        _add_overlay_label("%s · %d
%.1f%% della popolazione · %.1f%% della capacità" % [group,count,100.0*count/maxi(1,int(data.total)),100.0*count/int(data.capacity)])
    _add_overlay_label("Spazio libero: %.1f%%. Dominanza e coesistenza restano basate su densità e rapporto con la rivale maggiore." % data.free_percent)
    var filter_select := OptionButton.new()
    for label in ["Tutte le linee","Solo cellule RNA","Solo cellule DNA"]: filter_select.add_item(label)
    filter_select.selected = filter
    filter_select.custom_minimum_size.y = 48
    filter_select.item_selected.connect(func(index: int): _on_statistics(scope,index))
    overlay_list.add_child(filter_select)
    for line in data.lines:
        if filter==1 and line.group!="Cellule RNA" or filter==2 and line.group!="Cellule DNA": continue
        var fold := Button.new()
        fold.toggle_mode = true
        fold.text = "%s%s · %d · %.1f%%  ▾" % ["★ " if line.id==entities[player_id].get("ecotype",player_id) else "",line.id,line.count,line.population_percent]
        fold.custom_minimum_size.y = 48
        overlay_list.add_child(fold)
        var details := _label("%s · %.1f cellule/km²
Mobilità %.0f%% · Attacco %.0f%% · Difesa %.0f%%
%s" % [line.group,line.density,100.0*float(line.traits.get("motility",1)),100.0*float(line.traits.get("attack",1)),100.0*float(line.traits.get("defense",1)),"; ".join(GenomeScript.describe(line.traits))],14)
        details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        details.visible = false
        overlay_list.add_child(details)
        fold.toggled.connect(func(open: bool): details.visible = open)
    _add_overlay_label("ATTIVITÀ DEL GIOCATORE · tutte le linee controllate")
    _add_overlay_label("Divisioni effettuate: %d · Generazione attuale: %d
Nutrienti raccolti: %d particelle
Porzioni digerite: %d · Prede eliminate: %d" % [statistics.divisions,generation,statistics.particles,statistics.substrates,statistics.kills])
    var names: Dictionary = {"carbon":"Carbonio","amino":"Amminoacidi","lipid":"Lipidi","nucleic":"Nucleotidi"}
    for key in names:
        _add_overlay_label("%s assorbiti: %.1f" % [names[key],statistics.collected[key]])
    _add_overlay_label("Le quantità contano solo ciò che entra nelle riserve, anche da digestione e prede; non il materiale perso a riserve piene.")
    if float(statistics.started_at)>0:
        _add_overlay_label("Conteggi raccolta e divisioni registrati da %.0f minuti di questa partita; il salvataggio precedente non conservava lo storico." % (float(statistics.started_at)/60.0))
