extends Control
var battle: Node

func _draw() -> void:
    if battle==null or not battle.active(): return
    var z: Dictionary = battle.rules.zone(battle.state.elapsed)
    var origin := Vector2(78,78)
    var scale_map: float = 1.8
    draw_circle(origin,76,Color(.02,.07,.10,.88))
    draw_arc(origin+Vector2(z.center.x,z.center.z)*scale_map,z.radius*scale_map,0,TAU,80,Color(.25,.95,.77),2,true)
    if z.warning:
        draw_arc(origin+Vector2(z.next_center.x,z.next_center.z)*scale_map,z.next_radius*scale_map,0,TAU,80,Color(1,.75,.25),2,true)
    for i in range(3):
        var p: Vector3 = battle.rules.depot(battle.state.elapsed,i)
        draw_circle(origin+Vector2(p.x,p.z)*scale_map,4,Color(1,.65,.20) if battle.state.stocks[i]>0 else Color(.3,.3,.3))
    for id in battle.game.entities:
        var p: Vector3 = battle.game.entities[id].node.position
        var color := Color(1,.35,.45)
        if battle.friendly(id,battle.game.player_id): color = Color(.4,.8,1)
        if id==battle.game.player_id: color = Color.WHITE
        draw_circle(origin+Vector2(p.x,p.z)*scale_map,3 if id==battle.game.player_id else 2,color)
    draw_string(ThemeDB.fallback_font,Vector2(8,172),"Rifugio / depositi / rivali",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
