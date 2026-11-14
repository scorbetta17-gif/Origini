extends RefCounted
## Session counters and read-only census. Capacity share != population share.
const Ecology = preload("res://src/niche_ecology.gd")
const Genome = preload("res://src/cell_genome.gd")
const CAPACITY: int = 48
const KEYS := ["carbon","amino","lipid","nucleic"]

static func origin(started_at: float = 0.0) -> Dictionary:
    return {"version":1,"started_at":started_at,"divisions":0,"particles":0,
        "substrates":0,"kills":0,"collected":{"carbon":0.0,"amino":0.0,"lipid":0.0,"nucleic":0.0}}

static func normalize(raw: Dictionary, fallback_start: float = 0.0) -> Dictionary:
    var result: Dictionary = origin(fallback_start)
    for key in ["divisions","particles","substrates","kills"]:
        result[key] = maxi(0,int(raw.get(key,0)))
    result.started_at = maxf(0.0,float(raw.get("started_at",fallback_start)))
    var collected: Dictionary = raw.get("collected",{}) if raw.get("collected",{}) is Dictionary else {}
    for key in KEYS:
        result.collected[key] = maxf(0.0,float(collected.get(key,0)))
    return result

static func record_intake(state: Dictionary, before: Dictionary, after: Dictionary) -> void:
    # Count what reached reserves, not material discarded at the reserve cap.
    for key in KEYS:
        state.collected[key] = float(state.collected.get(key,0))+maxf(0.0,float(after.get(key,0))-float(before.get(key,0)))

static func genetic_group(traits: Dictionary) -> String:
    if traits.is_empty():
        return "Non classificate"
    return "Cellule DNA" if Genome.has(traits,"dna_stabilization") or bool(traits.get("dna",false)) else "Cellule RNA"

static func census(ecology: Dictionary, profiles: Dictionary, position: Vector3, whole_map: bool = false) -> Dictionary:
    var normalized: Dictionary = Ecology.normalize(ecology)
    var ids: Array = normalized.niches.keys() if whole_map else [Ecology.niche_id(position)]
    var counts: Dictionary = {}
    for id in ids:
        for lineage in normalized.niches[id].populations:
            counts[lineage] = int(counts.get(lineage,0))+int(normalized.niches[id].populations[lineage])
    var surface: float = 0
    for id in ids: surface += Ecology.area(str(id))
    var total: int = 0
    for n in counts.values(): total += int(n)
    var capacity: int = CAPACITY*ids.size()
    var groups := {"Cellule RNA":0,"Cellule DNA":0,"Non classificate":0}
    var lines: Array[Dictionary] = []
    for lineage in counts:
        var traits: Dictionary = profiles.get(lineage,{})
        var group: String = genetic_group(traits)
        var count: int = int(counts[lineage])
        groups[group] += count
        lines.append({"id":str(lineage),"group":group,"count":count,
            "population_percent":100.0*count/maxi(1,total),
            "capacity_percent":100.0*count/capacity,
            "density":float(count)/(surface),"traits":traits.duplicate(true)})
    lines.sort_custom(func(a: Dictionary,b: Dictionary):
        return a.count>b.count if a.count!=b.count else a.id<b.id)
    return {"total":total,"capacity":capacity,"occupied_percent":100.0*total/capacity,
        "free_percent":maxf(0.0,100.0*(capacity-total)/capacity),"groups":groups,"lines":lines,
        "area":surface,"niche":Ecology.niche_id(position)}
