extends RefCounted
class_name PhaseTwoProgress
## Stato della Fase 2: associazioni procariotiche, non endosimbiosi.
## Tutte le soglie temporali sono in secondi di contatto reale, non elapsed globale.
const DETECT_RADIUS: float = 8.0
const BOND_RADIUS: float = 4.1
const EXCHANGE_RADIUS: float = 3.7
const EXCHANGE_REQUIRED: float = 12.0
const STABILITY_REQUIRED: float = 25.0

static func empty() -> Dictionary:
    return {
        "discovered":false, "adhesion":false, "exchanged":false,
        "stable":false, "transmitted":false, "complete":false,
        "partner_id":"", "last_partner_id":"", "bonded":false,
        "active_stable":false,
        "exchange_seconds":0.0, "contact_seconds":0.0,
        "metabolites_exchanged":0.0, "transmitted_from":"",
        "generation_completed":-1
    }

static func normalize(source: Dictionary) -> Dictionary:
    var result: Dictionary = empty()
    for key in result:
        if source.has(key):
            result[key] = source[key]
    result["exchange_seconds"] = maxf(0.0,float(result["exchange_seconds"]))
    result["contact_seconds"] = maxf(0.0,float(result["contact_seconds"]))
    result["metabolites_exchanged"] = maxf(0.0,float(result["metabolites_exchanged"]))
    if not source.has("active_stable"):
        result["active_stable"] = bool(result["stable"]) and bool(result["bonded"]) and (
            float(result["contact_seconds"]) >= STABILITY_REQUIRED and float(result["exchange_seconds"]) >= EXCHANGE_REQUIRED)
    if bool(result["transmitted"]):
        result["stable"] = true
        result["exchanged"] = true
        result["adhesion"] = true
        result["discovered"] = true
        result["complete"] = true
    return result

static func observe(source: Dictionary, other_branch: String, other_id: String, distance: float) -> Dictionary:
    var result: Dictionary = normalize(source)
    if other_branch == "bacteria" and other_id != "" and distance <= DETECT_RADIUS:
        result["discovered"] = true
        if str(result["last_partner_id"]) == "":
            result["last_partner_id"] = other_id
    return result

static func can_adhere(archaeal_traits: Dictionary, bacterial_traits: Dictionary) -> bool:
    # Riconoscimento superficiale su entrambi; EPS archeale alternativa
    # meccanica al recettore archeale, ma non una fusione cellulare.
    var archaeological_anchor: bool = bool(archaeal_traits.get("adhesion",false)) or bool(archaeal_traits.get("eps",false))
    var bacterial_anchor: bool = bool(bacterial_traits.get("adhesion",false))
    return archaeological_anchor and bacterial_anchor

static func can_exchange(archaeal_traits: Dictionary, bacterial_traits: Dictionary) -> bool:
    return int(archaeal_traits.get("transporters",0)) > 0 and int(bacterial_traits.get("transporters",0)) > 0

static func bind(source: Dictionary, archaeal_traits: Dictionary, bacterial_traits: Dictionary, other_id: String, distance: float) -> Dictionary:
    var result: Dictionary = normalize(source)
    if other_id == "" or distance > BOND_RADIUS or not can_adhere(archaeal_traits,bacterial_traits):
        return result
    result["discovered"] = true
    result["adhesion"] = true
    result["bonded"] = true
    result["active_stable"] = false
    result["partner_id"] = other_id
    result["last_partner_id"] = other_id
    result["contact_seconds"] = 0.0
    result["exchange_seconds"] = 0.0
    return result

static func release(source: Dictionary) -> Dictionary:
    var result: Dictionary = normalize(source)
    result["partner_id"] = ""
    result["bonded"] = false
    result["active_stable"] = false
    result["contact_seconds"] = 0.0
    result["exchange_seconds"] = 0.0
    return result

static func advance(source: Dictionary, dt: float, distance: float,
                    archaeal_traits: Dictionary, bacterial_traits: Dictionary,
                    available_carbon: float, bacterial_energy: float) -> Dictionary:
    var progress: Dictionary = normalize(source)
    var result: Dictionary = {
        "progress":progress, "carbon_cost":0.0, "atp_gain":0.0,
        "bacterial_energy_delta":0.0, "bacterial_biomass_gain":0.0,
        "exchange_active":false
    }
    if not bool(progress["bonded"]) or str(progress["partner_id"]) == "":
        return result
    if not can_adhere(archaeal_traits,bacterial_traits) or distance > EXCHANGE_RADIUS:
        progress["active_stable"] = false
        progress["contact_seconds"] = maxf(0.0,float(progress["contact_seconds"])-dt*1.3)
        progress["exchange_seconds"] = maxf(0.0,float(progress["exchange_seconds"])-dt*.55)
        if distance > DETECT_RADIUS or not can_adhere(archaeal_traits,bacterial_traits):
            result["progress"] = release(progress)
        return result
    progress["contact_seconds"] = float(progress["contact_seconds"])+maxf(0.0,dt)
    if can_exchange(archaeal_traits,bacterial_traits) and available_carbon >= .1 and bacterial_energy >= 4.0:
        var shared: float = minf(.10*dt,available_carbon)
        var donor_cost: float = minf(.22*dt,bacterial_energy-4.0)
        if shared > 0.0 and donor_cost > 0.0:
            result["exchange_active"] = true
            result["carbon_cost"] = shared
            result["atp_gain"] = donor_cost*2.7
            # Rappresentazione astratta di scambio di substrati/metaboliti:
            # Archaea cede substrati carboniosi, Bacteria cede prodotti catabolici.
            result["bacterial_energy_delta"] = shared*2.8-donor_cost
            result["bacterial_biomass_gain"] = shared*.14
            progress["metabolites_exchanged"] = float(progress["metabolites_exchanged"])+shared+donor_cost
            progress["exchange_seconds"] = float(progress["exchange_seconds"])+maxf(0.0,dt)
            if float(progress["exchange_seconds"]) >= EXCHANGE_REQUIRED:
                progress["exchanged"] = true
    if bool(progress["exchanged"]) and float(progress["contact_seconds"]) >= STABILITY_REQUIRED:
        progress["stable"] = true
        progress["active_stable"] = true
    return result

static func inherit(source: Dictionary, daughter_traits: Dictionary,
                    partner_alive: bool, mother_id: String, generation: int) -> Dictionary:
    var progress: Dictionary = normalize(source)
    var inherited_ability: bool = bool(daughter_traits.get("adhesion",false)) or bool(daughter_traits.get("eps",false))
    inherited_ability = inherited_ability and int(daughter_traits.get("transporters",0)) > 0
    if bool(progress["stable"]) and bool(progress["active_stable"]) and partner_alive and inherited_ability and bool(progress["bonded"]):
        progress["transmitted"] = true
        progress["complete"] = true
        progress["transmitted_from"] = mother_id
        progress["generation_completed"] = generation
        progress["contact_seconds"] = 0.0
        progress["exchange_seconds"] = 0.0
    else:
        progress = release(progress)
    return progress

static func objective_lines(source: Dictionary) -> Array[String]:
    var p: Dictionary = normalize(source)
    var stages: Array[String] = []
    stages.append(("✓" if bool(p["discovered"]) else "○")+"  1/5  Riconosci una cellula Bacteria indipendente")
    stages.append(("✓" if bool(p["adhesion"]) else "○")+"  2/5  Attiva adesione reciproca")
    stages.append(("✓" if bool(p["exchanged"]) else "○")+"  3/5  Scambia metaboliti 12 s (%.1f/12)" % minf(EXCHANGE_REQUIRED,float(p["exchange_seconds"])))
    stages.append(("✓" if bool(p["stable"]) else "○")+"  4/5  Mantieni il consorzio 25 s (%.1f/25)" % minf(STABILITY_REQUIRED,float(p["contact_seconds"])))
    stages.append(("✓" if bool(p["transmitted"]) else "○")+"  5/5  Trasmetti la cooperazione a una figlia")
    return stages

static func short_objective(source: Dictionary) -> String:
    var p: Dictionary = normalize(source)
    if bool(p["complete"]):
        return "FASE 2 COMPLETATA · Consorzio metabolico trasmesso"
    if not bool(p["discovered"]):
        return "FASE 2 · Cerca una cellula Bacteria (non discende da Archaea)"
    if not bool(p["adhesion"]):
        return "FASE 2 · Evolvi recettori/EPS e scegli COOPERA vicino a Bacteria"
    if not bool(p["exchanged"]):
        if not bool(p["bonded"]):
            return "FASE 2 · Riavvicinati alla Bacteria e ripristina l'adesione"
        return "FASE 2 · Trasportatori su entrambe le cellule: %.0f/12 s" % float(p["exchange_seconds"])
    if not bool(p["stable"]):
        return "FASE 2 · Mantieni l'aggregato: %.0f/25 s" % float(p["contact_seconds"])
    if not bool(p["active_stable"]):
        return "FASE 2 · Riattiva il consorzio stabile prima della scissione"
    return "FASE 2 · Consorzio stabile: completa una scissione e scegli una figlia"
