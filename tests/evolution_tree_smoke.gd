extends SceneTree
const EvolutionView = preload("res://src/evolution_tree.gd")
const Progress = preload("res://src/evolution_progress.gd")
var requests: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tree := EvolutionView.new()
    tree.size = Vector2(1280,800)
    var state: Dictionary = Progress.origin()
    state.divisions = 3
    tree.configure(state,10.5)
    root.add_child(tree)
    await process_frame
    tree.fit_graph()
    assert(tree.node_positions.size()==Progress.catalogue().size())
    for entry in Progress.catalogue():
        assert(tree.node_positions.has(entry.id))
        assert(tree.graph_rect().has_point(tree.screen_position(entry.id)),"Every catalogue node appears in fit view")
    tree.capability_requested.connect(func(id: String): requests.append(id))
    tree.focus_node("rna_inheritance")
    assert(tree.locked_reasons("rna_inheritance").is_empty())
    tree.call("_request_purchase")
    assert(requests == ["rna_inheritance"])
    assert(is_equal_approx(tree.points,10.5) and not tree.state.unlocks.has("rna_inheritance"),"Signal does not spend wallet or mutate progression")
    tree.focus_node("leca")
    tree.call("_request_purchase")
    assert(requests.size()==1 and not tree.locked_reasons("leca").is_empty())
    tree.size = Vector2(390,844)
    tree.fit_graph()
    await process_frame
    for entry in Progress.catalogue():
        assert(tree.graph_rect().has_point(tree.screen_position(entry.id)))
    assert(tree._purchase.size.y>=44 and tree._card.size.x<=390)
    print("PASS: evolutionary DAG nodes, mobile fit, inspect lock reasons, purchase signal without wallet mutation")
    tree.queue_free()
    quit(0)
