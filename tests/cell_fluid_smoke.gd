extends SceneTree
const C = preload("res://src/cell_visual.gd")
const G = preload("res://src/cell_genome.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cell: Node3D = C.new()
    root.add_child(cell)
    cell.setup(G.normalize({"genome":G.origin()}),"pre_luca")
    cell.set_process(false)
    var motion: Node = cell.get_node("FluidMotion")
    motion.set_process(false)
    var peak: float = 0.0
    for i in range(1200):
        var velocity := Vector3(cos(i*.08),0,sin(i*.08))*3.0
        if i>600:
            velocity = Vector3.ZERO
        motion.advance_motion(velocity,1.0/60.0)
        var shape: Basis = motion.body.basis
        assert(shape.is_finite())
        assert(absf(shape.determinant()-1.0)<.0001,"Visual deformation preserves volume")
        assert(shape.x.length()>.79 and shape.x.length()<1.14)
        assert(shape.y.length()>.9 and shape.y.length()<1.14)
        peak = maxf(peak,motion.strain)
    assert(peak>.08,"Swimming must produce a visible, bounded response")
    assert(motion.strain<.0001,"Membrane relaxes after stopping")
    for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
        motion.filtered_velocity=Vector3.ZERO
        for frame in range(120): motion.advance_motion(axis*3,1.0/60)
        assert((motion.body.basis*axis).length()<.85,"Water compresses the direction of travel")
        assert(motion.shell_material.get_shader_parameter("flow_axis").dot(axis)>.99)
    var before: Transform3D = motion.body.transform
    motion.advance_motion(Vector3.INF,.01)
    assert(motion.body.transform == before)
    motion.advance_motion(Vector3.ONE,-1)
    assert(motion.body.transform == before)
    motion.advance_motion(Vector3.ONE*1e20,100)
    assert(motion.body.transform.is_finite() and motion.strain<=.19)
    var traits: Dictionary = G.grant({"genome":G.origin()},"monoderm_envelope",1,"test","bacteria")
    cell.setup(traits,"bacteria")
    motion = cell.get_node("FluidMotion")
    motion.set_process(false)
    for i in range(120):
        motion.advance_motion(Vector3(3,0,0),1.0/60.0)
    assert(motion.strain<peak*.3,"Walled cells must be appreciably more rigid")
    assert(cell.find_child("ContactShadow",true,false).get_parent()==cell)
    assert(cell.selection_ring.get_parent()==cell)
    cell.queue_free()
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    var positions: Array[Vector3] = []
    for fps in [30,60,120]:
        game.player.position = Vector3.ZERO
        game.entities[game.player_id]["velocity"] = Vector3.ZERO
        game.atp = 100
        for frame in range(fps*2):
            game.call("_move_player",Vector2.RIGHT,1.0/fps)
        for frame in range(fps):
            game.call("_move_player",Vector2.ZERO,1.0/fps)
        positions.append(game.player.position)
    assert(positions[0].distance_to(positions[1])<.0001)
    assert(positions[1].distance_to(positions[2])<.0001)
    print("PASS: bounded membrane, preserved affine volume, relaxation, wall rigidity, frame-independent movement")
    quit(0)
