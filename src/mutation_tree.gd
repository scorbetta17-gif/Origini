extends Control
class_name MutationTree
## 288 nodi collegati, con zoom/pan e allocazione reale dei punti.

signal mutation_unlocked(node_id: int, stat: String, value: float, cost: int)

const BRANCHES := ["MOTILITA", "ATTACCO", "DIFESA", "MUTAZIONI", "METABOLISMO", "ASSORBIMENTO"]
const STATS := ["motility", "attack", "defense", "mutation", "metabolism", "uptake"]
const COLORS := [
    Color(0.25, 0.86, 0.98), Color(1.0, 0.45, 0.43), Color(0.94, 0.74, 0.29),
    Color(0.83, 0.48, 1.0), Color(0.38, 0.94, 0.49), Color(0.41, 0.81, 0.92)
]
var owned: Dictionary = {}
var points: int = 0
var zoom_level: float = 0.9
var pan: Vector2 = Vector2.ZERO
var last_pointer: Vector2 = Vector2.ZERO
var dragging: bool = false
var gesture_travel: float = 0.0
var touch_dragged: bool = false
var touch_seen: bool = false
var inspected: int = 0

func configure(data: Dictionary, available_points: int) -> void:
    owned = data.duplicate(true)
    points = available_points
    queue_redraw()

func _pos(node_id: int) -> Vector2:
    var branch: int = node_id / 48
    var local: int = node_id % 48
    var ring: int = local / 8
    var lane: int = local % 8
    var angle: float = -PI * 0.5 + float(branch) * TAU / 6.0 + float(lane - 3) * 0.088
    var radius: float = 85.0 + float(ring) * 67.0
    return Vector2(cos(angle), sin(angle)) * radius

func _screen(world_pos: Vector2) -> Vector2:
    return size * 0.5 + pan + world_pos * zoom_level

func _type(node_id: int) -> int:
    var ring: int = (node_id % 48) / 8
    if ring == 5:
        return 2
    if ring == 2 or ring == 4:
        return 1
    return 0

func _cost(node_id: int) -> int:
    return _type(node_id) + 1

func _available(node_id: int) -> bool:
    if owned.has(str(node_id)):
        return false
    var local: int = node_id % 48
    return local < 8 or owned.has(str(node_id - 8))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(.011,.061,.085,.99))
    var center: Vector2 = _screen(Vector2.ZERO)
    for branch in range(6):
        var tint: Color = COLORS[branch]
        var far := _screen(Vector2(cos(-PI*.5+float(branch)*TAU/6.0),
            sin(-PI*.5+float(branch)*TAU/6.0))*530)
        draw_line(center,far,Color(tint.r,tint.g,tint.b,.13),6.0*zoom_level,true)
        for local in range(48):
            var id: int = branch*48+local
            var at: Vector2 = _screen(_pos(id))
            var parent: Vector2 = _screen(Vector2.ZERO if local < 8 else _pos(id-8))
            var active: bool = owned.has(str(id))
            draw_line(parent,at,Color(tint.r,tint.g,tint.b,.70) if active else Color(.23,.39,.44,.35),
                (2.6 if active else 1.1)*zoom_level,true)
    for branch in range(6):
        for local in range(48):
            var id: int = branch*48+local
            var at: Vector2 = _screen(_pos(id))
            var color: Color = COLORS[branch]
            var active: bool = owned.has(str(id))
            var ready: bool = _available(id)
            var radius: float = (5.2 if _type(id) == 0 else (8.2 if _type(id) == 1 else 11.0))*zoom_level
            if id == inspected:
                draw_circle(at,radius+8.0*zoom_level,Color(1.0,.92,.64,.30))
                draw_arc(at,radius+6.0*zoom_level,0,TAU,40,Color(1.0,.96,.73),2.2,true)
            draw_circle(at,radius+1.3*zoom_level,
                color if active else (color.darkened(.11) if ready else Color(.22,.39,.44,.76)))
            draw_circle(at,radius*.70,color.darkened(.42) if active else Color(.035,.13,.17))
            if _type(id) == 2:
                draw_circle(at,radius*.28,color.lightened(.22) if ready else Color(.33,.49,.52))
    draw_circle(center,26*zoom_level,Color(.42,.87,.78))
    draw_circle(center,18*zoom_level,Color(.13,.38,.42))
    draw_string(ThemeDB.fallback_font,center+Vector2(-19,4)*zoom_level,
        "LUCA",HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(11,int(12*zoom_level)),Color(.92,1,1))

    # Classic mobile visual hierarchy: six stat cards and branch selector.
    draw_rect(Rect2(0,0,size.x,165),Color(.015,.088,.115,.985))
    draw_line(Vector2(0,165),Vector2(size.x,165),Color(.21,.51,.56,.71),2,true)
    draw_string(ThemeDB.fallback_font,Vector2(16,27),
        "ALBERO EVOLUTIVO",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(.94,.99,.99))
    draw_string(ThemeDB.fallback_font,Vector2(16,51),
        "288 nodi · %d acquisiti · %d punti disponibili" % [owned.size(),points],
        HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.65,.84,.87))
    var stats: Array[String] = ["MOV","ATK","DIF","MUT","ATP","ASS"]
    var box_width: float = (size.x-26.0-5*5.0)/6.0
    for i in range(6):
        var x: float = 13.0+float(i)*(box_width+5)
        var rect := Rect2(x,66,box_width,56)
        draw_rect(rect,Color(.03,.13,.17,.99),true)
        draw_rect(rect,Color(COLORS[i].r,COLORS[i].g,COLORS[i].b,.41),false,1.4)
        var purchased_count: int = 0
        for local in range(48):
            if owned.has(str(i*48+local)):
                purchased_count += 1
        draw_string(ThemeDB.fallback_font,Vector2(x+7,88),
            "%d/48" % purchased_count,HORIZONTAL_ALIGNMENT_LEFT,-1,18,COLORS[i],box_width-9)
        draw_string(ThemeDB.fallback_font,Vector2(x+7,110),stats[i],
            HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.75,.88,.89),box_width-9)
    var chip: Array[String] = ["MOTILITA","ATTACCO","DIFESA","MUTAZ.","ENERGIA","ASSORB."]
    for i in range(6):
        var x: float = 10.0+float(i)*(size.x-20.0)/6.0
        var rect := Rect2(x,131,(size.x-26.0)/6.0,28)
        draw_rect(rect,Color(.032,.15,.195,.98),true)
        draw_rect(rect,Color(COLORS[i].r,COLORS[i].g,COLORS[i].b,.66),false,1)
        draw_string(ThemeDB.fallback_font,Vector2(x+5,151),chip[i],HORIZONTAL_ALIGNMENT_LEFT,-1,11,
            COLORS[i],rect.size.x-8)

    # Persistent inspector: first tap selects, second purchases an affordable node.
    draw_rect(Rect2(0,size.y-172,size.x,172),Color(.015,.083,.109,.99))
    draw_line(Vector2(0,size.y-172),Vector2(size.x,size.y-172),Color(.25,.55,.60,.65),2,true)
    if inspected >= 0:
        var branch: int = inspected/48
        var kind: int = _type(inspected)
        var title: String = "MUTAZIONE PUNTIFORME" if kind == 0 else (
            "OTTIMIZZAZIONE" if kind == 1 else "SPECIALIZZAZIONE")
        var affordable: bool = _available(inspected) and points >= _cost(inspected)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-141),
            "%s · %s" % [BRANCHES[branch],title],HORIZONTAL_ALIGNMENT_LEFT,-1,17,COLORS[branch],size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-113),
            "Effetto: +%.1f%% %s  ·  Costo %d punti" % [
                (0.022 if kind == 0 else (0.09 if kind == 1 else 0.18))*100.0,
                BRANCHES[branch],_cost(inspected)],
            HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.88,.96,.96),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-87),
            "Solo bonus numerici: nessuna nuova struttura biologica.",
            HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.65,.86,.87),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-60),
            "TOCCA ANCORA PER ACQUISTARE" if affordable else "Servono nodi precedenti o altri punti",
            HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.57,.92,.77) if affordable else Color(.95,.77,.59),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-32),
            "Mutazioni maggiori ereditabili: avvengono durante la scissione.",
            HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.69,.79,.88),size.x-34)
    else:
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-120),
            "Tocca un nodo per esaminarne l'effetto",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.90,.96,.96))

func zoom_by(factor: float) -> void:
    zoom_level = clampf(zoom_level*factor,.48,2.2)
    queue_redraw()

func center_view() -> void:
    zoom_level = .88
    pan = Vector2.ZERO
    queue_redraw()

func inspect_branch(branch: int) -> void:
    inspected = clampi(branch,0,5)*48
    queue_redraw()

func _pick(at: Vector2) -> int:
    var best: int = -1
    var distance: float = 999.0
    for i in range(288):
        var d: float = at.distance_to(_screen(_pos(i)))
        if d < 19.0 * zoom_level and d < distance:
            best = i
            distance = d
    return best

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and not touch_seen:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom_level = minf(2.15, zoom_level * 1.12)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom_level = maxf(0.42, zoom_level / 1.12)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragging = true
                gesture_travel = 0.0
                last_pointer = event.position
            else:
                dragging = false
    elif event is InputEventMouseMotion and dragging and not touch_seen:
        if event.position.distance_to(last_pointer) > 2.0:
            gesture_travel += event.position.distance_to(last_pointer)
            pan += event.position - last_pointer
            last_pointer = event.position
            queue_redraw()
    elif event is InputEventScreenTouch:
        touch_seen = true
        if event.pressed:
            last_pointer = event.position
            touch_dragged = false
        elif not touch_dragged:
            if event.position.y >= 130 and event.position.y <= 162:
                var branch: int = clampi(int((event.position.x-10.0)*6.0/maxf(1.0,size.x-20.0)),0,5)
                inspect_branch(branch)
            elif event.position.y >= 170 and event.position.y < size.y-176:
                var tapped: int = _pick(event.position)
                if tapped >= 0:
                    _select(tapped)
    elif event is InputEventScreenDrag:
        touch_seen = true
        if event.relative.length() > 1.0:
            touch_dragged = true
        pan += event.relative
        queue_redraw()
    if event is InputEventMouseButton and not touch_seen and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and gesture_travel < 9.0:
        var picked: int = _pick(event.position)
        if picked >= 0:
            _select(picked)

func _select(id: int) -> void:
    if inspected == id and _available(id) and points >= _cost(id):
        var branch: int = id / 48
        var value: float = 0.022 if _type(id) == 0 else (0.09 if _type(id) == 1 else 0.18)
        points -= _cost(id)
        owned[str(id)] = true
        mutation_unlocked.emit(id, STATS[branch], value, _cost(id))
    inspected = id
    queue_redraw()
