extends Node
## Persistent, optional first-cycle guidance. All rewards use the ordinary game.
const Genome = preload("res://src/cell_genome.gd")
const Portrait = preload("res://src/phenotype_portrait.gd")
var game: Node
var state: Dictionary = {"step":"gather"}
var marker: MeshInstance3D
var skip_button: Button
var target: Node3D

func active() -> bool:
    return not game.battle.active() and str(state.get("step","done")) not in ["done","skipped"]

func reset(arena: bool = false) -> void:
    state = {"step":"done" if arena else "gather"}
    target = null
    if is_instance_valid(marker): marker.hide()

func restore(raw: Variant) -> void:
    state = raw.duplicate(true) if raw is Dictionary else {"step":"done" if game.generation>0 else "gather"}
    if str(state.get("step","")) not in ["gather","offer","comparison","digest","explain","done","skipped"]:
        state = {"step":"done"}
    target = null
    if active() and state.step == "digest": ensure_detritus()

func skip() -> void:
    state.step = "skipped"
    game._close_overlay()
    game._layout_ui()
    game._refresh_hud()
    game._save_game()

func objective() -> String:
    if not active(): return ""
    match state.step:
        "gather":
            if game._can_divide(): return "Premi DIVIDI: la tua prima scissione è pronta"
            for kind in game.TYPES:
                if float(game.resources[kind])<float(game.NEED[kind])-.001:
                    var names: Dictionary = {"carbon":"carbonio","amino":"amminoacidi","lipid":"lipidi","nucleic":"nucleotidi"}
                    return "Raccogli %s · mancano %.1f · segui il cerchio verde" % [names[kind],float(game.NEED[kind])-float(game.resources[kind])]
            if game.resources.biomass<game.NEED.biomass: return "Continua a raccogliere: completa la biomassa per dividerti"
            return game._division_block_reason()
        "offer": return "Prima mutazione: ENZIMI · 2 PM, oppure conserva i punti"
        "comparison": return "Apri ENZIMI per vedere il confronto prima / dopo"
        "digest": return "Raggiungi il detrito illuminato e premi ENZIMI · 6 ATP"
        "explain": return "Mutazione provata! EVOLUZIONE: specializzazioni e capacità"
    return ""

func after_division() -> void:
    if active() and state.step == "gather":
        state.step = "offer"
        offer()

func offer() -> void:
    game._open_overlay("LA PRIMA MUTAZIONE", "Enzimi digestivi · stesso nodo e costo dell’albero")
    game._add_overlay_label("Le idrolasi permettono di digerire detriti organici. Costo: 2 PM. Ogni digestione costa 6 ATP e rispetta il limite delle riserve.")
    game._add_overlay_button("Acquista enzimi · 2 PM", buy)
    game._add_overlay_button("Conserva i punti e continua", skip)

func buy() -> void:
    # Use the actual tree validator, cost and phenotype implementation.
    game._on_tree()
    var cost: int = game.tree_view._cost(88)
    game._on_tree_mutation(88,game.tree_view.STATS[1],0.0,cost)

func purchased_enzyme(before: Dictionary) -> void:
    if not active() or state.step not in ["gather","offer"]: return
    state.before = before.duplicate(true)
    state.step = "comparison"
    comparison()

func comparison() -> void:
    game._open_overlay("PRIMA / DOPO · ENZIMI", "Due viste 3D della tua cellula, con lo stesso genoma del mondo")
    game._add_overlay_label("PRIMA: nessuna secrezione digestiva. DOPO: moduli enzimatici sulla membrana; ora puoi digerire i detriti.")
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 230
    game.overlay_list.add_child(row)
    for traits in [state.get("before",game._base_traits()),game.entities[game.player_id].traits]:
        var portrait := Portrait.new()
        portrait.custom_minimum_size = Vector2(200,230)
        portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(portrait)
        portrait.set_cell(traits,game.entities[game.player_id].branch)
    game._add_overlay_button("Prova gli enzimi sul detrito vicino", begin_digest)

func begin_digest() -> void:
    state.step = "digest"
    ensure_detritus()
    game._close_overlay()
    game._save_game()

func ensure_detritus() -> void:
    var best: float = INF
    for patch in game.substrates:
        if is_instance_valid(patch) and Vector2(patch.position.x-game.player.position.x,patch.position.z-game.player.position.z).length()<best:
            target = patch
            best = Vector2(patch.position.x-game.player.position.x,patch.position.z-game.player.position.z).length()
    if best>3.5:
        # Relocate one existing ordinary substrate; never duplicate portions on reload.
        if not is_instance_valid(target):
            game._spawn_substrate(game.player.position+Vector3(2.2,0,0),3,"peptide")
            target = game.substrates.back()
        var at: Vector3 = game.player.position+Vector3(2.2,0,0)
        var terrain: Node = game.world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
        target.position = Vector3(at.x,terrain.surface_height(Vector2(at.x,at.z))+.04,at.z)

func digested() -> void:
    if not active() or state.step != "digest": return
    state.step = "explain"
    game.call_deferred("_notice","Digestione riuscita! EVOLUZIONE: piccoli nodi specializzano, grandi nodi aggiungono capacità.")

func explain() -> void:
    if active() and state.step == "explain":
        state.step = "done"
        game._layout_ui()
        game._notice("Nodi piccoli: bonus e malus. Nodi grandi: capacità e strutture ereditabili.")

func enzyme_action() -> bool:
    if not active(): return false
    if state.step == "offer": offer(); return true
    if state.step == "comparison": comparison(); return true
    return false

func update_ui() -> void:
    if not is_instance_valid(skip_button):
        skip_button = Button.new()
        skip_button.text = "Salta guida"
        skip_button.pressed.connect(skip)
        game.hud.add_child(skip_button)
    skip_button.visible = active()
    var wh: Vector2 = game.get_viewport().get_visible_rect().size
    skip_button.position = Vector2(wh.x/2-65,wh.y-208)
    skip_button.size = Vector2(130,40)
    # Contextual actions, while the complete tree remains in its tab and menu.
    var tr: Dictionary = game.entities[game.player_id].traits
    game.buttons.regen.visible = game.battle.active() or game.hp<90 or game.generation>0
    game.buttons.enzymes.visible = game.battle.active() or game.generation>0 or Genome.has(tr,"hydrolase_secretion")
    game.buttons.lysis.visible = game.battle.active() or (Genome.has(tr,"hydrolase_secretion") and Genome.has(tr,"surface_recognition"))
    game.buttons.cooperate.visible = game.battle.active() or str(game.entities[game.player_id].branch)=="archaea"
    if not active():
        if is_instance_valid(marker): marker.hide()
        return
    if not is_instance_valid(marker):
        marker = MeshInstance3D.new()
        var ring := TorusMesh.new()
        ring.inner_radius = .36
        ring.outer_radius = .43
        marker.mesh = ring
        var mat := StandardMaterial3D.new()
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.albedo_color = Color(.45,1,.72)
        marker.material_override = mat
        game.world_root.add_child(marker)
    if state.step == "gather":
        target = null
        var nearest: float = INF
        var needed: String = ""
        for kind in game.TYPES:
            if float(game.resources[kind])<float(game.NEED[kind])-.001:
                needed = kind
                break
        for n in game.nutrients:
            if not is_instance_valid(n.node): continue
            var useful: bool = n.kind==needed if not needed.is_empty() else (game.resources.biomass<game.NEED.biomass or (n.kind=="carbon" and game.atp<30))
            var d: float = n.node.position.distance_squared_to(game.player.position)
            if useful and game._temperature_at(n.node.position)<40 and d<nearest:
                target = n.node
                nearest = d
    elif state.step == "digest":
        if not is_instance_valid(target): ensure_detritus()
    else: target = null
    marker.visible = is_instance_valid(target)
    if marker.visible:
        marker.position = target.position+Vector3(0,.12,0)
        marker.scale = Vector3.ONE*(1.0+.1*sin(game.t*3))
