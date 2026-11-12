extends SceneTree
const G = preload("res://src/cell_genome.gd")
const V = preload("res://src/cell_visual.gd")

func _initialize() -> void:
    call_deferred("_run")

func _rendered_meshes(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D and node.visible and node.mesh != null else 0
    for child in node.get_children():
        count += _rendered_meshes(child)
    return count

func _run() -> void:
    var origin: Dictionary = G.normalize({"genome":G.origin()})
    var visual: Node3D = V.new()
    root.add_child(visual)
    var visited: Dictionary = {}
    for locus in G.GENE_INFO:
        var branch: String = "archaea" if locus in ["archaellar_motor","archaeal_envelope"] else "bacteria" if locus in ["flagellar_motor","monoderm_envelope","diderm_envelope"] else "pre_luca"
        var traits: Dictionary = origin.duplicate(true)
        for level in range(1,int(G.GENE_INFO[locus]["max"])+1):
            if locus != "rna_replicase":
                traits = G.grant(traits,locus,level,"phenotype_test",branch)
            visual.setup(traits,branch,false)
            assert(visual.feature_nodes.has(locus),"Missing visible phenotype for "+locus)
            var feature: Dictionary = visual.feature_nodes[locus]
            assert(int(feature["allele"])==level)
            assert(not feature["nodes"].is_empty())
            var meshes: int = 0
            for node in feature["nodes"]:
                assert(is_instance_valid(node) and node.is_inside_tree())
                meshes += _rendered_meshes(node)
            assert(meshes>0,"Registry must refer to actual rendered geometry: "+locus)
            if locus == "cell_elongation":
                assert(visual.body_radii.x>visual.body_radii.z)
            if locus == "dna_stabilization":
                assert(visual.find_child("DNA_DoubleStrand",true,false)!=null)
                assert(visual.find_child("Accessory_RNA",true,false)!=null,"DNA must not eliminate all RNA")
            if locus == "monoderm_envelope":
                assert(visual.find_child("OuterMembrane",true,false)==null,"A lipid bilayer is not two cell membranes")
            visited[locus] = true
            await process_frame
    assert(visited.size()==16)
    # The two thermal adaptations are independent visual structures.
    var thermal: Dictionary = G.grant(origin,"thermal_membrane",2)
    visual.setup(thermal,"pre_luca")
    assert(visual.feature_nodes.has("thermal_membrane"))
    assert(not visual.feature_nodes.has("chaperone_complex"))
    var protected: Dictionary = G.grant(origin,"chaperone_complex",2)
    visual.setup(protected,"pre_luca")
    assert(visual.feature_nodes.has("chaperone_complex"))
    assert(not visual.feature_nodes.has("thermal_membrane"))
    # Sisters inherit the same structure; a later macro mutation changes one.
    var parent: Dictionary = G.grant(origin,"membrane_transport",2)
    parent = G.grant(parent,"surface_recognition",3)
    var sister_a: Dictionary = G.normalize(parent.duplicate(true))
    var sister_b: Dictionary = G.normalize(parent.duplicate(true))
    visual.setup(sister_a,"pre_luca")
    var expected: int = visual.feature_nodes["membrane_transport"]["nodes"].size()
    visual.setup(sister_b,"pre_luca")
    assert(visual.feature_nodes["membrane_transport"]["nodes"].size()==expected)
    sister_a = G.grant(sister_a,"membrane_transport",4)
    visual.setup(sister_a,"pre_luca")
    assert(visual.feature_nodes["membrane_transport"]["nodes"].size()>expected)
    visual.setup(origin,"pre_luca")
    assert(visual.feature_nodes.size()==1 and visual.feature_nodes.has("rna_replicase"),"Rebuilding must remove old gene modules")
    assert(visual.find_child("DNA_DoubleStrand",true,false)==null)
    assert(visual.find_child("Chaperone_CytosolicComplexes",true,false)==null)
    visual.queue_free()
    print("PASS: all 16 major loci and allele levels have real 3D phenotypes; independent thermal adaptations and inherited sister differences")
    quit(0)
