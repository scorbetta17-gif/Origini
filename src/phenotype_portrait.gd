extends Control
class_name PhenotypePortrait
## Scientific UI portrait built from real heritable phenotype.
## A compact, immediately legible reference to the former JS mobile game.
var phenotype: Dictionary = {}
var lineage: String = "pre_luca"
var highlighted: bool = false

func set_cell(traits: Dictionary, branch: String) -> void:
    phenotype = traits.duplicate(true)
    lineage = branch
    queue_redraw()

func _circle(at: Vector2, radius: float, color: Color) -> void:
    draw_circle(at,radius,color)

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 10 or h < 10:
        return
    var center: Vector2 = size*.5
    var radius: float = minf(w*.29,h*.36)
    var tint: Color = Color(.37,.79,.80)
    if lineage == "archaea":
        tint = Color(.43,.88,.71)
    elif lineage == "bacteria":
        tint = Color(.49,.78,.88)
    elif lineage == "luca":
        tint = Color(.73,.68,.95)
    _circle(center,radius*1.33,Color(tint.r,tint.g,tint.b,.075))
    _circle(center,radius*1.18,Color(tint.r,tint.g,tint.b,.075))
    var ring: PackedVector2Array = PackedVector2Array()
    for i in range(65):
        var angle: float = TAU*float(i)/64.0
        var r: float = radius*(1.0+.045*sin(angle*4.0)+.027*cos(angle*7.0))
        ring.append(center+Vector2(cos(angle)*r,sin(angle)*r))
    draw_colored_polygon(ring,Color(tint.r*.43,tint.g*.45,tint.b*.51,.97))
    draw_polyline(ring,tint.lightened(.21),3.6,true)
    _circle(center+Vector2(-radius*.29,-radius*.40),radius*.36,Color(1,1,1,.08))
    var dna: bool = bool(phenotype.get("dna",false))
    var rna: PackedVector2Array = PackedVector2Array()
    for i in range(39):
        var t: float = float(i)/38.0
        var point: Vector2 = center+Vector2(
            (t-.5)*radius*.95+sin(t*TAU*2.5)*radius*.12,
            sin(t*TAU*1.25)*radius*.32+cos(t*TAU*2.5)*radius*.08)
        rna.append(point)
    draw_polyline(rna,Color(.94,.62,.83) if not dna else Color(.73,.73,.97),3.7,true)
    if dna:
        var second: PackedVector2Array = PackedVector2Array()
        for i in range(39):
            var t: float = float(i)/38.0
            second.append(center+Vector2(
                (t-.5)*radius*.95+sin(t*TAU*2.5+PI)*radius*.12,
                sin(t*TAU*1.25+PI)*radius*.32+cos(t*TAU*2.5+PI)*radius*.08))
        draw_polyline(second,Color(.62,.83,.96),2.8,true)
    for i in range(3):
        var a: float = .6+float(i)*TAU/3.0
        _circle(center+Vector2(cos(a)*radius*.50,sin(a)*radius*.48),
            radius*.067,Color(.91,.91,.52))
    var pili: int = mini(8,int(phenotype.get("pili",0)))
    for i in range(pili):
        var a: float = TAU*float(i)/float(maxi(1,pili))
        var from: Vector2 = center+Vector2(cos(a),sin(a))*radius
        var to: Vector2 = from+Vector2(cos(a),sin(a))*radius*.33
        draw_line(from,to,Color(.76,.93,.77),2.1,true)
    var receptors: int = mini(8,int(phenotype.get("receptors",0)))
    for i in range(receptors):
        var a: float = TAU*(float(i)+.35)/float(maxi(1,receptors))
        var position: Vector2 = center+Vector2(cos(a),sin(a))*radius*1.08
        _circle(position,radius*.045,Color(.96,.94,.70))
    var motile: int = mini(3,int(phenotype.get("flagella",0))+int(phenotype.get("archaella",0)))
    for i in range(motile):
        var start: Vector2 = center+Vector2(-radius*.90,(-.33+float(i)*.27)*radius)
        var tail: PackedVector2Array = PackedVector2Array()
        for j in range(12):
            var t: float = float(j)/11.0
            tail.append(start+Vector2(-t*radius*.7,sin(t*TAU*2.2)*radius*.11))
        draw_polyline(tail,Color(.73,.90,.85),2.1,true)
    if bool(phenotype.get("eps",false)):
        draw_arc(center,radius*1.13,0,TAU,64,Color(.59,.88,.77,.55),2.0,true)
