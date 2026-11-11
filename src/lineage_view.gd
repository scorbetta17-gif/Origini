extends Control
class_name LineageView
## Un'unica mappa genealogica. La divisione non e' una morte; nessun genitore sparisce.
## Le radici esterne non sono connesse per errore alla cellula progenitrice.
signal lineage_requested(lineage_id: String)

var records: Array = []
var controlled_id: String = ""
var by_id: Dictionary = {}
var children: Dictionary = {}
var locations: Dictionary = {}
var next_slot: int = 0
var pan: Vector2 = Vector2.ZERO
var zoom: float = .95
var dragging: bool = false
var touched: bool = false
var touch_dragged: bool = false
var travel: float = 0.0
var previous: Vector2 = Vector2.ZERO
var inspected: String = ""

func configure(history: Array, current: String) -> void:
    records = history.duplicate(true)
    controlled_id = current
    _recalculate()
    queue_redraw()

func _recalculate() -> void:
    by_id.clear()
    children.clear()
    locations.clear()
    next_slot = 0
    for r in records:
        var id: String = str(r.get("id",""))
        if id == "" or by_id.has(id):
            continue
        by_id[id] = r
        children[id] = []
    var roots: Array = []
    for r in records:
        var id: String = str(r.get("id",""))
        if not by_id.has(id):
            continue
        var parent: String = str(r.get("parent",""))
        if parent == "" or not by_id.has(parent):
            if not roots.has(id):
                roots.append(id)
        elif not children[parent].has(id):
            children[parent].append(id)
    # Assegna ai figli posti adiacenti; il genitore compare sopra il gruppo.
    var visiting: Dictionary = {}
    for root in roots:
        _layout_branch(str(root),0,visiting)
        next_slot += 1
    for id in by_id:
        if not locations.has(id):
            _layout_branch(str(id),0,visiting)

func _layout_branch(id: String, depth: int, visiting: Dictionary) -> float:
    if locations.has(id):
        return float(locations[id].x)
    if visiting.has(id):
        return float(next_slot)*162.0
    visiting[id] = true
    var desc: Array = children.get(id,[])
    var x: float = 0.0
    if desc.is_empty():
        x = float(next_slot)*162.0
        next_slot += 1
    else:
        var min_x: float = INF
        var max_x: float = -INF
        for child in desc:
            var child_x: float = _layout_branch(str(child),depth+1,visiting)
            min_x = minf(min_x,child_x)
            max_x = maxf(max_x,child_x)
        x = (min_x+max_x)*.5
    locations[id] = Vector2(x,float(depth)*126.0)
    visiting.erase(id)
    return x

func _screen(point: Vector2) -> Vector2:
    var center: float = 0.0
    if next_slot > 0:
        center = (float(next_slot-1)*162.0)*.5
    return Vector2(size.x*.5,95.0)+pan+(point-Vector2(center,0))*zoom

func _color(line: String) -> Color:
    if line == "bacteria":
        return Color(.97,.64,.36)
    if line == "archaea":
        return Color(.42,.88,.73)
    if line == "luca":
        return Color(.70,.62,.97)
    return Color(.44,.82,.89)

func _portrait(center: Vector2, r: Dictionary, factor: float) -> void:
    var tint: Color = _color(str(r.get("branch","pre_luca")))
    var tr: Dictionary = r.get("traits",{})
    var r_x: float = 15.0*factor
    var r_y: float = 12.0*factor
    # La forma nell'albero segue il medesimo locus strutturale del modello 3D.
    r_x *= 1.0+clampf(float(tr.get("elongation",0.0))*.36,0.0,.44)
    var ellipse: PackedVector2Array = PackedVector2Array()
    for j in range(25):
        var a: float = TAU*float(j)/24.0
        ellipse.append(center+Vector2(cos(a)*r_x,sin(a)*r_y))
    draw_colored_polygon(ellipse,tint.darkened(.27))
    draw_polyline(ellipse,tint.lightened(.35),1.4*factor,true)
    # Una traccia RNA oppure la doppia elica semplificata del DNA.
    var previous: Vector2 = center+Vector2(-r_x*.62,0)
    for j in range(1,15):
        var u: float = float(j)/14.0
        var current: Vector2 = center+Vector2((u-.5)*r_x*1.24,sin(u*TAU*1.5)*r_y*.33)
        draw_line(previous,current,Color(.98,.63,.80) if not bool(tr.get("dna",false)) else Color(.70,.82,1.0),1.5*factor,true)
        previous = current
    var motor: int = int(tr.get("archaella",0))+int(tr.get("flagella",0))
    for j in range(mini(5,motor)):
        var pos: Vector2 = center+Vector2(-r_x*.8,(-2.0+float(j))*r_y*.23)
        draw_line(pos,pos+Vector2(-12.0*factor,(-2.0+float(j))*2.2*factor),Color(.58,.94,.96),1.2*factor,true)
    # Le appendici visibili sono solo quelle espresse dai loci ereditabili.
    var pili: int = mini(7,int(tr.get("pili",0)))
    for j in range(pili):
        var a: float = TAU*float(j)/float(maxi(1,pili))
        var start: Vector2 = center+Vector2(cos(a)*r_x,sin(a)*r_y)
        draw_line(start,start+Vector2(cos(a)*9.0,sin(a)*9.0)*factor,Color(.71,.82,.69),1.2*factor,true)
    var receptors: int = mini(7,int(tr.get("receptors",0)))
    for j in range(receptors):
        var a: float = TAU*(float(j)+.5)/float(maxi(1,receptors))
        var tip: Vector2 = center+Vector2(cos(a)*(r_x+3.0),sin(a)*(r_y+3.0))
        draw_circle(tip,1.9*factor,Color(.75,.90,.76))
    if bool(tr.get("eps",false)):
        draw_arc(center,r_x+3.0,0,TAU,32,Color(.58,1.0,.8,.65),1.7*factor,true)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(.009,.045,.065,.99))
    draw_string(ThemeDB.fallback_font,Vector2(14,27),"LINEE EVOLUTIVE  ·  genealogia cellulare",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(.88,.98,.97))
    draw_string(ThemeDB.fallback_font,Vector2(14,53),"%d nodi | Trascina per spostarti | Tocca per ispezionare" % by_id.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.65,.85,.88))
    for id in locations:
        var record: Dictionary = by_id[id]
        var parent: String = str(record.get("parent",""))
        if not locations.has(parent):
            continue
        var a: Vector2 = _screen(locations[parent])
        var b: Vector2 = _screen(locations[id])
        var mid_y: float = (a.y+b.y)*.5
        var tint: Color = _color(str(record.get("branch","pre_luca")))
        draw_polyline(PackedVector2Array([a+Vector2(0,27*zoom),Vector2(a.x,mid_y),Vector2(b.x,mid_y),b-Vector2(0,27*zoom)]),Color(tint.r,tint.g,tint.b,.61),maxf(1.0,1.7*zoom),true)
    for id in locations:
        var r: Dictionary = by_id[id]
        var p: Vector2 = _screen(locations[id])
        if p.x < -130 or p.x > size.x+130 or p.y < 60 or p.y > size.y+110:
            continue
        var alive: bool = bool(r.get("alive",true))
        var status: String = str(r.get("status","viva"))
        var tint: Color = _color(str(r.get("branch","pre_luca")))
        if not alive:
            tint = tint.darkened(.24 if status == "divisa" else .53)
        var half: Vector2 = Vector2(67,32)*zoom
        var rect: Rect2 = Rect2(p-half,half*2)
        draw_rect(rect,Color(.045,.14,.19,.96),true)
        draw_rect(rect,Color(1,.96,.57) if id == controlled_id else tint,false,2.5 if id == controlled_id else 1.4)
        _portrait(p+Vector2(-36*zoom,-4*zoom),r,zoom)
        draw_string(ThemeDB.fallback_font,p+Vector2(-13,0)*zoom,str(r.get("name",id)).substr(0,11),HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(9,int(12*zoom)),Color(.95,.98,.96))
        var label: String = status if not alive else "VIVA"
        draw_string(ThemeDB.fallback_font,p+Vector2(-13,18)*zoom,label,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(8,int(9*zoom)),tint)
        if id == inspected:
            draw_arc(p,half.x+6,0,TAU,52,Color(.96,.98,.61,.95),2.0,true)
    if inspected != "" and by_id.has(inspected):
        var rec: Dictionary = by_id[inspected]
        draw_rect(Rect2(9,size.y-101,size.x-18,94),Color(.03,.13,.18,.99),true)
        var info: String = "%s · %s · gen %d" % [inspected,str(rec.get("branch","")),int(rec.get("generation",0))]
        var relation: String = "Origine indipendente" if str(rec.get("parent","")) == "" else "Genitore: %s" % str(rec.get("parent",""))
        var state: String = "VIVA · tocca di nuovo per seguirla" if bool(rec.get("alive",true)) else "STORICA · %s" % str(rec.get("cause","scissione"))
        var phenotype: Dictionary = rec.get("traits",{})
        var genome: Dictionary = phenotype.get("genome",{})
        var loci: Dictionary = genome.get("loci",{})
        var genetics: String = "Genotipo: %d loci · varianti numeriche: %d" % [loci.size(),phenotype.get("mutations",[]).size()]
        draw_string(ThemeDB.fallback_font,Vector2(18,size.y-76),info,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.87,1,.97))
        draw_string(ThemeDB.fallback_font,Vector2(18,size.y-54),genetics,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.73,.88,.82))
        draw_string(ThemeDB.fallback_font,Vector2(18,size.y-31),relation+"  ·  "+state,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.65,.87,.91))

func _pick(pos: Vector2) -> String:
    var closest: String = ""
    var distance: float = INF
    for id in locations:
        var p: Vector2 = _screen(locations[id])
        var d: float = pos.distance_to(p)
        if d < maxf(35.0,66.0*zoom) and d < distance:
            distance = d
            closest = str(id)
    return closest

func _tap(p: Vector2) -> void:
    var id: String = _pick(p)
    if id == "" or not by_id.has(id):
        return
    if inspected == id and bool(by_id[id].get("alive",true)):
        lineage_requested.emit(id)
    else:
        inspected = id
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        touched = true
        if event.pressed:
            dragging = true
            touch_dragged = false
            travel = 0.0
            previous = event.position
        else:
            dragging = false
            if not touch_dragged and travel < 10.0:
                _tap(event.position)
        accept_event()
    elif event is InputEventScreenDrag:
        touched = true
        if dragging:
            pan += event.position-previous
            travel += event.position.distance_to(previous)
            previous = event.position
            touch_dragged = touch_dragged or travel > 10.0
            queue_redraw()
        accept_event()
    elif event is InputEventMouseButton and not touched:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom = minf(1.8,zoom*1.14)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom = maxf(.43,zoom/1.14)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed
            if event.pressed:
                travel = 0.0
                previous = event.position
            elif travel < 10.0:
                _tap(event.position)
        queue_redraw()
        accept_event()
    elif event is InputEventMouseMotion and dragging and not touched:
        pan += event.position-previous
        travel += event.position.distance_to(previous)
        previous = event.position
        queue_redraw()
        accept_event()
