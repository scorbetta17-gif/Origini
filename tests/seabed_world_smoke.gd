extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var started: int = Time.get_ticks_msec()
    var game: Node = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    var terrain: Node = game.world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
    assert(game.world_radius == 1150.0)
    assert(terrain.sector_count == 25)
    assert(terrain.rock_count > 1200 and terrain.rock_count < 3200)
    assert(terrain.terrain_triangles < 150000)
    assert(terrain.faults.size() == 844)
    var low: float = 1000
    var high: float = -1000
    var unique_heights: Dictionary = {}
    for x in range(-1150,1151,40):
        for z in range(-1150,1151,40):
            var h: float = terrain.surface_height(Vector2(x,z))
            assert(is_finite(h) and h<=-.26)
            low = minf(low,h)
            high = maxf(high,h)
            unique_heights[snappedf(h,.2)] = true
    assert(high-low>2,"Large map needs actual relief, not a scaled plane")
    assert(unique_heights.size()>10)
    # Rendered ground faces must point upwards (back-face regression).
    for sector in terrain.get_children():
        var mesh: Mesh = sector.get_node("Sedimento_scolpito").mesh
        var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
        for normal in normals:
            assert(normal.y>0,"All top surfaces must be visible from the camera")
    # Fine/coarse interfaces share the same line, not mismatched heights.
    for axis in [0,1]:
        for edge in [-32,32]:
            for along in range(-31,32,2):
                var p := Vector2(edge,along) if axis==0 else Vector2(along,edge)
                var tangent := Vector2(0,1) if axis==0 else Vector2(1,0)
                var midpoint: float = (terrain.height_at(p-tangent)+terrain.height_at(p+tangent))*.5
                assert(is_equal_approx(terrain._vertex_height(p,1),midpoint))
    # Streaming is bounded and reproducible at arbitrary distant positions.
    assert(pow(game.world_radius*2,2)>=5000000)
    var origin_height: float = terrain.surface_height(Vector2(13,19))
    for at in [Vector3(1040,0,-1040),Vector3(-700,0,920),Vector3.ZERO]:
        terrain.update_focus(at,true)
        assert(terrain.sectors.size()<=25 and terrain.pending.is_empty())
        assert(terrain.terrain_triangles<25000)
        assert(terrain.sectors.has(Vector2i(floori(at.x/32),floori(at.z/32))*32))
    assert(is_equal_approx(origin_height,terrain.surface_height(Vector2(13,19))))
    # Movement really crosses the old +/-25 boundary and respects the new one.
    game.player.position = Vector3(30,0,30)
    game.call("_move_player",Vector2.ONE.normalized(),.5)
    assert(game.player.position.x>30 and game.player.position.z>30)
    game.player.position = Vector3(1149.99,0,1149.99)
    game.call("_move_player",Vector2.ONE.normalized(),1.0)
    assert(game.player.position.x<=1150 and game.player.position.z<=1150)
    # A far-away jump must still offer local abiotic resources, under the cap.
    game.player.position = Vector3(1040,0,-1040)
    game.call("_respawn_nutrients",.3)
    var near: int = 0
    for n in game.nutrients:
        var p: Vector3 = n["node"].position
        assert(absf(p.x)<=1150 and absf(p.z)<=1150)
        if p.distance_to(game.player.position)<30:
            near += 1
    assert(near>=40,"Exploration supplies local food while preserving the contested habitat food near its living competitors")
    assert(game.nutrients.size()<=94)
    # Recycling must never move nutrients that sustain another living cell.
    var traits: Dictionary = game.call("_base_traits")
    game.call("_create_entity","seabed-neighbor","",0,"pre_luca",traits,Vector3.ZERO,false)
    game.call("_create_nutrient","carbon",Vector3(2,.29,0))
    var protected: Node3D = game.nutrients[-1]["node"]
    game.call("_recycle_distant_nutrients")
    assert(protected.position.is_equal_approx(Vector3(2,.29,0)))
    # A far position survives the existing save/load format.
    game.call("_save_game")
    game.player.position = Vector3.ZERO
    game.call("_load_game")
    assert(game.player.position.distance_to(Vector3(1040,0,-1040))<.01)
    print("SEABED sectors=",terrain.sector_count," triangles=",terrain.terrain_triangles,
        " rocks=",terrain.rock_count," relief=",high-low," setup+checks_ms=",Time.get_ticks_msec()-started)
    print("PASS: large seabed, upward faces, joined sectors, relief, distant nutrients and saves")
    quit(0)
