extends RefCounted
## Shared player/AI attack contract; all timings are seconds and persisted per match.
const DEFAULTS={"windup":.7,"recovery":1.8,"reach":1.65,"cost":10.0,"power":18.0}
static func initialize(b: Node) -> void:
    if not b.state.has("combat"): b.state.combat={}
    if not b.state.has("combat_config"): b.state.combat_config=DEFAULTS.duplicate()
    if not b.state.has("combat_metrics"): b.state.combat_metrics={"attempts":0,"hits":0,"misses":0}
static func busy(b: Node,id: String) -> bool:
    return b.active() and b.state.get("combat",{}).has(id)
static func request(b: Node,id: String,target: String) -> bool:
    initialize(b)
    var g: Node=b.game
    if busy(b,id) or not g.entities.has(id) or not g.entities.has(target) or b.friendly(id,target): return false
    var at: Vector3=g.entities[id].node.position
    var delta: Vector3=g.entities[target].node.position-at
    if delta.length()>float(b.state.combat_config.reach): return false
    var energy: float=g.atp if id==g.player_id else float(g.entities[id].energy)
    if energy<float(b.state.combat_config.cost): return false
    if id==g.player_id: g.atp-=float(b.state.combat_config.cost)
    else: g.entities[id].energy-=float(b.state.combat_config.cost)
    var direction: Vector3=delta.normalized()
    b.state.combat[id]={"target":target,"phase":"windup","left":b.state.combat_config.windup,"direction":[direction.x,direction.y,direction.z]}
    b.state.combat_metrics.attempts+=1
    return true
static func react(b: Node,id: String) -> Vector3:
    initialize(b)
    var g: Node=b.game
    if busy(b,id): return Vector3.ZERO
    var at: Vector3=g.entities[id].node.position
    for other in b.state.combat.keys():
        if not g.entities.has(other) or b.friendly(id,other): continue
        var record: Dictionary=b.state.combat[other]
        var away: Vector3=at-g.entities[other].node.position
        if away.length()>3: continue
        if record.phase=="windup" and record.target==id:
            return away.normalized()*3
        var style: int=int(g.entities[id].traits.get("arena_profile",0))
        if record.phase=="recovery" and away.length()<float(b.state.combat_config.reach) and (style in [0,1] or (style==3 and not b.nearby_partner(id).is_empty())):
            request(b,id,other)
            return Vector3.ZERO
    return Vector3.ZERO
static func advance(b: Node,dt: float) -> void:
    initialize(b)
    var g: Node=b.game
    for id in b.state.combat.keys():
        if not g.entities.has(id): b.state.combat.erase(id);continue
        var e: Dictionary=g.entities[id]
        if (g.hp if id==g.player_id else float(e.hp))<=0: b.state.combat.erase(id);continue
        var r: Dictionary=b.state.combat[id]
        r.left=float(r.left)-dt
        if r.phase=="windup" and float(r.left)<=0:
            r.phase="recovery";r.left=b.state.combat_config.recovery
            var hit: bool=false
            if g.entities.has(r.target) and not b.friendly(id,str(r.target)):
                var victim: Dictionary=g.entities[r.target]
                var offset: Vector3=victim.node.position-e.node.position
                var forward:=Vector3(r.direction[0],r.direction[1],r.direction[2])
                if offset.length()<=float(b.state.combat_config.reach) and (offset.length()<.05 or forward.dot(offset.normalized())>.35):
                    var hp: float=g.hp if r.target==g.player_id else float(victim.hp)
                    var damage: float=float(b.state.combat_config.power)*float(e.traits.get("attack",1))/maxf(.4,float(victim.traits.get("defense",1)))/maxf(.65,float(victim.traits.get("vitality",1)))
                    if hp>0:
                        b.record_hit(str(r.target),str(id),minf(hp,damage))
                        if r.target==g.player_id: g.hp=maxf(0,hp-damage)
                        else: victim.hp=maxf(0,hp-damage)
                        hit=true
                        if hp<=damage:
                            if r.target!=g.player_id: g._remove_entity(str(r.target),"predazione")
                            g._award_bundle(g.Balance.KILL_REWARD,id==g.player_id,str(id))
                            if id==g.player_id: g.statistics.kills+=1
            b.state.combat_metrics["hits" if hit else "misses"]+=1
        elif r.phase=="recovery" and float(r.left)<=0:
            b.state.combat.erase(id)
    for id in g.entities:
        var node: Node3D=g.entities[id].node
        var label: Label3D=node.get_node_or_null("Attacco")
        if b.state.combat.has(id):
            if label==null:
                label=Label3D.new();label.name="Attacco";label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
                label.font_size=64;label.pixel_size=.018;label.position=Vector3(0,1.5,0);node.add_child(label)
            var r: Dictionary=b.state.combat[id]
            label.text="▷" if r.phase=="windup" else "…"
            label.scale=Vector3.ONE*(1.0+.3*sin(float(r.left)*12)) if r.phase=="windup" else Vector3.ONE*.8
            label.visible=true
        elif label!=null: label.visible=false
