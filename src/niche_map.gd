extends Control
var game: Node
func _draw() -> void:
    var origin:=Vector2(size.x*.5,130)
    draw_rect(Rect2(Vector2.ZERO,size),Color(.03,.13,.17))
    for i in range(3):
        var at: Vector3=game.habitats.CENTERS[i]
        var p: Vector2=origin+Vector2(at.x,at.z)*4
        draw_circle(p,28,[Color(.2,.5,.4),Color(.7,.3,.15),Color(.35,.45,.6)][i])
        draw_string(ThemeDB.fallback_font,p+Vector2(-40,-35),game.habitats.TITLES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12)
        var count: int=0
        for n in game.ecology.niches["site"+str(i)].populations.values(): count+=int(n)
        draw_string(ThemeDB.fallback_font,p+Vector2(-8,5),str(count),HORIZONTAL_ALIGNMENT_LEFT,-1,18)
    for e in game.entities.values():
        var p: Vector3=e.node.position
        if Vector2(p.x,p.z).length()<35: draw_circle(origin+Vector2(p.x,p.z)*4,3,Color.WHITE if e.node==game.player else Color(.7,.8,1))
