extends Control
class_name OriginiCellWorldGlyphs
## Vista tattile 2.5D: corpi biologici leggibili, ispirati al vecchio client web.
## World and genetics come from existing 3D simulation: this only draws it.
## Uses no network, texture downloads, generated images, or standalone state.
var cells: Array[Dictionary] = []
var sea_top: float = 415.0
var sea_bottom: float = 1100.0
var animation_time: float = 0.0
var vignette: bool = true

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(points: Array[Dictionary], top: float, bottom: float, viewport: Vector2, elapsed: float) -> void:
    cells = points
    sea_top = top
    sea_bottom = bottom
    size = viewport
    animation_time = elapsed
    queue_redraw()

func _ellipse(center: Vector2, radii: Vector2, color: Color, segments: int = 32) -> void:
    var polygon := PackedVector2Array()
    for i in range(segments):
        var theta: float = TAU*float(i)/float(segments)
        polygon.append(center+Vector2(cos(theta)*radii.x,sin(theta)*radii.y))
    draw_colored_polygon(polygon,color)

func _outline(center: Vector2, radii: Vector2, color: Color, width: float,
        phase: float = 0.0, irregular: float = .027) -> void:
    var outline := PackedVector2Array()
    for i in range(65):
        var a: float = TAU*float(i)/64.0
        var wave: float = 1.0+irregular*sin(a*5.0+phase)+irregular*.48*cos(a*7.0-phase*.67)
        outline.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y)*wave)
    draw_polyline(outline,color,width,true)

func _body_polygon(center: Vector2, radii: Vector2, phase: float,
        count: int = 64) -> PackedVector2Array:
    var outline := PackedVector2Array()
    for i in range(count):
        var a: float = TAU*float(i)/float(count)
        var wave: float = 1.0+.038*sin(a*5.0+phase)+.021*cos(a*7.0-phase*.73)
        outline.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y)*wave)
    return outline

func _sea_light() -> void:
    var w: float = size.x
    var top: float = sea_top
    var floor: float = sea_bottom
    if floor <= top:
        return
    # Deep teal translucent water, with very soft sunlight shafts.
    for i in range(8):
        var y: float = top+float(i)*(floor-top)/8.0
        var a: float = .035+float(i)*.010
        draw_rect(Rect2(0,y,w,(floor-top)/8.0+1.0),Color(.025,.16,.23,a))
    var shafts: Array[float] = [.12,.42,.73,.94]
    for i in range(shafts.size()):
        var x: float = w*shafts[i]
        var drift: float = sin(animation_time*.11+float(i)*1.2)*17.0
        var beam := PackedVector2Array([
            Vector2(x-9.0,top),Vector2(x+22.0,top),
            Vector2(x+88.0+drift,floor),Vector2(x-35.0+drift,floor)
        ])
        draw_colored_polygon(beam,Color(.12,.57,.65,.032 if i%2==0 else .047))
    for i in range(19):
        var fx: float = float((i*173+47)%661)/661.0*w
        var fy: float = top+float((i*311+109)%997)/997.0*(floor-top)
        var d: float = 1.0+float(i%4)*.45
        draw_circle(Vector2(fx,fy),d,Color(.46,.85,.85,.10))

func _cell(point: Dictionary) -> void:
    var pos: Vector2 = point.get("pos",Vector2.ZERO)
    var radius: float = float(point.get("radius",53.0))
    var selected: bool = bool(point.get("selected",false))
    var trait: Dictionary = point.get("traits",{})
    var branch: String = str(point.get("branch","pre_luca"))
    var color: Color = Color(.34,.79,.79)
    if branch == "archaea":
        color = Color(.40,.84,.71)
    elif branch == "bacteria":
        color = Color(.44,.77,.88)
    elif branch == "luca":
        color = Color(.69,.66,.88)
    var wobble: float = animation_time*.57+float(point.get("seed",0))*.61
    var base_radius: Vector2 = Vector2(radius*1.05,radius*.89)
    var elongation: float = clampf(float(trait.get("elongation",0.0)),0.0,.65)
    base_radius.x *= 1.0+elongation*.3
    base_radius.y *= 1.0-elongation*.12
    # Small ground contact shadow and water halo establish depth without
    # turning the cell into a plastic sphere.
    for j in range(4):
        var f: float = float(j)
        _ellipse(pos+Vector2(0,radius*.75),Vector2(radius*(1.24-f*.12),radius*(.44-f*.045)),
            Color(.0,.015,.035,.04))
    for j in range(3):
        draw_arc(pos,radius*(1.33+float(j)*.13),0,TAU,64,
            Color(.38,.90,.86,.080-float(j)*.022),1.2,true)
    if bool(trait.get("eps",false)):
        draw_arc(pos,base_radius.x*1.24,0,TAU,64,Color(.60,.91,.78,.38),2.8,true)

    var pili: int = mini(9,int(trait.get("pili",0)))
    for i in range(pili):
        var a: float = TAU*float(i)/float(maxi(pili,1))
        var start: Vector2 = pos+Vector2(cos(a)*base_radius.x,sin(a)*base_radius.y)
        var end: Vector2 = pos+Vector2(cos(a)*base_radius.x*1.42,sin(a)*base_radius.y*1.45)
        draw_line(start,end,Color(.63,.91,.75,.88),2.25,true)
        draw_circle(end,2.0,Color(.72,.98,.85,.82))

    # Organic closed membrane with a smooth soft upper highlight.
    var outer: PackedVector2Array = _body_polygon(pos,base_radius,wobble)
    draw_colored_polygon(outer,Color(.17,.43,.48,.98).lerp(color,.12))
    var middle: PackedVector2Array = _body_polygon(pos,base_radius*.91,wobble)
    draw_colored_polygon(middle,Color(.22,.56,.60,.93).lerp(color,.16))
    _ellipse(pos+Vector2(-radius*.13,radius*.14),base_radius*.65,
        Color(.20,.64,.64,.20))
    _outline(pos,base_radius,Color(.57,.98,.95,.98),3.3,wobble)
    _outline(pos,base_radius*1.08,Color(.43,.89,.88,.22),1.7,wobble)
    _ellipse(pos+Vector2(-radius*.35,-radius*.38),Vector2(radius*.23,radius*.15),
        Color(.88,1.0,.94,.25))
    _ellipse(pos+Vector2(-radius*.28,-radius*.34),Vector2(radius*.12,radius*.08),
        Color(.98,1.0,.96,.14))

    # Exactly ONE ssRNA until DNA stabilization. 2D projection of folded RNA;
    # not a pre-existing nucleus or mitochondrion.
    var dna: bool = bool(trait.get("dna",false))
    var points := PackedVector2Array()
    for i in range(51):
        var t: float = float(i)/50.0
        var x: float = (t-.5)*radius*.85+sin(t*TAU*2.65)*radius*.11
        var y: float = sin(t*TAU*1.48)*radius*.30+cos(t*TAU*2.25)*radius*.085
        points.append(pos+Vector2(x,y)+Vector2(0,radius*.065))
    draw_polyline(points,Color(.95,.62,.89) if not dna else Color(.83,.71,1.0),4.2,true)
    if dna:
        var pair := PackedVector2Array()
        for i in range(51):
            var t: float = float(i)/50.0
            pair.append(points[i]+Vector2(0,sin(t*TAU*1.8+PI)*radius*.16))
        draw_polyline(pair,Color(.58,.88,1.0,.93),2.7,true)
    for i in range(3):
        var phi: float = .35+float(i)*TAU/3.0
        var p: Vector2 = pos+Vector2(cos(phi)*radius*.35,sin(phi)*radius*.30)
        draw_circle(p,radius*.063,Color(.97,.94,.53))
        draw_circle(p+Vector2(-1.5,-1.8),radius*.018,Color(1,1,.83,.80))
    for i in range(7):
        var phi: float = float(i)*2.47+1.2
        var p: Vector2 = pos+Vector2(cos(phi)*radius*.59,sin(phi)*radius*.56)
        draw_circle(p,radius*.027,Color(.89,1.0,.81,.65))

    var receptors: int = mini(9,int(trait.get("receptors",0)))
    for i in range(receptors):
        var a: float = TAU*(float(i)+.27)/float(maxi(receptors,1))
        var p: Vector2 = pos+Vector2(cos(a)*base_radius.x*1.06,sin(a)*base_radius.y*1.07)
        draw_circle(p,radius*.05,Color(.91,.95,.65))
    var proteases: int = mini(7,int(trait.get("protease",0)))
    for i in range(proteases):
        var a: float = TAU*(float(i)+.63)/float(maxi(proteases,1))
        var p: Vector2 = pos+Vector2(cos(a)*base_radius.x*.97,sin(a)*base_radius.y*.96)
        draw_circle(p,radius*.065,Color(1.0,.69,.48))
    var vesicles: int = mini(6,int(trait.get("vesicles",0)))
    for i in range(vesicles):
        var a: float = TAU*(float(i)+.5)/float(maxi(vesicles,1))
        var p: Vector2 = pos+Vector2(cos(a)*base_radius.x*1.25,sin(a)*base_radius.y*1.25)
        draw_circle(p,radius*.13,Color(.40,.86,.83,.20))
        draw_arc(p,radius*.13,0,TAU,28,Color(.61,.97,.93,.75),1.4,true)
    if selected:
        draw_arc(pos,radius*1.48,PI*.11,PI*.89,40,Color(.64,.98,.95,.24),1.1,true)
        draw_arc(pos,radius*1.48,PI*1.11,PI*1.89,40,Color(.64,.98,.95,.24),1.1,true)

func _draw() -> void:
    if size.x < 10 or size.y < 10:
        return
    _sea_light()
    for point in cells:
        _cell(point)
