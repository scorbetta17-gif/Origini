extends SceneTree
const Gallery = preload("res://src/gallery.gd")
const Genome = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    var examples: Array[Dictionary] = Gallery.variants()
    assert(examples.size() == 8)
    var represented: Dictionary = {}
    var signatures: Dictionary = {}
    for example in examples:
        var traits: Dictionary = Gallery.traits_for_variant(example)
        var branch: String = str(example["branch"])
        var signature: String = branch
        for locus in Genome.GENE_INFO:
            var level: int = Genome.expressed_allele(traits,locus,branch)
            if level>0:
                represented[locus] = true
                signature += "|%s:%d" % [locus,level]
        signatures[signature] = true
    assert(represented.size() == Genome.GENE_INFO.size(),"Gallery must demonstrate all 16 existing loci")
    assert(signatures.size() == 8,"All gallery cells must have genuinely different genotypes")
    var rna: Dictionary = Gallery.traits_for_variant(examples[0])
    var dna: Dictionary = Gallery.traits_for_variant(examples[1])
    var secretion: Dictionary = Gallery.traits_for_variant(examples[5])
    var transport: Dictionary = Gallery.traits_for_variant(examples[7])
    assert(not rna["dna"] and dna["dna"])
    assert(secretion["protease"] == 2 and secretion["vesicles"] == 2)
    assert(transport["transporters"] == 9 and transport["eps"])
    print("PASS: eight distinct gallery genotypes, all 16 loci, no stat-only mock phenotypes")
    quit(0)
