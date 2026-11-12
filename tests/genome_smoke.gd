extends SceneTree
const G = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var seed: Dictionary = {
        "motility":1.0,"defense":1.0,"attack":1.0,
        "genome":G.origin(), "mutations":[]
    }
    var primitive: Dictionary = G.normalize(seed)
    assert(G.has(primitive,"rna_replicase"))
    assert(not G.has(primitive,"dna_stabilization"))
    assert(int(primitive.get("pili",-1)) == 0)
    assert(int(primitive.get("vesicles",-1)) == 0)
    assert(int(primitive.get("protease",-1)) == 0)
    assert(int(primitive.get("receptors",-1)) == 0)
    # I punti passivi non creano nulla: solo stats.
    var minor: Dictionary = primitive.duplicate(true)
    minor["motility"] = 1.09
    minor = G.normalize(minor)
    assert(int(minor["pili"]) == 0)
    assert(float(minor["elongation"]) == 0.0)
    var grandparent: Dictionary = G.grant(primitive,"pili_twitch",2,"major_mutation")
    assert(G.allele(grandparent,"pili_twitch") == 1)
    assert(int(grandparent["pili"]) == 2)
    assert(int(primitive["pili"]) == 0)
    var parent: Dictionary = G.grant(grandparent,"surface_recognition",3)
    parent = G.grant(parent,"hydrolase_secretion",4)
    parent = G.grant(parent,"vesicle_pathway",4)
    var sister_a: Dictionary = G.normalize(parent.duplicate(true))
    var sister_b: Dictionary = G.normalize(parent.duplicate(true))
    assert(G.allele(sister_a,"pili_twitch") == 1)
    assert(int(sister_b["receptors"]) == 2)
    assert(int(sister_b["protease"]) == 1 and int(sister_b["vesicles"]) == 1)
    sister_a = G.grant(sister_a,"pili_twitch",5)
    assert(int(sister_a["pili"]) == 4 and int(sister_b["pili"]) == 2)
    var thermophile: Dictionary = G.grant(parent,"thermal_membrane",5)
    thermophile = G.grant(thermophile,"chaperone_complex",5)
    assert(float(thermophile["thermotolerance"]) > 1.4)
    assert(float(parent["thermotolerance"]) == 0.0)
    var bacteria: Dictionary = G.grant(parent,"dna_stabilization",5,"major_mutation","bacteria")
    bacteria = G.grant(bacteria,"flagellar_motor",6,"major_mutation","bacteria")
    assert(int(bacteria["flagella"]) > 0)
    assert(int(bacteria["archaella"]) == 0)
    var archaea: Dictionary = G.grant(parent,"archaellar_motor",6,"major_mutation","archaea")
    assert(int(archaea["archaella"]) > 0)
    assert(int(archaea["flagella"]) == 0)
    var invalid: Dictionary = G.grant(parent,"flagellar_motor",6,"major_mutation","archaea")
    assert(int(invalid["flagella"]) == 0)
    # Simula vecchio salvataggio prima del modello genotipico.
    var legacy: Dictionary = G.normalize({"pili":3,"dna":true,"adhesion":true},"luca")
    assert(G.allele(legacy,"pili_twitch") > 0)
    assert(G.has(legacy,"dna_stabilization"))
    assert(str(legacy["genome"]["loci"]["pili_twitch"]["origin"]) == "legacy_inferred")
    # Saturated branch-specific motors must not waste a random major mutation.
    bacteria = G.grant(bacteria,"flagellar_motor",7,"major_mutation","bacteria")
    archaea = G.grant(archaea,"archaellar_motor",7,"major_mutation","archaea")
    assert(not G.random_candidates("bacteria",bacteria).has("flagellar_motor"))
    assert(not G.random_candidates("archaea",archaea).has("archaellar_motor"))
    for locus in G.COMMON_MAJOR:
        for level in range(int(G.GENE_INFO[locus]["max"])):
            bacteria = G.grant(bacteria,locus,8+level,"major_mutation","bacteria")
    bacteria = G.grant(bacteria,"monoderm_envelope",11,"major_mutation","bacteria")
    assert(G.random_candidates("bacteria",bacteria).is_empty())
    # Diderm may supersede an inherited monoderm; retain genealogy, express one.
    var diderm: Dictionary = G.grant(bacteria,"diderm_envelope",12,"major_mutation","bacteria")
    assert(str(diderm["envelope"]) == "diderm")
    assert(G.expressed_allele(diderm,"monoderm_envelope","bacteria") == 0)
    assert(G.expressed_allele(diderm,"diderm_envelope","bacteria") == 1)
    assert(G.expressed_allele(diderm,"flagellar_motor","archaea") == 0)
    var historical_size: int = diderm["genome"]["history"].size()
    diderm = G.grant(diderm,"monoderm_envelope",13,"major_mutation","bacteria")
    assert(diderm["genome"]["history"].size() == historical_size)
    assert(G.has(diderm,"monoderm_envelope"),"Do not erase ancestral records")
    # Old field-only saves preserve higher module counts and elongated forms.
    var rich_legacy: Dictionary = G.normalize({"transporters":9,"elongation":.8,
        "receptors":6,"flagella":3},"bacteria")
    assert(G.allele(rich_legacy,"membrane_transport") == 3)
    assert(G.allele(rich_legacy,"cell_elongation") == 2)
    assert(G.allele(rich_legacy,"surface_recognition") == 3)
    assert(G.allele(rich_legacy,"flagellar_motor") == 2)
    # Known over-cap alleles never generate unbounded visual module counts.
    var oversized: Dictionary = primitive.duplicate(true)
    oversized["genome"]["loci"]["pili_twitch"] = {"allele":999,"origin":"legacy","generation":2}
    oversized = G.normalize(oversized)
    assert(int(oversized["pili"]) == 6)
    assert(int(oversized["genome"]["loci"]["pili_twitch"]["allele"]) == 999,
        "Read-time bounds must not silently discard original save metadata")
    # Four generations retain distinct inherited combinations after JSON save/load.
    var branches: Array[Dictionary] = [primitive.duplicate(true),primitive.duplicate(true)]
    for generation in range(2,6):
        branches[0] = G.grant(branches[0],"pili_twitch",generation)
        branches[1] = G.grant(branches[1],"vesicle_pathway",generation)
        branches[0] = G.normalize(JSON.parse_string(JSON.stringify(branches[0])))
        branches[1] = G.normalize(JSON.parse_string(JSON.stringify(branches[1])))
        assert(G.has(branches[0],"pili_twitch") and not G.has(branches[0],"vesicle_pathway"))
        assert(G.has(branches[1],"vesicle_pathway") and not G.has(branches[1],"pili_twitch"))
    assert(int(primitive["pili"]) == 0 and int(primitive["vesicles"]) == 0)
    print("PASS: genotype, major loci, stat-only small changes, daughter inheritance across generations, caps, branch expression and legacy migration")
    quit(0)
