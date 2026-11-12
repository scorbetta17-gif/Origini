extends Control
class_name OriginiNutrientMarkers
## Marker chimici VETTORIALI nella vera scena isometrica Godot.
## Il carbonio rappresenta carboidrati semplici (due anelli tipo zucchero),
## i lipidi un fosfolipide, gli AA una formula generica e i nucleotidi
## fosfato + pentoso + base azotata; non molecole atomistiche esatte.
## Tutti i marker sono +10% di dimensione rispetto al gameplay 0.74.
var markers: Array[Dictionary] = []
var top_limit: float = 390.0
var bottom_limit: float = 1000.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(points: Array[Dictionary], top: float, bottom: float,
        viewport: Vector2) -> void:
    markers = points
    top_limit = top
    bottom_limit = bottom
    size = viewport
    queue_redraw()

func _text(at: Vector2, message: String, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _ring(center: Vector2, radius: float, sides: int, color: Color,
        width: float = 2.4, rotation: float = -.25) -> void:
    var line := PackedVector2Array()
    for i in range(sides+1):
        var angle: float = TAU*float(i)/float(sides)+rotation
        line.append(center+Vector2(cos(angle),sin(angle))*radius)
    draw_polyline(line,color,width,true)

func _bond(a: Vector2, b: Vector2, color: Color, width: float = 2.3) -> void:
    draw_line(a,b,color,width,true)

func _glow(center: Vector2, radius: float, color: Color) -> void:
    draw_circle(center,radius*1.68,Color(color.r,color.g,color.b,.055))
    draw_circle(center,radius*1.19,Color(color.r,color.g,color.b,.067))

func _carbon_sugar_dimer(at: Vector2, r: float) -> void:
    var amber := Color(.99,.80,.40,.98)
    var pale := Color(1.0,.94,.67,.99)
    var oxygen := Color(.68,.92,.93,.99)
    _glow(at,r,amber)
    var left: Vector2 = at+Vector2(-r*.72,.15*r)
    var right: Vector2 = at+Vector2(r*.72,-.13*r)
    _ring(left,r*.66,6,amber,2.9,-PI/6.0)
    _ring(right,r*.66,6,amber,2.9,-PI/6.0)
    _bond(left+Vector2(r*.57,0),right-Vector2(r*.57,0),oxygen,2.5)
    draw_circle(at,r*.16,oxygen)
    # Hydroxyl-like side groups: stylized oxygen and hydroxyls.
    _bond(left+Vector2(-r*.46,-r*.5),left+Vector2(-r*.63,-r*.80),amber,2)
    _bond(right+Vector2(r*.43,r*.50),right+Vector2(r*.55,r*.82),amber,2)
    draw_circle(left+Vector2(-r*.66,-r*.82),r*.11,pale)
    draw_circle(right+Vector2(r*.57,r*.85),r*.11,pale)

func _amino_acid(at: Vector2, r: float) -> void:
    var bright := Color(.62,.96,.70,.99)
    var nitrogen := Color(.43,.80,1.0,.98)
    var oxygen := Color(1.0,.66,.70,.98)
    _glow(at,r,bright)
    var central: Vector2 = at+Vector2(0,.05*r)
    var n: Vector2 = at+Vector2(-r*.85,-r*.37)
    var carboxy: Vector2 = at+Vector2(r*.85,-r*.25)
    var radical: Vector2 = at+Vector2(.06*r,.99*r)
    _bond(n,central,bright,2.5)
    _bond(central,carboxy,bright,2.5)
    _bond(central,radical,bright,2.4)
    draw_circle(central,r*.25,bright)
    draw_circle(n,r*.22,nitrogen)
    draw_circle(carboxy,r*.22,oxygen)
    draw_circle(radical,r*.17,Color(.94,.90,.57,.98))
    _text(n+Vector2(-r*.39,-r*.34),"N",11,Color(.94,.99,1.0))
    _text(carboxy+Vector2(r*.14,-r*.38),"O",11,Color(1.0,.91,.93))
    _text(radical+Vector2(r*.18,r*.17),"R",10,bright)

func _phospholipid(at: Vector2, r: float) -> void:
    # Polar phosphate head, short glycerol junction and TWO hydrocarbon tails.
    var head_color := Color(.60,.90,1.0,.99)
    var lipid_color := Color(1.0,.79,.42,.98)
    _glow(at,r,lipid_color)
    var head: Vector2 = at+Vector2(0,-r*.63)
    draw_circle(head,r*.39,Color(.20,.54,.72,.93))
    _ring(head,r*.42,12,head_color,2.5)
    _text(head+Vector2(-r*.19,r*.19),"P",13,Color(.90,.98,1.0))
    var fork: Vector2 = at+Vector2(0,-r*.07)
    _bond(head+Vector2(0,r*.39),fork,head_color,2.5)
    for sign_value in [-1.0,1.0]:
        var x: float = sign_value*r*.28
        var chain := PackedVector2Array([
            fork, at+Vector2(x,r*.22),
            at+Vector2(x+sign_value*r*.10,r*.53),
            at+Vector2(x-sign_value*r*.07,r*.83),
            at+Vector2(x+sign_value*r*.08,r*1.12)
        ])
        draw_polyline(chain,lipid_color,3.3,true)
        draw_circle(chain[chain.size()-1],r*.10,lipid_color)

func _nucleotide(at: Vector2, r: float) -> void:
    var violet := Color(.87,.66,1.0,.98)
    var phosphate := Color(1.0,.76,.48,.98)
    var sugar := Color(.65,.85,1.0,.98)
    _glow(at,r,violet)
    var ribose: Vector2 = at+Vector2(-r*.15,r*.08)
    _ring(ribose,r*.53,5,sugar,2.7,-PI*.5)
    var p: Vector2 = at+Vector2(-r*.94,-r*.52)
    _bond(p,ribose+Vector2(-r*.38,-r*.20),sugar,2.4)
    draw_circle(p,r*.29,Color(.65,.37,.62,.98))
    _ring(p,r*.32,12,phosphate,2.4)
    _text(p+Vector2(-r*.20,r*.14),"P",11,phosphate)
    var base_center := at+Vector2(r*.85,-r*.23)
    _bond(ribose+Vector2(r*.44,-r*.21),base_center-Vector2(r*.25,0),violet,2.4)
    _ring(base_center,r*.39,6,violet,2.8,-PI/6.0)
    _text(base_center+Vector2(-r*.20,r*.20),"N",10,Color(1.0,.90,1.0))

func _detritus(at: Vector2, r: float) -> void:
    var orange := Color(.87,.57,.39,.92)
    _glow(at,r*.72,orange)
    _bond(at+Vector2(-r*.76,-r*.63),at+Vector2(r*.12,r*.37),orange,2.8)
    _bond(at+Vector2(-r*.14,r*.58),at+Vector2(r*.65,-r*.30),orange,2.5)
    draw_circle(at+Vector2(r*.58,-r*.68),r*.17,orange)
    draw_circle(at+Vector2(-r*.73,r*.52),r*.14,orange)

func _draw() -> void:
    for m in markers:
        var at: Vector2 = m["pos"]
        if at.y < top_limit or at.y > bottom_limit:
            continue
        if at.x < 18.0 or at.x > size.x-18.0:
            continue
        # Prevent molecule glyphs from covering lower action buttons.
        if at.y > size.y-404 and (at.x < 184 or at.x > size.x-184):
            continue
        var kind: String = str(m.get("kind","carbon"))
        var radius: float = clampf(float(m.get("scale",1.0))*14.5,12.0,20.5)
        match kind:
            "carbon":
                _carbon_sugar_dimer(at,radius)
            "amino":
                _amino_acid(at,radius)
            "lipid":
                _phospholipid(at,radius)
            "nucleic":
                _nucleotide(at,radius)
            "detritus":
                _detritus(at,radius)
