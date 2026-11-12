extends RefCounted
class_name PhaseOneProgress
## Phase 1: ecological colonization and comparison of evolving cohorts.
## Completion requires an extended observation period; not an arbitrary
## two-division shortcut. Endosymbiosis is NOT part of this phase.
const MIN_PLAYER_GENERATION: int = 6
const MIN_LIVING_CELLS: int = 10
const MIN_AUTONOMOUS_DIVISIONS: int = 3
const FINAL_OBSERVATION_SECONDS: float = 75.0

static func empty() -> Dictionary:
    return {
        "started":true, "complete":false, "intro_seen":false,
        "player_divisions":0, "autonomous_divisions":0,
        "high_generation_seen":false, "living_threshold_seen":false,
        "observation_seconds":0.0, "completed_at":-1.0,
        "final_report":{}, "phase_two_intro_seen":false
    }

static func normalize(value: Dictionary) -> Dictionary:
    var output: Dictionary = empty()
    for key in output:
        if value.has(key):
            output[key] = value[key]
    return output

static func group(gen: int) -> String:
    if gen <= 2:
        return "prime"
    if gen <= 5:
        return "intermedie"
    return "recenti"

static func population(entities: Dictionary) -> Dictionary:
    var result: Dictionary = {"prime":0,"intermedie":0,"recenti":0,"totale":0,
        "raccoglitore":0,"esploratore":0,"predatore":0,"difensore":0}
    for id in entities:
        var e: Dictionary = entities[id]
        result[group(int(e.get("generation",0)))] += 1
        result["totale"] += 1
        var role: String = str(e.get("strategy","raccoglitore"))
        if result.has(role):
            result[role] += 1
    for cohort in ["prime","intermedie","recenti"]:
        result[cohort+"_pct"] = 100.0*float(result[cohort])/float(maxi(1,int(result["totale"])))
    return result

static func advance(value: Dictionary, elapsed: float, generation: int,
                    current_population: Dictionary, world_seconds: float) -> Dictionary:
    var p: Dictionary = normalize(value)
    if bool(p["complete"]):
        return p
    if generation >= MIN_PLAYER_GENERATION:
        p["high_generation_seen"] = true
    if int(current_population.get("totale",0)) >= MIN_LIVING_CELLS:
        p["living_threshold_seen"] = true
    # Hold the final cohort under actual autonomous competition.
    # A fall in population resets this observation; successful early
    # exploration and division remain recorded.
    var eligible: bool = bool(p["high_generation_seen"]) and (
        int(p["autonomous_divisions"]) >= MIN_AUTONOMOUS_DIVISIONS) and (
        int(current_population.get("totale",0)) >= MIN_LIVING_CELLS)
    if eligible:
        p["observation_seconds"] = minf(FINAL_OBSERVATION_SECONDS,
            float(p["observation_seconds"])+maxf(0.0,elapsed))
    else:
        p["observation_seconds"] = 0.0
    if eligible and float(p["observation_seconds"]) >= FINAL_OBSERVATION_SECONDS:
        p["complete"] = true
        p["completed_at"] = world_seconds
        p["final_report"] = current_population.duplicate(true)
    return p

static func mission_lines(value: Dictionary, current_population: Dictionary, generation: int) -> Array[String]:
    var p: Dictionary = normalize(value)
    var n: int = int(current_population.get("totale",0))
    return [
        ("✓" if int(p["player_divisions"]) >= 1 else "○") + "  1. Prima scissione: due cellule figlie",
        ("✓" if generation >= MIN_PLAYER_GENERATION else "○") + "  2. Evolvi la tua linea fino al ciclo %d (%d/%d)" % [MIN_PLAYER_GENERATION,mini(generation,MIN_PLAYER_GENERATION),MIN_PLAYER_GENERATION],
        ("✓" if int(p["autonomous_divisions"]) >= MIN_AUTONOMOUS_DIVISIONS else "○") + "  3. Almeno %d divisioni autonome (%d/%d)" % [MIN_AUTONOMOUS_DIVISIONS,int(p["autonomous_divisions"]),MIN_AUTONOMOUS_DIVISIONS],
        ("✓" if n >= MIN_LIVING_CELLS else "○") + "  4. Popola l'oceano con %d cellule vive (%d/%d)" % [MIN_LIVING_CELLS,n,MIN_LIVING_CELLS],
        ("✓" if bool(p["complete"]) else "○") + "  5. Osserva la competizione per %.0f s (%.0f/%.0f)" % [
            FINAL_OBSERVATION_SECONDS,float(p["observation_seconds"]),FINAL_OBSERVATION_SECONDS]
    ]

static func current_objective(value: Dictionary, current_population: Dictionary, generation: int) -> String:
    var p: Dictionary = normalize(value)
    if bool(p["complete"]):
        return "FASE 1 COMPLETATA · Nicchia iniziale colonizzata"
    if int(p["player_divisions"]) < 1:
        return "FASE 1 · Nutriti ed effettua la prima scissione"
    if generation < MIN_PLAYER_GENERATION:
        return "FASE 1 · Evolvi la tua linea: ciclo %d/%d" % [generation,MIN_PLAYER_GENERATION]
    if int(p["autonomous_divisions"]) < MIN_AUTONOMOUS_DIVISIONS:
        return "FASE 1 · Le altre cellule devono replicarsi: %d/%d" % [int(p["autonomous_divisions"]),MIN_AUTONOMOUS_DIVISIONS]
    if int(current_population.get("totale",0)) < MIN_LIVING_CELLS:
        return "FASE 1 · Popolazione %d/%d · aumenta nutrienti e discendenza" % [int(current_population.get("totale",0)),MIN_LIVING_CELLS]
    return "FASE 1 · Competizione evolutiva: %.0f/%.0f s" % [
        float(p["observation_seconds"]),FINAL_OBSERVATION_SECONDS]

static func report_lines(value: Dictionary) -> Array[String]:
    var p: Dictionary = normalize(value)
    var data: Dictionary = p["final_report"]
    if data.is_empty():
        return ["Popolazione in evoluzione: campionamento non ancora concluso."]
    var lines: Array[String] = [
        "POPOLAZIONE FINALE · %d cellule vive" % int(data.get("totale",0)),
        "Primi cicli (0–2): %d cellule · %.1f%%" % [int(data.get("prime",0)),float(data.get("prime_pct",0.0))],
        "Cicli intermedi (3–5): %d cellule · %.1f%%" % [int(data.get("intermedie",0)),float(data.get("intermedie_pct",0.0))],
        "Cicli recenti (6+): %d cellule · %.1f%%" % [int(data.get("recenti",0)),float(data.get("recenti_pct",0.0))],
        "Ecotipi: %d raccoglitori · %d esploratori · %d predatori · %d difensori" % [
            int(data.get("raccoglitore",0)),int(data.get("esploratore",0)),
            int(data.get("predatore",0)),int(data.get("difensore",0))]
    ]
    return lines
