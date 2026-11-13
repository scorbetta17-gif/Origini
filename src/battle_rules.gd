extends RefCounted
## Arena rules are game abstractions, not an evolutionary chronology.
const DURATION: float = 1200.0
const PHASE_LENGTH: float = 240.0
const WARNING: float = 90.0
const TRANSITION: float = 90.0
const RADII := [34.0,28.0,22.0,16.0,10.0]
const NAMES := ["Predazione","Difesa","Mobilità","Cooperazione"]

static func origin() -> Dictionary:
    return {"enabled":true,"elapsed":0.0,"result":"","profile":0,
        "teams":{},"pacts":{},"depot_phase":-1,"stocks":[60,60,60],
        "harvest":{},"repair":{},"packets":{},"spawn_credit":0.0,"announced":-1}

static func center(stage: int) -> Vector3:
    return Vector3.ZERO if stage==0 else Vector3(sin(stage*1.7)*3.0,0,cos(stage*1.7)*3.0)

static func zone(elapsed: float) -> Dictionary:
    var stage: int = clampi(int(elapsed/PHASE_LENGTH),0,4)
    var progress: float = clampf((elapsed-stage*PHASE_LENGTH)/TRANSITION,0.0,1.0)
    var previous: int = maxi(0,stage-1)
    var radius: float = lerpf(RADII[previous],RADII[stage],progress)
    var at: Vector3 = center(previous).lerp(center(stage),progress)
    var next: int = mini(4,stage+1)
    var seconds: float = (stage+1)*PHASE_LENGTH-elapsed
    return {"stage":stage,"radius":radius,"center":at,"next_center":center(next),
        "next_radius":RADII[next],"warning":stage<4 and seconds<=WARNING,
        "seconds":maxf(0.0,seconds),"remaining":maxf(0.0,DURATION-elapsed)}

static func exposure(elapsed: float, at: Vector3) -> float:
    var z: Dictionary = zone(elapsed)
    return maxf(0.0,Vector2(at.x-z.center.x,at.z-z.center.z).length()-z.radius)

static func damage(elapsed: float, at: Vector3, traits: Dictionary, cooperating: bool = false) -> float:
    var outside: float = exposure(elapsed,at)
    if outside<=0.0: return 0.0
    var protection: float = minf(.30,maxf(0.0,float(traits.get("defense",1.0))-1.0)*.6)
    var thermal: bool = int(zone(elapsed).stage)%2==1
    var adaptation: float = minf(.12,float(traits.get("thermotolerance",0))*.06) if thermal else (.08 if bool(traits.get("eps",false)) else 0.0)
    protection = minf(.30,protection+adaptation)
    protection += .10 if cooperating else 0.0
    var stage: int = int(zone(elapsed).stage)
    return (.6+stage*.35)*clampf(outside/3.0,.15,2.0)*(1.0-protection)

static func environment(elapsed: float, at: Vector3) -> Dictionary:
    var outside: float = exposure(elapsed,at)
    var thermal: bool = int(zone(elapsed).stage)%2==1
    return {"temperature":29.0+minf(32.0,outside*2.0) if thermal else 29.0,
        "ph":7.2 if thermal else 7.2-minf(3.0,outside*.2),"front":"termico" if thermal else "acido"}

static func depot(elapsed: float, index: int) -> Vector3:
    var z: Dictionary = zone(elapsed)
    var angle: float = TAU*index/3.0+int(z.stage)*.6
    return center(int(z.stage))+Vector3(cos(angle),0,sin(angle))*float(RADII[int(z.stage)])*.48

static func score(health: float, energy: float, packets: int) -> float:
    # No kill score; collection contribution capped to prevent snowballing.
    return clampf(health,0,100)*.60+clampf(energy,0,100)*.30+minf(10.0,packets*.25)

static func valid(raw: Variant) -> bool:
    if not raw is Dictionary: return false
    if not bool(raw.get("enabled",false)): return raw.is_empty()
    if not raw.get("elapsed") is float and not raw.get("elapsed") is int: return false
    if not is_finite(float(raw.elapsed)) or float(raw.elapsed)<0 or float(raw.elapsed)>DURATION: return false
    for key in ["teams","pacts","harvest","repair","packets"]:
        if not raw.get(key) is Dictionary: return false
    if not raw.get("stocks") is Array or raw.stocks.size()!=3: return false
    for stock in raw.stocks:
        if not (stock is int or stock is float) or not is_finite(float(stock)) or float(stock)<0 or float(stock)>60: return false
    for key in ["profile","depot_phase","spawn_credit","announced"]:
        if not (raw.get(key) is int or raw.get(key) is float) or not is_finite(float(raw[key])): return false
    if int(raw.profile)<0 or int(raw.profile)>3 or float(raw.spawn_credit)<0 or float(raw.spawn_credit)>1: return false
    if int(raw.depot_phase)<-1 or int(raw.depot_phase)>4 or int(raw.announced)<-1 or int(raw.announced)>3: return false
    for key in ["teams","pacts"]:
        for value in raw[key].values():
            if not value is String: return false
    for key in ["harvest","repair","packets"]:
        for value in raw[key].values():
            if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return false
    return str(raw.get("result","")) in ["","vittoria","sconfitta","pareggio"]
