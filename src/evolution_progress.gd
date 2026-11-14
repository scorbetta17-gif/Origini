extends RefCounted
class_name EvolutionProgress
## Functional-capacity DAG. Costs and generation thresholds are GAMEPLAY.
## Never migrate an external association into an internal organelle.
const VERSION: int = 1

static func catalogue() -> Array[Dictionary]:
    return [
        _entry("cell_zero","Cellula Zero",0,[],"GAMEPLAY","Protocellula narrativa con compartimento e RNA.",0),
        _entry("rna_inheritance","Ereditarieta RNA",2,["cell_zero"],"PLAUSIBLE","Copia e trasmissione di RNA; ordine storico aperto.",2),
        _entry("dormancy","Dormienza reversibile",2,["rna_inheritance"],"GAMEPLAY","Riposo minimo 12 s; risparmio ATP, nessuna immunità termica.",2),
        _entry("translation","Traduzione",3,["rna_inheritance"],"CONSENSUS","Capacita di traduzione, precedente alla divergenza dei domini.",5),
        _entry("dna_archive","Archivio DNA",3,["translation"],"PLAUSIBLE","Deposito, copia e segregazione del genoma distinti.",8),
        _entry("bioenergetics","Bioenergetica di membrana",3,["translation"],"CONSENSUS","Trasporto e gradienti energetici integrati.",10),
        _entry("luca","Popolazione LUCA",4,["dna_archive","bioenergetics"],"CONSENSUS","Ultimo antenato comune ricostruito, non prima cellula.",16),
        _entry("bacteria","Linea Bacteria",3,["luca"],"CONSENSUS","Ramo autonomo; puo fornire un partner ad altra linea.",20),
        _entry("archaea","Linea Archaea",3,["luca"],"CONSENSUS","Ramo ospite del percorso eucariotico.",20),
        _entry("prokaryotic_groups","Aggregati procariotici",3,["luca"],"PLAUSIBLE","Adesione o separazione incompleta: nessuna fusione delle genealogie.",24),
        _entry("differentiated_groups","Gruppi differenziati",4,["prokaryotic_groups"],"PLAUSIBLE","Divisione del lavoro procariotica; ramo opzionale autonomo.",30),
        _entry("alpha_partner","Partner di affinita alfa",4,["bacteria"],"PLAUSIBLE","Linea batterica autonoma compatibile; non e un organello.",26),
        _entry("asgard_host","Ospite affine agli Asgard",4,["archaea"],"CONSENSUS","Affinita filogenetica; la forma dell'ospite ancestrale e inferita.",26),
        _entry("cytoskeleton","Citoscheletro e protrusioni",3,["asgard_host"],"PLAUSIBLE","Analoghi moderni ispirano protrusioni; non implicano fagocitosi moderna.",29),
        _entry("membrane_traffic","Traffico di membrane",4,["cytoskeleton"],"PLAUSIBLE","Compartimenti e smistamento; ordine rispetto alla simbiosi aperto.",32),
        _entry("stable_consortium","Consorzio esterno stabile",4,["cytoskeleton"],"PLAUSIBLE","Partner batterico indipendente, scambio e co-localizzazione ripetuti.",32),
        _entry("internal_symbiont","Simbionte interno ereditabile",5,["stable_consortium","membrane_traffic"],"CONTROVERSIAL","Ingresso modellato come scenario; distinto dalla semplice adesione.",38),
        _entry("nucleus","Nucleo e scambio regolato",4,["membrane_traffic"],"PLAUSIBLE","Compartimentazione genomica e trasporto regolato.",40),
        _entry("er_golgi","Reticolo e Golgi",4,["membrane_traffic"],"PLAUSIBLE","Ricezione, modifica, smistamento e riciclo; non frammenti di cellula lisata.",42),
        _entry("protein_import","Import proteico",3,["internal_symbiont"],"CONSENSUS","Import di proteine prodotte dall'ospite nel simbionte.",40),
        _entry("metabolic_integration","Integrazione metabolica",3,["internal_symbiont","bioenergetics"],"CONSENSUS","Scambi energetici e biosintetici coordinati con l'ospite.",42),
        _entry("coordinated_division","Divisione coordinata",3,["internal_symbiont"],"CONSENSUS","Coordinamento della replicazione e trasmissione del simbionte.",44),
        _entry("mitochondrion","Mitocondrio integrato",6,["internal_symbiont","protein_import","metabolic_integration","coordinated_division"],"CONSENSUS","Import proteico, integrazione metabolica e trasmissione coordinata.",48),
        _entry("leca","Traguardo di tipo LECA",8,["mitochondrion","nucleus","er_golgi"],"CONSENSUS","Eucariote unicellulare con sistemi funzionali ereditabili; soglie ludiche.",60)
    ]

static func _entry(id: String, label: String, cost: int, requires: Array, confidence: String, description: String, divisions: int) -> Dictionary:
    return {"id":id,"label":label,"cost":cost,"requires":requires,"confidence":confidence,
        "description":description,"min_divisions":divisions}

static func origin() -> Dictionary:
    return {"version":VERSION,"unlocks":{"cell_zero":true},"divisions":0,
        "stability":{"external":0,"internal":0,"integrated":0,"leca":0},
        "evidence":{},"last_division_id":"","stage":"cell_zero"}

static func normalize(data: Dictionary) -> Dictionary:
    var result: Dictionary = data.duplicate(true)
    var defaults: Dictionary = origin()
    for key in defaults:
        if not result.has(key):
            result[key] = defaults[key]
    for key in ["unlocks","stability","evidence"]:
        if not result[key] is Dictionary:
            result[key] = defaults[key]
    result["version"] = VERSION
    result["divisions"] = maxi(0,int(result["divisions"]))
    result["unlocks"]["cell_zero"] = true
    for key in defaults["stability"]:
        result["stability"][key] = maxi(0,int(result["stability"].get(key,0)))
    result["stage"] = "cell_zero"
    for entry in catalogue():
        if bool(result["unlocks"].get(entry["id"],false)):
            result["stage"] = entry["id"]
    return result

static func _find(id: String) -> Dictionary:
    for entry in catalogue():
        if entry["id"] == id:
            return entry
    return {}

static func _external(context: Dictionary) -> bool:
    return bool(context.get("external_partner_alive",false)) and str(context.get("partner_id","")) != "" and str(context.get("partner_branch","")) == "bacteria" and bool(context.get("exchange_active",false))

static func can_unlock(data: Dictionary, id: String, _traits: Dictionary = {}, context: Dictionary = {}) -> bool:
    var state: Dictionary = normalize(data)
    var entry: Dictionary = _find(id)
    if entry.is_empty() or bool(state["unlocks"].get(id,false)):
        return false
    if int(state["divisions"]) < int(entry["min_divisions"]):
        return false
    for requirement in entry["requires"]:
        if not bool(state["unlocks"].get(requirement,false)):
            return false
    if id == "bacteria" and bool(state["unlocks"].get("archaea",false)):
        return false
    if id == "archaea" and bool(state["unlocks"].get("bacteria",false)):
        return false
    var evidence: Dictionary = state["evidence"] if context.is_empty() else context
    var stable: Dictionary = state["stability"]
    if id == "stable_consortium":
        return _external(evidence) and int(stable["external"]) >= 3
    if id == "internal_symbiont":
        return _external(evidence) and int(stable["external"]) >= 6
    if id == "mitochondrion":
        return int(stable["internal"]) >= 6 and int(stable["integrated"]) >= 4
    if id == "leca":
        return int(stable["leca"]) >= 8
    return true

static func unlock(data: Dictionary, id: String) -> Dictionary:
    var result: Dictionary = normalize(data)
    if not can_unlock(result,id):
        return result
    result["unlocks"][id] = true
    return normalize(result)

static func on_division(data: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result: Dictionary = normalize(data)
    var event_id: String = str(context.get("division_id",""))
    if event_id != "" and event_id == str(result["last_division_id"]):
        return result
    result["last_division_id"] = event_id
    result["divisions"] = int(result["divisions"])+1
    var evidence: Dictionary = {}
    for key in ["external_partner_alive","partner_id","partner_branch","exchange_active","internal_transmitted","protein_import","metabolic_integration","coordinated_division","membrane_traffic_functional","nuclear_transport_functional"]:
        if context.has(key):
            evidence[key] = context[key]
    var same_partner: bool = str(evidence.get("partner_id","")) == str(result["evidence"].get("partner_id",""))
    result["evidence"] = evidence
    var stable: Dictionary = result["stability"]
    var unlocked: Dictionary = result["unlocks"]
    var external: bool = _external(evidence) and bool(unlocked.get("cytoskeleton",false))
    stable["external"] = (int(stable["external"])+1 if same_partner else 1) if external else 0
    var internal: bool = bool(unlocked.get("internal_symbiont",false)) and bool(evidence.get("internal_transmitted",false))
    stable["internal"] = int(stable["internal"])+1 if internal else 0
    var integrated: bool = internal and bool(evidence.get("protein_import",false)) and bool(evidence.get("metabolic_integration",false)) and bool(evidence.get("coordinated_division",false))
    stable["integrated"] = int(stable["integrated"])+1 if integrated else 0
    var complete: bool = integrated and bool(unlocked.get("mitochondrion",false)) and bool(unlocked.get("nucleus",false)) and bool(unlocked.get("er_golgi",false)) and bool(evidence.get("membrane_traffic_functional",false)) and bool(evidence.get("nuclear_transport_functional",false))
    stable["leca"] = int(stable["leca"])+1 if complete else 0
    return normalize(result)

static func status(data: Dictionary) -> Dictionary:
    var state: Dictionary = normalize(data)
    var available: Array[String] = []
    for entry in catalogue():
        if can_unlock(state,entry["id"]):
            available.append(entry["id"])
    return {"stage":state["stage"],"divisions":state["divisions"],
        "stability":state["stability"].duplicate(true),"available":available,
        "complete":bool(state["unlocks"].get("leca",false))}
