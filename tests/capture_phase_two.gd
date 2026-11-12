extends SceneTree
const G = preload("res://src/cell_genome.gd")
var game: Node
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    root.size=Vector2i(720,1280)
    root.content_scale_size=root.size
    game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.call("_close_overlay")
    game.phase1_progress.complete=true
    var traits: Dictionary = game.call("_base_traits")
    for locus in ["dna_stabilization","archaeal_envelope","surface_recognition","membrane_transport"]:
        traits=G.grant(traits,locus,6,"capture","archaea")
    game.call("_create_entity","A-010","",6,"archaea",traits,Vector3.ZERO,false,true)
    game.call("_activate_lineage","A-010")
    game.next_id=11
    game.call("_create_external_bacterium")
    game.call("_on_cooperate")
    for i in range(530): game.call("_process",.05)
    game.call("_refresh_hud")
    game.call("_on_phase_two")
    await _save("phase-two-panel")
    game.call("_close_overlay")
    game.call("_refresh_hud")
    await _save("phase-two-gameplay")
    print("PASS: actual Godot Phase 2 mission panel and live consortium")
    quit()
func _save(label: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
    assert(root.get_texture().get_image().save_png("res://build/previews/"+label+".png")==OK)
