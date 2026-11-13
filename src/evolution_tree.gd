extends Control
class_name EvolutionTree
signal capability_requested(id: String)
const Progress = preload("res://src/evolution_progress.gd")
const POSITIONS: Dictionary = {
    "cell_zero":Vector2(-850,0),"rna_inheritance":Vector2(-650,0),
    "translation":Vector2(-450,0),"dna_archive":Vector2(-250,-110),
    "bioenergetics":Vector2(-250,110),"luca":Vector2(-50,0),
    "bacteria":Vector2(150,240),"alpha_partner":Vector2(380,240),
    "prokaryotic_groups":Vector2(-80,380),"differentiated_groups":Vector2(180,420),
    "archaea":Vector2(150,-180),"asgard_host":Vector2(360,-180),
    "cytoskeleton":Vector2(570,-180),"membrane_traffic":Vector2(780,-280),
    "stable_consortium":Vector2(780,70),"internal_symbiont":Vector2(1010,70),
    "nucleus":Vector2(1010,-360),"er_golgi":Vector2(1010,-180),
    "protein_import":Vector2(1230,-70),"metabolic_integration":Vector2(1230,130),
    "coordinated_division":Vector2(1230,330),
    "mitochondrion":Vector2(1460,70),"leca":Vector2(1680,-180)}
var state: Dictionary = {}
var points: float = 0.0
var traits: Dictionary = {}
var context: Dictionary = {}
var zoom_level: float = .5
var pan: Vector2 = Vector2.ZERO
var inspected: String = "cell_zero"
var node_positions: Dictionary = POSITIONS.duplicate()
const COMPACT_POSITIONS: Dictionary = {
    "cell_zero":Vector2(-640,0),"rna_inheritance":Vector2(-640,-190),
    "translation":Vector2(-420,-290),"dna_archive":Vector2(-210,-430),
    "bioenergetics":Vector2(-210,-210),"luca":Vector2(10,-290),
    "bacteria":Vector2(10,0),"alpha_partner":Vector2(240,90),
    "prokaryotic_groups":Vector2(-410,160),"differentiated_groups":Vector2(-410,390),
    "archaea":Vector2(250,-430),"asgard_host":Vector2(490,-430),
    "cytoskeleton":Vector2(680,-270),"membrane_traffic":Vector2(680,-10),
    "stable_consortium":Vector2(470,230),"internal_symbiont":Vector2(720,360),
    "nucleus":Vector2(930,-220),"er_golgi":Vector2(1160,-40),
    "protein_import":Vector2(960,190),"metabolic_integration":Vector2(960,430),
    "coordinated_division":Vector2(710,600),"mitochondrion":Vector2(1210,430),
    "leca":Vector2(1390,180)}
const SHORT_NAMES: Dictionary = {"cell_zero":"Zero","rna_inheritance":"RNA","luca":"LUCA",
    "bacteria":"Bacteria","archaea":"Archaea","asgard_host":"Asgard","nucleus":"Nucleo",
    "er_golgi":"Golgi","mitochondrion":"Mito","leca":"LECA"}
var _title: Label
var _description: Label
var _purchase: Button
var _card: PanelContainer
var _toolbar: HBoxContainer
var _dragging: bool = false
var _travel: float = 0.0
var _last_tap: int = 0
var _fitted: bool = false

func configure(data: Dictionary, available_points: float, genome_traits: Dictionary = {}, current_context: Dictionary = {}) -> void:
    state = Progress.normalize(data)
    points = maxf(0.0,available_points)
    traits = genome_traits.duplicate(true)
    context = current_context.duplicate(true)
    if is_node_ready():
        _refresh()
    queue_redraw()

func _ready() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    if state.is_empty():
        state = Progress.origin()
    _toolbar = HBoxContainer.new()
    add_child(_toolbar)
    for title in ["−","+","Tutto"]:
        var button := Button.new()
        button.text = title
        button.custom_minimum_size = Vector2(58,44)
        _toolbar.add_child(button)
        if title == "Tutto":
            button.pressed.connect(fit_graph)
        elif title == "+":
            button.pressed.connect(func(): _zoom(1.25))
        else:
            button.pressed.connect(func(): _zoom(.8))
    _card = PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(.035,.09,.12,.98)
    style.border_color = Color(.18,.51,.57)
    style.set_border_width_all(1)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    _card.add_theme_stylebox_override("panel",style)
    add_child(_card)
    var column := VBoxContainer.new()
    _card.add_child(column)
    _title = Label.new()
    _title.add_theme_font_size_override("font_size",19)
    _title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_title)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    _description = Label.new()
    _description.add_theme_font_size_override("font_size",15)
    _description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_description)
    _purchase = Button.new()
    _purchase.custom_minimum_size.y = 44
    _purchase.pressed.connect(_request_purchase)
    column.add_child(_purchase)
    resized.connect(_layout)
    _layout()
    _refresh()

func graph_rect() -> Rect2:
    return Rect2(0,58,size.x,maxf(80,size.y-_card_height()-68))

func _card_height() -> float:
    return minf(250,maxf(190,size.y*.36))

func _layout() -> void:
    node_positions = COMPACT_POSITIONS.duplicate()
    if size.x<600:
        # Rotate the compact branching map into a portrait reading direction.
        for id in node_positions:
            var point: Vector2 = node_positions[id]
            node_positions[id] = Vector2(point.y,-point.x)
    _toolbar.position = Vector2(12,6)
    _card.position = Vector2(8,maxf(80,size.y-_card_height()))
    _card.size = Vector2(maxf(100,size.x-16),_card_height()-8)
    if not _fitted and size.x > 100:
        fit_graph()
        _fitted = true
    queue_redraw()

func fit_graph() -> void:
    var bounds := Rect2(Vector2(node_positions.values()[0]),Vector2.ZERO)
    for point in node_positions.values():
        bounds = bounds.expand(point)
    zoom_level = clampf(minf((size.x-70)/(bounds.size.x+80),(graph_rect().size.y-60)/(bounds.size.y+80)),.10,1.2)
    pan = -bounds.get_center()*zoom_level
    queue_redraw()

func _zoom(factor: float) -> void:
    var old: float = zoom_level
    zoom_level = clampf(zoom_level*factor,.10,2.5)
    pan *= zoom_level/old
    queue_redraw()

func screen_position(id: String) -> Vector2:
    return graph_rect().get_center()+pan+Vector2(node_positions.get(id,Vector2.ZERO))*zoom_level

func focus_node(id: String) -> void:
    if not node_positions.has(id):
        return
    inspected = id
    pan = -Vector2(node_positions[id])*zoom_level
    _refresh()

func locked_reasons(id: String) -> Array[String]:
    var reasons: Array[String] = []
    var entry: Dictionary = _entry(id)
    if entry.is_empty():
        return ["Capacita sconosciuta"]
    if bool(state.get("unlocks",{}).get(id,false)):
        return ["Capacita gia acquisita"]
    for required in entry.requires:
        if not bool(state.unlocks.get(required,false)):
            reasons.append("Richiede: "+str(_entry(required).get("label",required)))
    if int(state.divisions)<int(entry.min_divisions):
        reasons.append("Divisioni: %d / %d" % [state.divisions,entry.min_divisions])
    if points<float(entry.cost):
        reasons.append("Punti insufficienti: %.1f / %d" % [points,entry.cost])
    if id == "archaea" and bool(state.unlocks.get("bacteria",false)) or id == "bacteria" and bool(state.unlocks.get("archaea",false)):
        reasons.append("Ramo alternativo: continua con una linea sorella")
    if not Progress.can_unlock(state,id,traits,context) and reasons.is_empty():
        var stability: Dictionary = state.stability
        if id in ["stable_consortium","internal_symbiont"]:
            reasons.append("Partner Bacteria vivo e scambio attivo; stabilita %d / %d divisioni" % [stability.external,3 if id=="stable_consortium" else 6])
        elif id == "mitochondrion":
            reasons.append("Trasmissione interna %d / 6; integrazione %d / 4" % [stability.internal,stability.integrated])
        elif id == "leca":
            reasons.append("Funzioni integrate trasmesse: %d / 8 divisioni" % stability.leca)
        else:
            reasons.append("Prerequisiti funzionali non soddisfatti")
    return reasons

func _entry(id: String) -> Dictionary:
    for entry in Progress.catalogue():
        if entry.id == id:
            return entry
    return {}

func _refresh() -> void:
    if _title == null:
        return
    var entry: Dictionary = _entry(inspected)
    _title.text = str(entry.get("label",inspected))+"  ·  %.1f punti" % points
    var reasons: Array[String] = locked_reasons(inspected)
    _description.text = "%s\nCosto %d · Da divisione %d · %s\n%s" % [entry.get("description",""),entry.get("cost",0),entry.get("min_divisions",0),entry.get("confidence","GAMEPLAY"),"Disponibile. Tocca Acquisisci oppure tocca di nuovo il nodo." if reasons.is_empty() else "\n".join(reasons)]
    _purchase.text = "Acquisita" if bool(state.unlocks.get(inspected,false)) else "Acquisisci · %d punti" % int(entry.get("cost",0))
    _purchase.disabled = not reasons.is_empty()
    queue_redraw()

func _request_purchase() -> void:
    if locked_reasons(inspected).is_empty():
        capability_requested.emit(inspected)

func _category_color(id: String) -> Color:
    if id in ["bacteria","alpha_partner","stable_consortium","internal_symbiont","protein_import","metabolic_integration","coordinated_division","mitochondrion"]:
        return Color(.98,.66,.32)
    if id in ["archaea","asgard_host","cytoskeleton","membrane_traffic","nucleus","er_golgi"]:
        return Color(.66,.59,.98)
    if id in ["prokaryotic_groups","differentiated_groups"]:
        return Color(.40,.85,.51)
    return Color(.36,.84,.91)

func _icon(id: String, center: Vector2, radius: float, tint: Color) -> void:
    var r: float = radius*.68
    if id in ["dna_archive","rna_inheritance","translation"]:
        for sign_value in [-1,1]:
            var curve := PackedVector2Array()
            for step in range(13):
                var u: float = float(step)/12.0
                curve.append(center+Vector2(sin(u*TAU)*r*.5*sign_value,(u*2-1)*r))
            draw_polyline(curve,tint,1.3,true)
    elif id in ["nucleus","leca"]:
        draw_arc(center,r,0,TAU,20,tint,1.3,true)
        draw_arc(center,r*.5,0,TAU,20,tint,1.3,true)
        draw_circle(center,1.5,tint)
    elif id in ["mitochondrion","internal_symbiont","metabolic_integration"]:
        draw_arc(center,r,0,TAU,20,tint,1.3,true)
        var folds := PackedVector2Array()
        for step in range(5):
            folds.append(center+Vector2((float(step)/4-.5)*r*1.5,r*.45*(1 if step%2==0 else -1)))
        draw_polyline(folds,tint,1.4,true)
    elif id in ["membrane_traffic","er_golgi","protein_import"]:
        for row in range(3):
            var y: float = (row-1)*r*.65
            draw_line(center+Vector2(-r*.65,y),center+Vector2(r*.45,y),tint,1.4,true)
        draw_circle(center+Vector2(r*.85,-r*.7),r*.20,tint)
    elif id in ["stable_consortium","coordinated_division","prokaryotic_groups","differentiated_groups"]:
        draw_arc(center-Vector2(r*.4,0),r*.55,0,TAU,16,tint,1.3,true)
        draw_arc(center+Vector2(r*.4,0),r*.55,0,TAU,16,tint,1.3,true)
    else:
        draw_arc(center,r*.65,0,TAU,20,tint,1.3,true)
        draw_circle(center+Vector2(r*.15,-r*.12),r*.2,tint)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(.012,.045,.065))
    var font: Font = ThemeDB.fallback_font
    var graph: Rect2 = graph_rect()
    for entry in Progress.catalogue():
        for required in entry.requires:
            var start: Vector2 = screen_position(required)
            var finish: Vector2 = screen_position(entry.id)
            if graph.has_point(start) and graph.has_point(finish):
                draw_line(start,finish,Color(.16,.39,.43),2,true)
    # Contextual donor link is distinct from AND prerequisites and never gates host lineage ownership.
    var donor: Vector2 = screen_position("alpha_partner")
    var consortium: Vector2 = screen_position("stable_consortium")
    if graph.has_point(donor) and graph.has_point(consortium):
        draw_dashed_line(donor,consortium,Color(.94,.64,.29),2,8,true)
    for entry in Progress.catalogue():
        var p: Vector2 = screen_position(entry.id)
        if not graph.grow(-12).has_point(p):
            continue
        var owned: bool = bool(state.get("unlocks",{}).get(entry.id,false))
        var available: bool = Progress.can_unlock(state,entry.id,traits,context)
        var tint: Color = _category_color(entry.id)
        if not owned and not available:
            tint = tint.darkened(.25)
        var radius: float = clampf(25*zoom_level,9,25)
        draw_circle(p,radius,Color(.025,.10,.13))
        draw_arc(p,radius,0,TAU,32,tint,3,true)
        if entry.id == inspected:
            draw_arc(p,radius+5,0,TAU,32,Color.WHITE,2,true)
        _icon(entry.id,p,radius,tint.lightened(.20))
        if owned:
            draw_circle(p+Vector2(radius*.8,-radius*.8),2.5,Color(.3,1,.5))
        # Text stays legible while zooming; full long names are always in inspection card.
        if zoom_level<.27 and entry.id!=inspected and not SHORT_NAMES.has(entry.id):
            continue
        var caption: String = str(SHORT_NAMES.get(entry.id,entry.label))
        if zoom_level<.65 and caption.length()>14:
            caption = caption.substr(0,12)+"…"
        var text_size: int = 12 if zoom_level<.5 else 16
        var width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x
        draw_string(font,p+Vector2(-width*.5,radius+19),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color(.86,.94,.95))
    draw_string(font,Vector2(202,34),"Trascina · zoom · tocca un nodo",HORIZONTAL_ALIGNMENT_LEFT,maxf(0,size.x-210),14,Color(.60,.76,.80))

func _tap(position: Vector2) -> void:
    var nearest: String = ""
    var distance: float = 28
    for id in node_positions:
        var current: float = position.distance_to(screen_position(id))
        if current<distance:
            nearest = id
            distance = current
    if nearest == "":
        return
    var now: int = Time.get_ticks_msec()
    var double_tap: bool = nearest==inspected and now-_last_tap<450
    inspected = nearest
    _last_tap = now
    _refresh()
    if double_tap:
        _request_purchase()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMagnifyGesture:
        _zoom(event.factor)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(1.12)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(1.0/1.12)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = event.pressed
            if event.pressed:
                _travel = 0
            elif _travel<8:
                _tap(event.position)
    elif event is InputEventMouseMotion and _dragging:
        pan += event.relative
        _travel += event.relative.length()
        queue_redraw()
    elif event is InputEventScreenTouch:
        if event.pressed:
            _travel = 0
        elif _travel<8:
            _tap(event.position)
    elif event is InputEventScreenDrag:
        pan += event.relative
        _travel += event.relative.length()
        queue_redraw()
