extends SceneTree
const OCEAN = preload("res://src/primordial_ocean.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var ocean: Node3D = OCEAN.new()
    root.add_child(ocean)
    var rng := RandomNumberGenerator.new()
    rng.seed = 987
    var previous_state: int = rng.state
    ocean.setup(rng)
    assert(rng.state == previous_state,"Environment must not consume genetics/nutrient RNG")
    var count: int = 0
    for vent in ocean.get_children():
        if not vent.is_in_group("primordial_volcano"):
            continue
        count += 1
        assert(vent.get_node("Basalto_stratificato") is MeshInstance3D)
        var rock: Mesh = vent.get_node("Basalto_stratificato").mesh
        var vertices: PackedVector3Array = rock.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        assert(vertices.size()/3 < 2500,"Keep the basalt within the mobile triangle budget")
        var top := Vector3(0,vent.vent_height+10,0)
        var bottom := Vector3(0,vent.basin_height-.01,0)
        # Geometric regression: an opaque cap would hide the basin again.
        for i in range(0,vertices.size(),3):
            assert(vertices[i].is_finite())
            var hit: Variant = Geometry3D.segment_intersects_triangle(
                top,bottom,vertices[i],vertices[i+1],vertices[i+2])
            assert(hit == null,"Crater opening must not be sealed by rock")
        assert(vent.basin_height < vent.rim_min_height - .2)
        var basin: Mesh = vent.get_node("Bacino_incassato").mesh
        var floor_vertices: PackedVector3Array = basin.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        for vertex in floor_vertices:
            assert(is_equal_approx(vertex.y,vent.basin_height))
        var plume: MultiMeshInstance3D = vent.get_node("Pennacchio_idrotermale")
        assert(plume.multimesh.instance_count == 18)
        var before: Vector3 = vent.plume_positions[0]
        vent.call("_process",.5)
        assert(vent.plume_positions[0].y > before.y)
        var bounds: AABB = rock.get_aabb()
        assert(bounds.size.x > vent.vent_radius * 1.8)
        assert(bounds.size.y >= vent.vent_height * .9)
        print("VOLCANO triangles=",vertices.size()/3," size=",bounds.size)
    assert(count == 2)
    ocean.queue_free()
    print("PASS: two hollow 3D volcanoes, recessed lava, rising plumes, isolated visual RNG")
    quit(0)
