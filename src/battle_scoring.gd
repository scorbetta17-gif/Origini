extends RefCounted
## Per-cell, bounded, saveable score ledger. No score modifies combat statistics.
const DAMAGE_WINDOW: float = 30.0
const DEFAULT_NUTRITION_TARGET: float = 150.0
const NUTRIENTS := ["carbon","amino","lipid","nucleic"]

static func initialize(state: Dictionary) -> void:
    for key in ["scores","damage","credited","crossings"]:
        if not state.has(key): state[key] = {}
    if not state.has("nutrition_target"): state.nutrition_target = DEFAULT_NUTRITION_TARGET

static func account(state: Dictionary, id: String) -> Dictionary:
    initialize(state)
    if not state.scores.has(id): state.scores[id] = {"absorbed":0.0,"kills":[],"fronts":{}}
    return state.scores[id]

static func intake(state: Dictionary, id: String, before: Dictionary, after: Dictionary) -> float:
    var amount: float = 0
    for key in NUTRIENTS: amount += maxf(0,float(after.get(key,0))-float(before.get(key,0)))
    var cell: Dictionary = account(state,id)
    cell.absorbed = float(cell.absorbed)+amount
    return amount

static func hit(state: Dictionary, victim: String, attacker: String, damage: float) -> void:
    initialize(state)
    if victim==attacker or damage<=0 or state.credited.has(victim): return
    var hits: Array = state.damage.get(victim,[])
    var recent: Array = []
    for event in hits:
        if float(state.elapsed)-float(event[0])<=DAMAGE_WINDOW: recent.append(event)
    recent.append([float(state.elapsed),attacker,damage])
    state.damage[victim] = recent

static func death(state: Dictionary, victim: String) -> String:
    initialize(state)
    if state.credited.has(victim): return str(state.credited[victim])
    var totals: Dictionary = {}
    for event in state.damage.get(victim,[]):
        var age: float = float(state.elapsed)-float(event[0])
        if age>=0 and age<=DAMAGE_WINDOW:
            totals[event[1]] = float(totals.get(event[1],0))+float(event[2])
    var winner: String = ""
    var maximum: float = 0
    var ids: Array = totals.keys()
    ids.sort() # Exact damage ties resolved by stable cell ID, not traversal order.
    for id in ids:
        if float(totals[id])>maximum:
            maximum = float(totals[id])
            winner = id
    state.credited[victim] = winner # Even environment-only deaths are finalized once.
    state.damage.erase(victim)
    if not winner.is_empty(): account(state,winner).kills.append(victim)
    return winner

static func front(state: Dictionary, id: String, stage: int, objective: String) -> bool:
    if stage<1 or stage>4: return false
    var cell: Dictionary = account(state,id)
    if cell.fronts.has(str(stage)): return false
    cell.fronts[str(stage)] = objective
    return true

static func breakdown(state: Dictionary, id: String, hp: float, atp: float) -> Dictionary:
    var cell: Dictionary = account(state,id)
    var vitality: float = clampf(hp,0,100)*.25+clampf(atp,0,100)*.15
    var nutrition: float = 20.0*clampf(float(cell.absorbed)/float(state.nutrition_target),0,1)
    var eliminations: float = minf(20,cell.kills.size()*4)
    var objectives: float = minf(20,cell.fronts.size()*5)
    return {"vitality":vitality,"nutrition":nutrition,"eliminations":eliminations,"objectives":objectives,
        "total":vitality+nutrition+eliminations+objectives,"absorbed":cell.absorbed,"kills":cell.kills.duplicate(),"fronts":cell.fronts.duplicate()}

static func valid(state: Dictionary) -> bool:
    # Legacy 0.82 starts fresh counters; historical intake cannot be reconstructed.
    for key in ["scores","damage","credited","crossings"]:
        if state.has(key) and not state[key] is Dictionary: return false
    var threshold: Variant = state.get("nutrition_target",DEFAULT_NUTRITION_TARGET)
    if not numeric(threshold) or float(threshold)<=0: return false
    for cell in state.get("scores",{}).values():
        if not cell is Dictionary or not numeric(cell.get("absorbed")) or float(cell.absorbed)<0: return false
        if not cell.get("kills") is Array or not cell.get("fronts") is Dictionary: return false
        var unique: Dictionary = {}
        for id in cell.kills:
            if not id is String or unique.has(id): return false
            unique[id] = true
        for key in cell.fronts:
            if str(key) not in ["1","2","3","4"] or not cell.fronts[key] is String: return false
    for victim in state.get("damage",{}):
        if not state.damage[victim] is Array: return false
        for event in state.damage[victim]:
            if not event is Array or event.size()!=3: return false
            if not numeric(event[0]) or not event[1] is String or not numeric(event[2]): return false
            if float(event[0])<0 or float(event[0])>float(state.elapsed) or float(event[2])<0: return false
    for winner in state.get("credited",{}).values():
        if not winner is String: return false
    for value in state.get("crossings",{}).values():
        if not value is Dictionary: return false
        if not value.get("outside") is bool or not numeric(value.get("at")): return false
    return true

static func numeric(value: Variant) -> bool:
    return (value is float or value is int) and is_finite(float(value))
