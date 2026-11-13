extends RefCounted
## Persistent aggregate census. Rendered entities are representatives, never extra counts.
const VERSION: int = 1
const AREA_KM2: float = 0.2116
const WORLD_MIN: float = -1150.0
const NICHE_WIDTH: float = 460.0
const INTERVAL: float = 5.0
const MIN_DENSITY: float = 30.0
const DOMINANCE: float = 1.5
const HABITATS: Array[String] = ["prey_rich", "exposed_reef", "nutrient_mat", "fragmented_patches", "lean_vent"]
const WEIGHTS: Array[Dictionary] = [
    {"attack":.55,"motility":.18,"vitality":.12,"metabolism":.15},
    {"defense":.48,"vitality":.32,"uptake":.10,"metabolism":.10},
    {"uptake":.60,"metabolism":.30,"vitality":.10},
    {"motility":.65,"metabolism":.20,"uptake":.15},
    {"metabolism":.60,"uptake":.20,"defense":.10,"vitality":.10}
]

static func origin() -> Dictionary:
    var niches: Dictionary = {}
    for index in range(25):
        niches[str(index)] = {"habitat":HABITATS[(index + index / 5) % 5],
            "populations":{}, "birth_credit":{}, "death_credit":{}, "resources":48.0}
    return {"version":VERSION, "elapsed":0.0, "niches":niches}

static func normalize(raw: Dictionary) -> Dictionary:
    var state: Dictionary = origin()
    state.elapsed = clampf(float(raw.get("elapsed",0.0)),0.0,INTERVAL)
    var old: Dictionary = raw.get("niches",{})
    for key in state.niches:
        var entry: Dictionary = old.get(key,{})
        var target: Dictionary = state.niches[key]
        target.resources = clampf(float(entry.get("resources",48.0)),0.0,96.0)
        var populations: Dictionary = entry.get("populations",{})
        for lineage in populations:
            var count: int = maxi(0,int(populations[lineage]))
            if count > 0 and not str(lineage).is_empty():
                target.populations[str(lineage)] = count
                for credit in ["birth_credit","death_credit"]:
                    target[credit][str(lineage)] = clampf(float(entry.get(credit,{}).get(lineage,0.0)),0.0,.999999)
    return state

static func niche_id(position: Vector3) -> String:
    var column: int = clampi(int(floor((position.x-WORLD_MIN)/NICHE_WIDTH)),0,4)
    var row: int = clampi(int(floor((position.z-WORLD_MIN)/NICHE_WIDTH)),0,4)
    return str(row*5+column)

static func register_birth(state: Dictionary, lineage: String, position: Vector3, count: int = 1) -> Dictionary:
    if count <= 0 or lineage.is_empty():
        return state
    var populations: Dictionary = state.niches[niche_id(position)].populations
    populations[lineage] = int(populations.get(lineage,0))+count
    return state

static func register_death(state: Dictionary, lineage: String, position: Vector3, count: int = 1) -> Dictionary:
    if count <= 0:
        return state
    var niche: Dictionary = state.niches[niche_id(position)]
    var remaining: int = maxi(0,int(niche.populations.get(lineage,0))-count)
    if remaining > 0:
        niche.populations[lineage] = remaining
    else:
        niche.populations.erase(lineage)
        niche.birth_credit.erase(lineage)
        niche.death_credit.erase(lineage)
    return state

static func differentiate(state: Dictionary, previous: String, descendant: String, position: Vector3, count: int = 1) -> Dictionary:
    if previous == descendant or descendant.is_empty() or count <= 0:
        return state
    var populations: Dictionary = state.niches[niche_id(position)].populations
    var transferred: int = mini(count,int(populations.get(previous,0)))
    register_death(state,previous,position,transferred)
    register_birth(state,descendant,position,transferred)
    return state

static func climate_fit(traits: Dictionary, habitat: String) -> float:
    var index: int = HABITATS.find(habitat)
    if index < 0:
        index = 0
    var logarithm: float = 0.0
    for stat in WEIGHTS[index]:
        logarithm += float(WEIGHTS[index][stat])*log(clampf(float(traits.get(stat,1.0)),.25,2.5))
    return clampf(exp(logarithm),.4,2.0)

static func advance(state: Dictionary, delta: float, lineage_profiles: Dictionary) -> Dictionary:
    # At most 60 seconds per call: no offline population explosion after resume.
    state.elapsed = float(state.get("elapsed",0.0))+clampf(delta,0.0,60.0)
    while float(state.elapsed) >= INTERVAL:
        state.elapsed = float(state.elapsed)-INTERVAL
        for key in state.niches:
            _step(state.niches[key],lineage_profiles)
    return state

static func _step(niche: Dictionary, profiles: Dictionary) -> void:
    var populations: Dictionary = niche.populations
    var total: int = 0
    for count in populations.values():
        total += int(count)
    # 48 cells/niche carrying capacity = 226.84 cells/km2, never a founder source.
    var capacity: int = 48
    niche.resources = minf(96.0,float(niche.resources)+2.4)
    var ids: Array = populations.keys()
    ids.sort()
    var desired_births: Dictionary = {}
    var requested: int = 0
    for lineage in ids:
        var n: int = int(populations[lineage])
        var profile: Dictionary = profiles.get(lineage,{})
        var traits: Dictionary = profile.get("traits",profile)
        var fit: float = climate_fit(traits,str(niche.habitat))
        # Resource maintenance and overcrowding are shared; unsuitable phenotypes lose more.
        var starvation: float = maxf(0.0,float(total)*.035-float(niche.resources))/maxf(1.0,float(total)*.035)
        var mortality: float = .003 + maxf(0.0,1.0-fit)*.04 + maxf(0.0,float(total)/capacity-1.0)*.04 + starvation*.08
        var death_credit: float = float(niche.death_credit.get(lineage,0.0))+n*mortality
        var deaths: int = mini(n,int(floor(death_credit)))
        niche.death_credit[lineage] = death_credit-floor(death_credit)
        populations[lineage] = n-deaths
        var birth_credit: float = float(niche.birth_credit.get(lineage,0.0))+(n-deaths)*.022*fit*maxf(0.0,1.0-float(total)/capacity)
        var births: int = int(floor(birth_credit))
        niche.birth_credit[lineage] = birth_credit-floor(birth_credit)
        desired_births[lineage] = births
        requested += births
    niche.resources = maxf(0.0,float(niche.resources)-total*.035)
    var available: int = mini(maxi(0,capacity-total),int(floor(float(niche.resources))))
    # Proportional grant, rounded down: no lineage-ID priority, no free births.
    for lineage in ids:
        var births: int = int(desired_births[lineage])
        if requested > available:
            births = int(floor(float(births)*available/maxi(1,requested)))
        populations[lineage] = int(populations[lineage])+births
        niche.resources = maxf(0.0,float(niche.resources)-births)
        if int(populations[lineage]) == 0:
            populations.erase(lineage)
            niche.birth_credit.erase(lineage)
            niche.death_credit.erase(lineage)

static func summary(state: Dictionary, lineage: String, position: Vector3) -> Dictionary:
    var id: String = niche_id(position)
    var niche: Dictionary = state.niches[id]
    var populations: Dictionary = niche.populations
    var own: int = int(populations.get(lineage,0))
    var strongest: int = 0
    var total: int = 0
    for other in populations:
        total += int(populations[other])
        if str(other) != lineage:
            strongest = maxi(strongest,int(populations[other]))
    var dense: bool = float(own)/AREA_KM2 >= MIN_DENSITY
    var dominant: bool = dense and (strongest == 0 or float(own) >= DOMINANCE*strongest)
    return {"niche_id":id,"habitat":niche.habitat,"area_km2":AREA_KM2,"population":own,
        "total_population":total,"density":float(own)/AREA_KM2,"strongest_rival":strongest,
        "dominant":dominant,"coexistence":dense and not dominant,
        "status":"dominant" if dominant else ("coexistence" if dense else "sparse")}
