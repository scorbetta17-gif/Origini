extends SceneTree
const VISUAL = preload("res://src/cell_visual.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var visual = VISUAL.new()
    root.add_child(visual)
    visual.setup({},"pre_luca")
    assert(not visual.feature_nodes.has("nucleus"))
    assert(is_instance_valid(visual.replication_source))
    visual.set_division_progress(-10)
    assert(visual.division_progress==0.0 and not visual.replication_copy.visible)
    visual.set_division_progress(3)
    assert(visual.division_progress==1.0 and visual.replication_copy.visible)
    assert(is_equal_approx(float(visual.membrane.material_override.get_shader_parameter("division_progress")),1.0))
    assert(visual.replication_copy.position.x>visual.replication_source.position.x)
    var capabilities: Dictionary = {}
    for id in ["asgard_host","internal_symbiont","mitochondrion","membrane_traffic","er_golgi","nucleus","leca"]:
        capabilities[id] = true
    visual.setup({"dna":true,"evolution_capabilities":capabilities},"archaea")
    for id in capabilities:
        assert(visual.feature_nodes.has(id))
        assert(visual.find_child("Evolution_"+id,true,false)!=null)
    assert(visual.find_child("DNA_DoubleStrand",true,false)!=null)
    assert(visual.find_child("Accessory_RNA",true,false)!=null)
    assert(visual.find_child("Evolution_er_golgi",true,false).get_child_count()==7)
    assert(visual.find_child("Evolution_mitochondrion",true,false).get_child_count()==5)
    assert(visual.find_children("*","MeshInstance3D",true,false).size()<120)
    visual.set_division_progress(.6)
    assert(visual.replication_copy.visible)
    visual.set_division_progress(0)
    assert(not visual.replication_copy.visible)
    print("PASS: capability-gated phenotypes, RNA/DNA inheritance, bounded fission and replication, bounded geometry")
    quit(0)

