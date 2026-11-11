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
var inspected: int = -1

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
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.070, 0.095, 0.95))
    for branch in range(6):
        var tint: Color = COLORS[branch]
        var far := _screen(Vector2(cos(-PI * .5 + branch * TAU / 6.0), sin(-PI * .5 + branch * TAU / 6.0)) * 530)
        draw_line(_screen(Vector2.ZERO), far, Color(tint.r, tint.g, tint.b, 0.22), 5.0 * zoom_level, true)
        for local in range(48):
            var id: int = branch * 48 + local
            var p := _screen(_pos(id))
            var parent := _screen(Vector2.ZERO if local < 8 else _pos(id - 8))
            var linked: bool = owned.has(str(id))
            var edge_tint: Color = tint if linked else Color(0.24, 0.35, 0.39, 0.65)
            draw_line(parent, p, edge_tint, (2.8 if linked else 1.35) * zoom_level, true)
    for branch in range(6):
        for local in range(48):
            var id: int = branch * 48 + local
            var at := _screen(_pos(id))
            var tint: Color = COLORS[branch]
            var unlocked: bool = owned.has(str(id))
            var accessible: bool = _available(id)
            var rt: float = (6.0 if _type(id) == 0 else (10.0 if _type(id) == 1 else 16.0)) * zoom_level
            if id == inspected:
                draw_circle(at, rt + 8.0 * zoom_level, Color(1.0, 1.0, 1.0, 0.19))
            draw_circle(at, rt + 2.5 * zoom_level, tint if unlocked else (Color(0.4, 0.57, 0.61) if accessible else Color(0.20, 0.30, 0.34)))
            draw_circle(at, rt, tint.darkened(0.58) if unlocked else Color(0.04, 0.13, 0.17))
            if _type(id) >= 1:
                var glyph: String = [">", "!", "+", "*", "~", "o"][branch]
                draw_string(ThemeDB.fallback_font, at + Vector2(-4, 5) * zoom_level, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * zoom_level), Color.WHITE if unlocked else Color(0.65, 0.75, 0.76))
    draw_circle(_screen(Vector2.ZERO), 31 * zoom_level, Color(0.34, 0.81, 0.75, 0.75))
    draw_circle(_screen(Vector2.ZERO), 24 * zoom_level, Color(0.12, 0.35, 0.44))
    draw_string(ThemeDB.fallback_font, _screen(Vector2.ZERO) + Vector2(-25, 4) * zoom_level, "ORIGINE", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * zoom_level), Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(16, 28), "ALBERO DELLE MUTAZIONI  ·  288 nodi", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.89, 0.97, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(16, 55), "Punti evolutivi: %d   |   trascina / zoom con rotella" % points, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.62, 0.86, 0.88))
    if inspected >= 0:
        var branch: int = inspected / 48
        var kind: int = _type(inspected)
        var name: String = "Mutazione puntiforme" if kind == 0 else ("Mutazione notevole" if kind == 1 else "Specializzazione maggiore")
        draw_rect(Rect2(12, size.y - 90, size.x - 24, 77), Color(0.04, 0.17, 0.22, 0.97))
        draw_string(ThemeDB.fallback_font, Vector2(26, size.y - 61), "%s — %s" % [BRANCHES[branch], name], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, COLORS[branch])
        draw_string(ThemeDB.fallback_font, Vector2(26, size.y - 31), "Costo: %d   |   %s   |   Tocca di nuovo per sbloccare" % [_cost(inspected), "Disponibile" if _available(inspected) else "Bloccato / acquisito"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

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
