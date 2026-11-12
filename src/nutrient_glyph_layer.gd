extends Control
class_name NutrientGlyphLayer
## Overlay gameplay 2D coerente con ORIGINI 0.56 web.
## Icone proiettate ESATTAMENTE dai nutrienti reali del mondo 3D.
## Nessuna risorsa virtuale: raccolta, distanza e scissione rimangono in main.gd.

const CARBON = Color(.98,.76,.40,1)
const AMINO = Color(.61,.91,.56,1)
const LIPID = Color(.55,.89,.95,1)
const NUCLEIC = Color(.89,.58,.91,1)
const DETRITUS = Color(.93,.56,.65,1)
var view_camera: Camera3D
var source_nutrients: Array = []
var cutoff_top: float = 0.0
var seconds: float = 0.0

func setup(camera_node: Camera3D, nutrients: Array) -> void:
    view_camera = camera_node
    source_nutrients = nutrients
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(delta: float) -> void:
    if not visible:
        return
    seconds += minf(delta,.05)
    queue_redraw()

func _hexagon(radius: float, start: float = PI/6.0) -> PackedVector2Array:
    var poly := PackedVector2Array()
    for i in range(6):
        var a: float = start+TAU*float(i)/6.0
        poly.append(Vector2(cos(a),sin(a))*radius)
    return poly

func _outline_poly(poly: PackedVector2Array, color: Color, width: float) -> void:
    var p: PackedVector2Array = poly.duplicate()
    p.append(p[0])
    draw_polyline(p,color,width,true)

func _label(value: String, at: Vector2, px: int, tint: Color) -> void:
    draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func _carbon() -> void:
    var p: PackedVector2Array = _hexagon(14.0)
    draw_colored_polygon(p,Color(.41,.29,.12,.67))
    _outline_poly(p,CARBON,2.4)
    _label("C",Vector2(-5,5),14,Color(1,.92,.70))

func _amino() -> void:
    var coords: Array[Vector2] = [Vector2(-14,5),Vector2(-2,2),Vector2(12,5),Vector2(-2,-12)]
    for i in [0,2,3]:
        draw_line(coords[1],coords[i],Color(.51,.80,.49,.85),2.0,true)
    for i in range(coords.size()):
        draw_circle(coords[i],5.2 if i==1 else 4.2,Color(.42,.74,.40,.90))
        draw_arc(coords[i],4.7 if i==1 else 3.7,0,TAU,16,AMINO,1.6,true)
    _label("N",Vector2(-23,-12),10,Color(.81,.98,.71))
    _label("C",Vector2(17,-12),10,Color(.81,.98,.71))

func _lipid() -> void:
    var points: Array[Vector2] = [
        Vector2(-9,-8),Vector2(4,-10),Vector2(-16,3),
        Vector2(-2,4),Vector2(11,3),Vector2(2,14)]
    for pt in points:
        draw_circle(pt,8.7,Color(.25,.57,.66,.77))
        draw_arc(pt,8.7,0,TAU,25,LIPID,1.8,true)
    draw_circle(Vector2(-5,-4),4,Color(.70,.96,.96,.30))

func _nucleic() -> void:
    var ring := PackedVector2Array()
    for i in range(5):
        var a: float = -PI*.5+TAU*float(i)/5.0
        ring.append(Vector2(cos(a),sin(a))*11.0+Vector2(4,0))
    draw_colored_polygon(ring,Color(.41,.22,.50,.80))
    _outline_poly(ring,NUCLEIC,2.4)
    draw_circle(Vector2(-12,0),4.4,Color(.72,.40,.79,.95))
    _label("P",Vector2(-16,4),9,Color(1,.86,1))
    _label("N",Vector2(2,-16),9,Color(1,.79,1))

func _detritus() -> void:
    var path := PackedVector2Array([
        Vector2(-13,-6),Vector2(-7,-13),Vector2(6,-11),
        Vector2(15,-4),Vector2(11,10),Vector2(-3,13),Vector2(-14,5)])
    draw_colored_polygon(path,Color(.57,.31,.42,.83))
    _outline_poly(path,DETRITUS,1.9)

func _draw() -> void:
    if not is_instance_valid(view_camera) or not view_camera.is_inside_tree():
        return
    for rec in source_nutrients:
        if not (rec is Dictionary):
            continue
        var node: Node3D = rec.get("node",null)
        if not is_instance_valid(node) or not node.is_inside_tree():
            continue
        if view_camera.is_position_behind(node.global_position):
            continue
        var at: Vector2 = view_camera.unproject_position(node.global_position+Vector3(0,.13,0))
        if at.x < 20.0 or at.x > size.x-20.0:
            continue
        if at.y < cutoff_top+20.0 or at.y > size.y-35.0:
            continue
        var dist: float = view_camera.global_position.distance_to(node.global_position)
        var scale_factor: float = clampf(9.0/maxf(dist,4.0),.69,1.09)
        scale_factor *= clampf(size.x/720.0,.84,1.28)
        var kind: String = str(rec.get("kind",""))
        var hover: float = sin(seconds*1.42+float(rec.get("bob",0.0)))*1.4
        draw_set_transform(at+Vector2(0,hover),0.0,Vector2.ONE*scale_factor)
        match kind:
            "carbon":
                _carbon()
            "amino":
                _amino()
            "lipid":
                _lipid()
            "nucleic":
                _nucleic()
            "detritus":
                _detritus()
        draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
