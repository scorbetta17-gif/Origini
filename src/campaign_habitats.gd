extends Node
## Local teaching habitats within the existing 5.29 km² world, not new maps.
const CENTERS := [Vector3(0,0,5),Vector3(16,0,-14),Vector3(-15,0,-9)]
const TITLES := ["PIANA SICURA", "FAGLIA CALDA", "TAPPETO CONTESO"]
const COLORS := [Color(.22,.35,.37),Color(.33,.29,.24),Color(.21,.36,.28)]
var game: Node
var visual: Node3D

func rebuild(enabled: bool) -> void:
    if is_instance_valid(visual): visual.queue_free()
    if not enabled: return
    visual = Node3D.new()
    visual.name = "Habitat_vicini"
    game.world_root.add_child(visual)
    var terrain: Node = game.world_root.get_node("Fondale_minimale/Fondo_sabbioso_roccioso")
    for i in range(3):
        var center: Vector3 = CENTERS[i]
        # Discontinuous mineral plates follow the actual seabed height.
        for j in range(18 if i>0 else 7):
            var angle: float = j*2.39996
            var r: float = sqrt(float(j)+1)*.8
            var at: Vector3 = center+Vector3(cos(angle)*r,0,sin(angle)*r)
            var mesh := MeshInstance3D.new()
            var rock := CylinderMesh.new()
            rock.top_radius = .5+float(j%3)*.13
            rock.bottom_radius = rock.top_radius*1.12
            rock.height = .08 if i==0 else .18
            rock.radial_segments = 5+j%3
            mesh.mesh = rock
            mesh.material_override = game._solid(COLORS[i].lightened(float(j%4)*.025))
            mesh.position = Vector3(at.x,terrain.surface_height(Vector2(at.x,at.z)),at.z)
            visual.add_child(mesh)
        var label := Label3D.new()
        label.text = TITLES[i]+["\nRisorse disperse · basso rischio","\nPiù vicino = più caldo · risorse concentrate","\nRaccolta rapida · concorrenti"][i]
        label.font_size = 34
        label.pixel_size = .008
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.position = center+Vector3(0,1.2,-3.5)
        visual.add_child(label)
    for radius in [2.5,4.5]:
        var lines := ImmediateMesh.new()
        lines.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
        for j in range(97):
            var at: Vector3 = CENTERS[1]+Vector3(cos(TAU*j/96.0),0,sin(TAU*j/96.0))*radius
            at.y = terrain.surface_height(Vector2(at.x,at.z))+.08
            lines.surface_add_vertex(at)
        lines.surface_end()
        var contour := MeshInstance3D.new()
        contour.mesh = lines
        contour.material_override = game._solid(Color(.65,.32,.20) if radius<3 else Color(.45,.48,.28))
        visual.add_child(contour)
    # Existing source (16,-14) already supplies animated plume and temperature.

func description(at: Vector3) -> String:
    var i: int = nearest(at)
    if at.distance_to(CENTERS[i])>9: return "ESPLORA · Piana S / Faglia NE / Tappeto NO"
    return TITLES[i]+[" · cibo disperso, basso rischio"," · gradiente termico, cerca il tuo limite"," · risorse dense, concorrenti"][i]

func nearest(at: Vector3) -> int:
    var found: int = 0
    for i in range(1,3):
        if at.distance_squared_to(CENTERS[i])<at.distance_squared_to(CENTERS[found]): found = i
    return found

func food_position(index: int = -1) -> Vector3:
    var i: int = index if index>=0 else game.rng.randi_range(0,2)
    var radius: float = [7.0,2.7,3.2][i]
    var angle: float = game.rng.randf()*TAU
    var r: float = sqrt(game.rng.randf())*radius
    # Hot inner resources require thermal adaptation; outer ring remains reachable.
    if i==1: r = game.rng.randf_range(2.2,4.8)
    return CENTERS[i]+Vector3(cos(angle)*r,.29,sin(angle)*r)

func seed_world() -> void:
    var cursor: int = game.nutrients.size()-48
    for i in range(3):
        for j in range([10,16,22][i]):
            var n: Dictionary = game.nutrients[cursor]
            n.node.position = food_position(i)
            n.origin_y = n.node.position.y
            cursor += 1
    for i in range(3):
        var tr: Dictionary = game._base_traits()
        tr["uptake"] = 1.1
        game._create_entity("MAT-%02d"%i,"",0,"pre_luca",tr,CENTERS[2]+Vector3(i-1,0,1),false,true)
