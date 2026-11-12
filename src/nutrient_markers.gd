extends Control
class_name OriginiNutrientMarkers
## Simple 2D nutrient glyphs projected from the REAL 3D world.
## Mirrors the readable chemical silhouettes of the original JS prototype.
## No runtime WebView or opaque sprite sheets.
var markers: Array[Dictionary] = []
var top_limit: float = 390.0
var bottom_limit: float = 1000.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(points: Array[Dictionary], top: float, bottom: float, viewport: Vector2) -> void:
    markers = points
    top_limit = top
    bottom_limit = bottom
    size = viewport
    queue_redraw()

func _text(at: Vector2, value: String, font_size: int, tint: Color) -> void:
    draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,tint)

func _hexagon(center: Vector2, radius: float, color: Color) -> void:
    var ring := PackedVector2Array()
    for i in range(7):
        var a: float = -PI*.5+float(i)*TAU/6.0
        ring.append(center+Vector2(cos(a),sin(a))*radius)
    draw_polyline(ring,color,2.1,true)

func _pentagon(center: Vector2, radius: float, color: Color) -> void:
    var vertices := PackedVector2Array()
    for i in range(6):
        var a: float = -PI*.5+float(i)*TAU/5.0
        vertices.append(center+Vector2(cos(a),sin(a))*radius)
    draw_polyline(vertices,color,2.0,true)

func _draw() -> void:
    for m in markers:
        var position: Vector2 = m["pos"]
        if position.y < top_limit or position.y > bottom_limit:
            continue
        if position.x < 13 or position.x > size.x-13:
            continue
        # Avoid covering contextual action buttons at the bottom corners.
        if position.y > size.y-404 and (position.x < 184 or position.x > size.x-184):
            continue
        var kind: String = str(m.get("kind","carbon"))
        var r: float = clampf(float(m.get("scale",1.0))*14.5,11.0,16.0)
        var c: Color
        match kind:
            "carbon":
                c = Color(.98,.81,.45,.91)
                _hexagon(position,r,c)
                draw_circle(position,r*.65,Color(.33,.28,.13,.65))
                _text(position+Vector2(-4,5),"C",14,c)
            "amino":
                c = Color(.64,.91,.62,.93)
                draw_line(position+Vector2(-r,0),position+Vector2(r,0),c,2.3,true)
                draw_line(position,position+Vector2(0,-r*.63),c,2.3,true)
                draw_circle(position,r*.52,c)
                draw_circle(position+Vector2(-r,0),r*.32,c)
                draw_circle(position+Vector2(r,0),r*.32,c)
                _text(position+Vector2(-r-5,-r*.6),"N",10,c)
                _text(position+Vector2(r*.6,-r*.6),"C",10,c)
            "lipid":
                c = Color(1.0,.72,.37,.96)
                var coords := PackedVector2Array([
                    position+Vector2(-r*1.2,-r*.45),
                    position+Vector2(-r*.58,r*.15),
                    position+Vector2(-r*.15,-r*.52),
                    position+Vector2(r*.4,r*.13),
                    position+Vector2(r*.95,-r*.52)
                ])
                draw_polyline(coords,c,3.5,true)
                draw_circle(position+Vector2(-r*1.25,-r*.48),r*.42,c)
            "nucleic":
                c = Color(.85,.58,.93,.93)
                _pentagon(position,r,c)
                draw_circle(position+Vector2(-r*1.15,r*.45),r*.30,c)
                _text(position+Vector2(r*.35,r*.48),"N",10,c)
            "detritus":
                c = Color(.80,.53,.40,.65)
                draw_line(position+Vector2(-r,-r*.6),position+Vector2(r*.3,r*.7),c,2.0,true)
                draw_circle(position+Vector2(r*.4,-r*.55),r*.35,c)
