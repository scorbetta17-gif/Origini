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
var zoom_level: float = .85
var pan: Vector2 = Vector2.ZERO
var last_pointer: Vector2 = Vector2.ZERO
var dragging: bool = false
var gesture_travel: float = 0.0
var touch_dragged: bool = false
var touch_seen: bool = false
var inspected: int = 0
var source_traits: Dictionary = {}
const Balance = preload("res://src/mutation_balance.gd")
var cell_generation: int = 0
const GenomeScript = preload("res://src/cell_genome.gd")
# Eight explicit, heritable gene milestones per category, rather than a
# misleading big passive node with no genotype.
const MAJOR_LOCUS_BY_BRANCH := [
    ["pili_twitch","cell_elongation","surface_recognition","membrane_transport","pili_twitch","cell_elongation","surface_recognition","membrane_transport"],
    ["hydrolase_secretion","surface_recognition","vesicle_pathway","hydrolase_secretion","vesicle_pathway","surface_recognition","hydrolase_secretion","vesicle_pathway"],
    ["eps_biosynthesis","thermal_membrane","chaperone_complex","cell_elongation","thermal_membrane","chaperone_complex","eps_biosynthesis","thermal_membrane"],
    ["surface_recognition","vesicle_pathway","membrane_transport","chaperone_complex","thermal_membrane","surface_recognition","vesicle_pathway","membrane_transport"],
    ["membrane_transport","chaperone_complex","thermal_membrane","vesicle_pathway","chaperone_complex","membrane_transport","thermal_membrane","vesicle_pathway"],
    ["membrane_transport","vesicle_pathway","surface_recognition","pili_twitch","vesicle_pathway","membrane_transport","surface_recognition","pili_twitch"]
]

func configure(data: Dictionary, available_points: int, genome_traits: Dictionary = {}, generation: int = 0) -> void:
    clip_contents = true
    cell_generation = generation
    owned = data.duplicate(true)
    points = available_points
    source_traits = genome_traits.duplicate(true)
    queue_redraw()

func _cluster(branch: int, cluster: int) -> Vector2:
    var axis := Vector2.from_angle(-PI*.5+branch*TAU/6.0)
    var side := Vector2(-axis.y,axis.x)
    return axis*(240.0+(cluster/2)*190.0)+side*((-1.0 if cluster%2==0 else 1.0)*(60.0+(cluster/2)*32.0))

func _pos(node_id: int) -> Vector2:
    var branch: int = node_id/48
    var local: int = node_id%48
    var cluster: int = local%8
    var center: Vector2 = _cluster(branch,cluster)
    if local>=40: return center
    var stage: int = local/8
    var angle: float = -PI*.5+branch*TAU/6.0+PI+stage*TAU/5.0
    return center+Vector2.from_angle(angle)*45.0

func _parent_id(id: int) -> int:
    var local: int = id%48
    var cluster: int = local%8
    if local>=40: return id-8
    if local>=8: return id-8
    return -1 if cluster<2 else id/48*48+40+cluster-2

func _cluster_points(id: int) -> int:
    var total: int = 0
    for stage in range(5):
        if owned.has(str(id/48*48+stage*8+id%8)): total+=1
    return total

func _screen(world_pos: Vector2) -> Vector2:
    return size * 0.5 + pan + world_pos * zoom_level

func _type(node_id: int) -> int:
    return 2 if node_id%48>=40 else 0

func major_locus(node_id: int) -> String:
    if _type(node_id) != 2:
        return ""
    var branch: int = node_id / 48
    var lane: int = node_id % 8
    return MAJOR_LOCUS_BY_BRANCH[branch][lane]

func _draw_major_icon(center: Vector2, radius: float, locus: String, tint: Color) -> void:
    # Shared vector style: pale ink, rounded arcs, phenotype-specific pictograms.
    var r: float = maxf(6.0,radius*.72)
    var ink: Color = tint.lightened(.48)
    var width: float = maxf(1.5,r*.15)
    match locus:
        "pili_twitch":
            draw_arc(center,r*.35,0,TAU,20,ink,width,true)
            for i in range(5):
                var n := Vector2.from_angle(TAU*i/5.0)
                draw_line(center+n*r*.4,center+n*r,ink,width,true)
        "cell_elongation":
            draw_arc(center-Vector2(r*.38,0),r*.44,PI*.5,PI*1.5,16,ink,width,true)
            draw_arc(center+Vector2(r*.38,0),r*.44,-PI*.5,PI*.5,16,ink,width,true)
            for sign_value in [-1,1]:
                draw_line(center+Vector2(-r*.38,r*.44*sign_value),center+Vector2(r*.38,r*.44*sign_value),ink,width,true)
        "surface_recognition":
            draw_line(center+Vector2(0,r*.8),center,ink,width,true)
            draw_line(center,center+Vector2(-r*.65,-r*.65),ink,width,true)
            draw_line(center,center+Vector2(r*.65,-r*.65),ink,width,true)
            draw_circle(center+Vector2(0,-r*.8),r*.16,ink)
        "membrane_transport":
            for x in [-.55,.55]:
                draw_line(center+Vector2(r*x,-r*.7),center+Vector2(r*x,r*.7),ink,width,true)
            draw_line(center+Vector2(-r*.25,0),center+Vector2(r*.25,0),ink,width,true)
            draw_circle(center+Vector2(0,-r*.7),r*.19,ink)
            draw_circle(center+Vector2(0,r*.7),r*.13,ink)
        "hydrolase_secretion":
            var contour := PackedVector2Array()
            for i in range(7):
                contour.append(center+Vector2.from_angle(TAU*i/6.0)*r*.75)
            draw_polyline(contour,ink,width,true)
            draw_line(center+Vector2(-r*.35,r*.15),center,ink,width,true)
            draw_line(center,center+Vector2(r*.35,-r*.15),ink,width,true)
        "vesicle_pathway":
            draw_arc(center-Vector2(r*.23,r*.08),r*.58,0,TAU,24,ink,width,true)
            draw_arc(center+Vector2(r*.62,-r*.50),r*.26,0,TAU,16,ink,width,true)
        "eps_biosynthesis":
            draw_arc(center,r*.40,0,TAU,20,ink,width,true)
            for i in range(10):
                draw_circle(center+Vector2.from_angle(TAU*i/10.0)*r*.82,r*.105,ink)
        "thermal_membrane":
            for y in [-.5,0,.5]:
                var line := PackedVector2Array()
                for i in range(17):
                    var u: float = float(i)/16.0
                    line.append(center+Vector2((u-.5)*r*1.6,r*y+sin(u*TAU)*r*.14))
                draw_polyline(line,ink,width,true)
        "chaperone_complex":
            for i in range(6):
                draw_circle(center+Vector2.from_angle(TAU*i/6.0)*r*.56,r*.23,ink)
            draw_circle(center,r*.23,tint.darkened(.4))

func _cost(node_id: int) -> int:
    return 2 if _type(node_id)==2 else 1

func point_count(branch: int) -> int:
    var count: int = 0
    for i in range(40):
        if owned.has(str(branch*48+i)):
            count += 1
    return count

func major_count(branch: int) -> int:
    var count: int = 0
    for i in range(40,48):
        if owned.has(str(branch*48+i)):
            count += 1
    return count

func _available(node_id: int) -> bool:
    if node_id<0 or node_id>=288 or owned.has(str(node_id)):
        return false
    if _type(node_id)!=2:
        var parent: int = _parent_id(node_id)
        return parent<0 or owned.has(str(parent))
    var locus: String = major_locus(node_id)
    if GenomeScript.allele(source_traits,locus)>=int(GenomeScript.GENE_INFO[locus]["max"]):
        return false
    # Deliberate introductory exception: two points from the first division.
    if node_id==88 and cell_generation>=1 and not GenomeScript.has(source_traits,"hydrolase_secretion"):
        return true
    var branch: int = node_id/48
    return _cluster_points(node_id)>=Balance.POINTS_PER_MAJOR

func focus_node(id: int) -> void:
    inspected = clampi(id,0,287)
    pan = -_pos(inspected)*zoom_level
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color(.011,.061,.085,.99))
    var center: Vector2 = _screen(Vector2.ZERO)
    # Draw the same edges that govern purchases; original biology-themed artwork.
    for id in range(288):
        var parent: int = _parent_id(id)
        var start: Vector2 = center if parent<0 else _screen(_pos(parent))
        var finish: Vector2 = _screen(_pos(id))
        var tint: Color = COLORS[id/48]
        var lit: bool = owned.has(str(id))
        draw_line(start,finish,tint.darkened(.28) if lit else Color(.15,.27,.29),3.2*zoom_level,true)
        if lit: draw_line(start,finish,tint.lightened(.20),1.1*zoom_level,true)
    for branch in range(6):
        for cluster in range(8):
            draw_arc(_screen(_cluster(branch,cluster)),45.0*zoom_level,0,TAU,48,Color(.17,.30,.32,.45),1.0,true)
        for local in range(48):
            var id: int = branch*48+local
            var at: Vector2 = _screen(_pos(id))
            var color: Color = COLORS[branch]
            var active: bool = owned.has(str(id))
            var ready: bool = _available(id)
            var radius: float = (5.8 if _type(id) == 0 else (9.1 if _type(id) == 1 else 16.2))*zoom_level
            if id == inspected:
                draw_circle(at,radius+8.0*zoom_level,Color(1.0,.92,.64,.30))
                draw_arc(at,radius+6.0*zoom_level,0,TAU,40,Color(1.0,.96,.73),2.2,true)
            draw_circle(at,radius+1.3*zoom_level,
                color if active else (color.darkened(.11) if ready else Color(.22,.39,.44,.76)))
            draw_circle(at,radius*.70,color.darkened(.42) if active else Color(.035,.13,.17))
            if _type(id) == 2:
                draw_arc(at,radius+2.2*zoom_level,0,TAU,28,
                    color.lightened(.42) if active else Color(.45,.64,.65,.90),1.6*zoom_level,true)
                _draw_major_icon(at,radius,major_locus(id),color if ready or active else Color(.31,.48,.50))
    draw_circle(center,26*zoom_level,Color(.42,.87,.78))
    draw_circle(center,18*zoom_level,Color(.13,.38,.42))
    draw_arc(center,23*zoom_level,0,TAU,48,Color(.68,.94,.88),1.6,true)
    var rna := PackedVector2Array()
    for i in range(25):
        var u: float = float(i)/24.0
        rna.append(center+Vector2((u-.5)*25,sin(u*TAU*1.4)*6)*zoom_level)
    draw_polyline(rna,Color(1,.59,.22),2.2*zoom_level,true)

    # Classic mobile visual hierarchy: six stat cards and branch selector.
    draw_rect(Rect2(0,0,size.x,165),Color(.015,.088,.115,.985))
    draw_line(Vector2(0,165),Vector2(size.x,165),Color(.21,.51,.56,.71),2,true)
    draw_string(ThemeDB.fallback_font,Vector2(16,27),
        "ALBERO EVOLUTIVO",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(.94,.99,.99))
    draw_string(ThemeDB.fallback_font,Vector2(16,51),
        "240 puntiformi + 48 scelte maggiori · %d acquisite · %d punti" % [owned.size(),points],
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
            "OTTIMIZZAZIONE" if kind == 1 else "MUTAZIONE MAGGIORE · GENE")
        var affordable: bool = _available(inspected) and points >= _cost(inspected)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-141),
            "%s · %s" % [BRANCHES[branch],title],HORIZONTAL_ALIGNMENT_LEFT,-1,17,COLORS[branch],size.x-34)
        var preview: Dictionary = Balance.tree_effect(source_traits,STATS[branch],kind==2)
        var gain: float = float(preview[STATS[branch]])-float(source_traits.get(STATS[branch],0.0 if branch==3 else 1.0))
        var genetic_name: String = ""
        if kind == 2:
            var locus: String = major_locus(inspected)
            genetic_name = str(GenomeScript.GENE_INFO[locus]["name"])
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-113),
            ("GENE: "+genetic_name+" · +%.1f%% · %d P" % [gain*100.0,_cost(inspected)]) if kind == 2 else (
                "Effetto: +%.1f%% %s  ·  Costo %d punti" % [
                    gain*100.0,
                    BRANCHES[branch],_cost(inspected)]),
            HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.88,.96,.96),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-87),
            ("Fenotipo + bonus; -1,2 punti % "+str(Balance.TRADEOFF[STATS[branch]]) if kind == 2
                else "Bonus decrescente; -0,4 punti % "+str(Balance.TRADEOFF[STATS[branch]])),
            HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.65,.86,.87),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-60),
            "TOCCA ANCORA PER ACQUISTARE" if affordable else "Servono puntiformi, punti o il locus e gia al massimo",
            HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.57,.92,.77) if affordable else Color(.95,.77,.59),size.x-34)
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-32),
            ("Enzimi iniziali: GEN 1 · 2 punti" if inspected==88 else "Puntiformi del cluster: %d / %d per la maggiore" % [_cluster_points(inspected),5]),
            HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.69,.79,.88),size.x-34)
    else:
        draw_string(ThemeDB.fallback_font,Vector2(17,size.y-120),
            "Tocca un nodo per esaminarne l'effetto",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.90,.96,.96))

func zoom_by(factor: float) -> void:
    zoom_level = clampf(zoom_level*factor,.25,3.0)
    queue_redraw()

func center_view() -> void:
    zoom_level = .85
    pan = Vector2.ZERO
    queue_redraw()

func inspect_branch(branch: int) -> void:
    zoom_level = 1.22
    focus_node(clampi(branch,0,5)*48+40)

func _pick(at: Vector2) -> int:
    var best: int = -1
    var distance: float = 999.0
    for i in range(288):
        var d: float = at.distance_to(_screen(_pos(i)))
        if d < maxf(24.0,25.0*zoom_level) and d < distance:
            best = i
            distance = d
    return best

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and not touch_seen:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom_level = minf(3.0, zoom_level * 1.12)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom_level = maxf(.25, zoom_level / 1.12)
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
        if event.position.y>=130 and event.position.y<=162:
            inspect_branch(clampi(int((event.position.x-10)*6/maxf(1,size.x-20)),0,5))
            return
        if event.position.y<170 or event.position.y>=size.y-176: return
        var picked: int = _pick(event.position)
        if picked >= 0:
            _select(picked)

func _select(id: int) -> void:
    if inspected == id and _available(id) and points >= _cost(id):
        var branch: int = id / 48
        var value: float = Balance.MAJOR_GAIN if _type(id)==2 else Balance.MINOR_GAIN
        points -= _cost(id)
        owned[str(id)] = true
        mutation_unlocked.emit(id, STATS[branch], value, _cost(id))
    inspected = id
    queue_redraw()
