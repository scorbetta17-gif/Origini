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
    print("PASS: genotype, major loci, stat-only small changes, daughter inheritance, legacy migration")
    quit(0)
