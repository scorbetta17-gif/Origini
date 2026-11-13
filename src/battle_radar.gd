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
        # Shade the area outside the announced refuge, before it becomes dangerous.
        for angle in range(72):
            var a: float = TAU*angle/72.0
            var center: Vector2 = origin+Vector2(z.next_center.x,z.next_center.z)*scale_map
            draw_line(center+Vector2(cos(a),sin(a))*z.next_radius*scale_map,center+Vector2(cos(a),sin(a))*72,Color(.8,.25,.32,.32),3)
        var me: Vector3 = battle.game.player.position
        for i in range(3):
            var future: Vector3 = battle.rules.depot((int(z.stage)+1)*battle.rules.PHASE_LENGTH,i)
            var at: Vector2 = origin+Vector2(future.x,future.z)*scale_map
            var color: Color = [Color(1,.48,.28),Color(.4,1,.75),Color(.6,.75,1)][i]
            draw_arc(at,6,0,TAU,16,color,2,true)
            draw_string(ThemeDB.fallback_font,at+Vector2(7,3),["R","S","C"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
            if i<2: draw_dashed_line(origin+Vector2(me.x,me.z)*scale_map,at,color,1,4)
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
    draw_string(ThemeDB.fallback_font,Vector2(8,172),"R ricco · S sicuro · C alleati",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
