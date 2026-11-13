extends RefCounted
class_name CellGenome
## ORIGINI — Genotipo funzionale (semplificazione ludica).
## Le mutazioni maggiori sono loci ereditabili, non meri incrementi numerici.
## I piccoli modificatori di stat non richiedono nuove strutture o loci nominati.
const VERSION: int = 1
const GENE_INFO: Dictionary = {
    "rna_replicase": {"name":"Sistema RNA autocatalitico","max":1},
    "dna_stabilization": {"name":"Stabilizzazione DNA","max":1},
    "membrane_transport": {"name":"Complesso di trasporto","max":3},
    "surface_recognition": {"name":"Recettori di riconoscimento","max":3},
    "pili_twitch": {"name":"Pili con ancoraggio e trazione","max":3},
    "hydrolase_secretion": {"name":"Idrolasi e recupero molecolare","max":3},
    "vesicle_pathway": {"name":"Via di secrezione vescicolare","max":3},
    "eps_biosynthesis": {"name":"Biosintesi matrice EPS","max":1},
    "thermal_membrane": {"name":"Lipidi di membrana termostabili","max":3},
    "chaperone_complex": {"name":"Proteostasi e chaperoni","max":3},
    "cell_elongation": {"name":"Organizzazione della forma cellulare","max":2},
    "monoderm_envelope": {"name":"Involucro monoderma","max":1},
    "diderm_envelope": {"name":"Involucro diderma","max":1},
    "archaeal_envelope": {"name":"Involucro archeale","max":1},
    "flagellar_motor": {"name":"Apparato flagellare batterico","max":2},
    "archaellar_motor": {"name":"Apparato archaellare","max":2}
}
const COMMON_MAJOR: Array[String] = [
    "membrane_transport","surface_recognition","pili_twitch",
    "hydrolase_secretion","vesicle_pathway","eps_biosynthesis",
    "thermal_membrane","chaperone_complex","cell_elongation"
]

static func origin() -> Dictionary:
    return {"version":VERSION,"loci":{
        "rna_replicase":{"allele":1,"origin":"origine","generation":0}
    },"history":[]}

static func allele(traits: Dictionary, locus: String) -> int:
    var genome: Dictionary = traits.get("genome",{})
    var loci: Dictionary = genome.get("loci",{})
    var entry: Dictionary = loci.get(locus,{})
    var value: int = maxi(0,int(entry.get("allele",0)))
    return mini(value,int(GENE_INFO[locus]["max"])) if GENE_INFO.has(locus) else value

static func expressed_allele(traits: Dictionary, locus: String, branch: String = "pre_luca") -> int:
    # Keep inherited records intact; only compatible structures are expressed.
    if locus in ["flagellar_motor","monoderm_envelope","diderm_envelope"] and branch != "bacteria":
        return 0
    if locus in ["archaellar_motor","archaeal_envelope"] and branch != "archaea":
        return 0
    # Older saves can contain both loci. Diderm describes the active envelope;
    # retaining monoderm history does not mean drawing a third membrane.
    if locus == "monoderm_envelope" and has(traits,"diderm_envelope"):
        return 0
    return allele(traits,locus)

static func has(traits: Dictionary, locus: String) -> bool:
    return allele(traits,locus) > 0

static func _legacy(traits: Dictionary, branch: String) -> Dictionary:
    var loci: Dictionary = origin()["loci"].duplicate(true)
    # Migrazione esplicita: il gene e' inferito da una vecchia proprieta' salvata,
    # NON confuso con una sequenza genetica ricostruita scientificamente.
    var hints: Dictionary = {
        "dna_stabilization": 1 if bool(traits.get("dna",false)) else 0,
        "surface_recognition": mini(3,maxi(1 if bool(traits.get("adhesion",false)) else 0,
            int(ceil(float(traits.get("receptors",0))/2.0)))),
        "membrane_transport": mini(3,int(ceil(float(traits.get("transporters",0))/3.0))),
        "cell_elongation": mini(2,int(ceil(float(traits.get("elongation",0.0))/.40))),
        "pili_twitch": mini(3,int(ceil(float(traits.get("pili",0))/2.0))),
        "hydrolase_secretion": mini(3,int(traits.get("protease",0))),
        "vesicle_pathway": mini(3,int(traits.get("vesicles",0))),
        "eps_biosynthesis": 1 if bool(traits.get("eps",false)) else 0,
        "thermal_membrane": mini(3,int(ceil(float(traits.get("thermotolerance",0.0))))),
        "flagellar_motor": mini(2,maxi(1,int(traits.get("flagella",0))-1)) if int(traits.get("flagella",0)) > 0 else 0,
        "archaellar_motor": mini(2,maxi(1,int(traits.get("archaella",0))-1)) if int(traits.get("archaella",0)) > 0 else 0,
        "diderm_envelope": 1 if str(traits.get("envelope","")) == "diderm" else 0,
        "monoderm_envelope": 1 if str(traits.get("envelope","")) == "monoderm" else 0,
        "archaeal_envelope": 1 if branch == "archaea" else 0
    }
    for id in hints:
        if int(hints[id]) > 0:
            loci[id] = {"allele":int(hints[id]),"origin":"legacy_inferred","generation":-1}
    return {"version":VERSION,"loci":loci,"history":[]}

static func normalize(traits: Dictionary, branch: String = "pre_luca") -> Dictionary:
    var result: Dictionary = traits.duplicate(true)
    var genome: Dictionary = result.get("genome",{})
    if not genome.has("loci"):
        genome = _legacy(result,branch)
    else:
        genome = genome.duplicate(true)
        if not genome.has("history"):
            genome["history"] = []
    result["genome"] = genome
    return express(result,branch)

static func grant(traits: Dictionary, locus: String, generation: int, origin_type: String = "major_mutation", branch: String = "pre_luca") -> Dictionary:
    var result: Dictionary = normalize(traits,branch)
    if not GENE_INFO.has(locus):
        return result
    if locus == "flagellar_motor" and branch != "bacteria":
        return result
    if locus == "archaellar_motor" and branch != "archaea":
        return result
    if locus == "archaeal_envelope" and branch != "archaea":
        return result
    if (locus == "monoderm_envelope" or locus == "diderm_envelope") and branch != "bacteria":
        return result
    if locus == "monoderm_envelope" and has(result,"diderm_envelope"):
        return result
    var genome: Dictionary = result["genome"]
    var loci: Dictionary = genome["loci"]
    var current: int = allele(result,locus)
    var cap: int = int(GENE_INFO[locus]["max"])
    if current >= cap:
        return result
    var new_level: int = current+1
    loci[locus] = {"allele":new_level,"origin":origin_type,"generation":generation}
    genome["loci"] = loci
    var history: Array = genome.get("history",[])
    history.append({"locus":locus,"allele":new_level,"generation":generation,"origin":origin_type})
    genome["history"] = history
    result["genome"] = genome
    return express(result,branch)

static func express(traits: Dictionary, branch: String = "pre_luca") -> Dictionary:
    # SOLO il genoma maggiore controlla nuovi moduli strutturali.
    var result: Dictionary = traits.duplicate(true)
    result["dna"] = has(result,"dna_stabilization")
    result["pili"] = allele(result,"pili_twitch")*2
    result["receptors"] = allele(result,"surface_recognition")*2
    result["adhesion"] = has(result,"surface_recognition")
    result["protease"] = allele(result,"hydrolase_secretion")
    result["vesicles"] = allele(result,"vesicle_pathway")
    result["eps"] = has(result,"eps_biosynthesis")
    result["transporters"] = allele(result,"membrane_transport")*3
    result["elongation"] = float(allele(result,"cell_elongation"))*.40
    result["thermotolerance"] = float(allele(result,"thermal_membrane"))*.8 + float(allele(result,"chaperone_complex"))*.65
    result["flagella"] = (1+allele(result,"flagellar_motor")) if branch == "bacteria" and has(result,"flagellar_motor") else 0
    result["archaella"] = (1+allele(result,"archaellar_motor")) if branch == "archaea" and has(result,"archaellar_motor") else 0
    result["envelope"] = "diderm" if branch == "bacteria" and has(result,"diderm_envelope") else (
        "monoderm" if branch == "bacteria" and has(result,"monoderm_envelope") else (
        "archaeal" if branch == "archaea" and has(result,"archaeal_envelope") else "none"))
    return result

static func random_candidates(branch: String, traits: Dictionary) -> Array[String]:
    var items: Array[String] = []
    for locus in COMMON_MAJOR:
        if allele(traits,locus) < int(GENE_INFO[locus]["max"]):
            items.append(locus)
    if branch == "bacteria":
        if allele(traits,"flagellar_motor") < int(GENE_INFO["flagellar_motor"]["max"]):
            items.append("flagellar_motor")
        if allele(traits,"monoderm_envelope") == 0 and allele(traits,"diderm_envelope") == 0:
            items.append("monoderm_envelope")
    elif branch == "archaea":
        if allele(traits,"archaellar_motor") < int(GENE_INFO["archaellar_motor"]["max"]):
            items.append("archaellar_motor")
    return items

static func describe(traits: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for locus in GENE_INFO:
        var level: int = allele(traits,locus)
        if level > 0:
            result.append("%s  ·  allele %d" % [str(GENE_INFO[locus]["name"]),level])
    return result
