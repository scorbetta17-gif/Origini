extends Node3D
## Deterministic 512x512 seabed; independent sectors allow engine frustum culling.
const Palette = preload("res://src/seabed_palette.gd")
const TILE: int = 32
const HALF: int = 256
var noise := FastNoiseLite.new()
var faults: Array[PackedVector2Array] = []
var fault_buckets: Dictionary = {}
var sector_count: int = 0
var rock_count: int = 0
var terrain_triangles: int = 0

func setup() -> void:
    noise.seed = 76112
    noise.frequency = .027
    noise.fractal_octaves = 3
    _make_faults()
    var material := ShaderMaterial.new()
    material.shader = preload("res://shaders/seafloor.gdshader")
    material.set_shader_parameter("basalt",Palette.BASALT)
    material.set_shader_parameter("sediment",Palette.SEDIMENT)
    var stone_mat := StandardMaterial3D.new()
    stone_mat.albedo_color = Palette.BASALT
    stone_mat.roughness = .98
    var stone_mesh: ArrayMesh = _stone_mesh()
    for z in range(-HALF,HALF,TILE):
        for x in range(-HALF,HALF,TILE):
            _sector(Vector2i(x,z),material,stone_mesh,stone_mat)

func _make_faults() -> void:
    # Four original harmless gas sites; new scars extend beyond the old arena.
    for path in [
        PackedVector2Array([Vector2(-9,-6),Vector2(-4.9,-3.7),Vector2(-3.6,-3),Vector2(-2.8,-3.3),Vector2(-1.65,-2.4),Vector2(2,-1)]),
        PackedVector2Array([Vector2(9,3),Vector2(4.6,5),Vector2(3.7,5.8),Vector2(2.6,5.4),Vector2(1.8,6.2),Vector2(-2,8)]),
        PackedVector2Array([Vector2(-15,8),Vector2(-7.4,10.2),Vector2(-6.6,10.7),Vector2(-5.9,9.9),Vector2(-5.1,10.4),Vector2(-1,13)]),
        PackedVector2Array([Vector2(7,-9),Vector2(9,-3.4),Vector2(9.8,-2.7),Vector2(10.4,-3.2),Vector2(11.4,-2),Vector2(17,0)])
    ]:
        faults.append(path)
    var rng := RandomNumberGenerator.new()
    rng.seed = 76113
    for i in range(34):
        var start := Vector2(rng.randf_range(-220,220),rng.randf_range(-220,220))
        if start.length()<36:
            start += Vector2(48,36)
        var direction := Vector2.from_angle(rng.randf()*TAU)
        var path := PackedVector2Array([start])
        for j in range(9):
            start += direction.rotated(rng.randf_range(-.6,.6))*rng.randf_range(3,8)
            start = start.clamp(Vector2.ONE*-250,Vector2.ONE*250)
            path.append(start)
        faults.append(path)
        faults.append(PackedVector2Array([path[4],path[4]+direction.rotated(1.1)*8,path[4]+direction.rotated(.9)*16]))
    for path in faults:
        for i in range(path.size()-1):
            var a: Vector2 = path[i]
            var b: Vector2 = path[i+1]
            var low := Vector2i(((a.min(b)-Vector2.ONE*5)/TILE).floor())
            var high := Vector2i(((a.max(b)+Vector2.ONE*5)/TILE).floor())
            for z in range(low.y,high.y+1):
                for x in range(low.x,high.x+1):
                    var key := Vector2i(x,z)
                    if not fault_buckets.has(key):
                        fault_buckets[key] = []
                    fault_buckets[key].append([a,b])

func fault_distance(p: Vector2) -> float:
    var distance: float = 1000.0
    for segment in fault_buckets.get(Vector2i((p/TILE).floor()),[]):
        var a: Vector2 = segment[0]
        var edge: Vector2 = segment[1]-a
        var t: float = clampf((p-a).dot(edge)/maxf(.0001,edge.length_squared()),0,1)
        distance = minf(distance,p.distance_to(a+edge*t))
    return distance

func height_at(p: Vector2) -> float:
    var broad: float = noise.get_noise_2d(p.x,p.y)
    var detail: float = noise.get_noise_2d(p.x*4+91,p.y*4-63)
    var basin: float = smoothstep(-.15,.45,noise.get_noise_2d(p.x*.42-150,p.y*.42+230))
    var terraces: float = floorf((broad+.65)*7.0)/7.0
    var height: float = -.40-(broad+.55)*.75-terraces*.65-basin*1.35+detail*.17
    # Flat collars anchor volcano skirts in the same geological surface.
    for vent in [Vector2(-11,3),Vector2(16,-14)]:
        height = lerpf(-.265,height,smoothstep(3.8,6.5,p.distance_to(vent)))
    var width: float = 1.35 if p.length()<24 else 3.2
    var incision: float = 1.0-smoothstep(.12,width,fault_distance(p))
    return minf(-.265,height-incision*(.72 if p.length()<24 else 1.65))

func _vertex_height(p: Vector2, step: int) -> float:
    if step == 1:
        if (p.x == -32 or p.x == 32) and posmod(int(p.y),2) == 1:
            return (height_at(p+Vector2(0,-1))+height_at(p+Vector2(0,1)))*.5
        if (p.y == -32 or p.y == 32) and posmod(int(p.x),2) == 1:
            return (height_at(p+Vector2(-1,0))+height_at(p+Vector2(1,0)))*.5
    return height_at(p)

func surface_height(p: Vector2) -> float:
    # Exact barycentric height on the rendered triangles, including LOD seams.
    var origin := Vector2i((p/TILE).floor())*TILE
    var step: int = 1 if absi(origin.x+16)<48 and absi(origin.y+16)<48 else 2
    var cell: Vector2 = (p/step).floor()*step
    var f: Vector2 = (p-cell)/step
    var a: float = _vertex_height(cell,step)
    var b: float = _vertex_height(cell+Vector2(step,0),step)
    var c: float = _vertex_height(cell+Vector2(step,step),step)
    var d: float = _vertex_height(cell+Vector2(0,step),step)
    if f.x+f.y<=1:
        return a+(b-a)*f.x+(d-a)*f.y
    return c+(d-c)*(1-f.x)+(b-c)*(1-f.y)

func _sector(origin: Vector2i, material: Material, stone_mesh: Mesh, stone_mat: Material) -> void:
    var node := Node3D.new()
    node.name = "Settore_%d_%d" % [origin.x,origin.y]
    node.position = Vector3(origin.x,0,origin.y)
    add_child(node)
    var step: int = 1 if absi(origin.x+16)<48 and absi(origin.y+16)<48 else 2
    var size: int = TILE/step+1
    var vertices := PackedVector3Array()
    for z in range(size):
        for x in range(size):
            var p := Vector2(origin.x+x*step,origin.y+z*step)
            vertices.append(Vector3(x*step,_vertex_height(p,step),z*step))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    for z in range(size-1):
        for x in range(size-1):
            var a: Vector3 = vertices[z*size+x]
            var b: Vector3 = vertices[z*size+x+1]
            var c: Vector3 = vertices[(z+1)*size+x+1]
            var d: Vector3 = vertices[(z+1)*size+x]
            _tri(st,a,d,b)
            _tri(st,b,d,c)
            terrain_triangles += 2
    st.generate_normals()
    var ground := MeshInstance3D.new()
    ground.name = "Sedimento_scolpito"
    ground.mesh = st.commit()
    ground.material_override = material
    ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.add_child(ground)
    var rng := RandomNumberGenerator.new()
    rng.seed = 76114+(origin.x+HALF)*1031+(origin.y+HALF)*3571
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = stone_mesh
    mm.instance_count = 34
    for i in range(mm.instance_count):
        var p := Vector2(rng.randf_range(1,31),rng.randf_range(1,31))
        var world: Vector2 = p+Vector2(origin)
        var radius: float = rng.randf_range(.12,.65)
        var ridge: float = noise.get_noise_2d(world.x+400,world.y-200)
        if i%6 == 0:
            radius *= 5.4 if ridge>0 else 2.0
        if i%11 == 0 and world.length()>6:
            radius = rng.randf_range(1.4,3.1) if ridge>-.12 else .6
        if world.length()<4 or world.distance_to(Vector2(-11,3))<4 or world.distance_to(Vector2(16,-14))<3:
            radius = .025
        var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(radius,radius*rng.randf_range(.4,.9),radius*.8))
        mm.set_instance_transform(i,Transform3D(basis,Vector3(p.x,surface_height(world)-radius*.14,p.y)))
    var stones := MultiMeshInstance3D.new()
    stones.name = "Blocchi_e_detrito"
    stones.multimesh = mm
    stones.material_override = stone_mat
    stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.add_child(stones)
    sector_count += 1
    rock_count += mm.instance_count

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(b)

func _stone_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    for i in range(7):
        var a: float = TAU*i/7
        var b: float = TAU*(i+1)/7
        var low_a := Vector3(cos(a),0,sin(a))
        var low_b := Vector3(cos(b),0,sin(b))
        var top_a := Vector3(cos(a)*.65,.8+.12*sin(a*3),sin(a)*.65)
        var top_b := Vector3(cos(b)*.65,.8+.12*sin(b*3),sin(b)*.65)
        _tri(st,low_a,top_a,low_b)
        _tri(st,low_b,top_a,top_b)
        _tri(st,top_a,Vector3(.1,1,-.1),top_b)
    st.generate_normals()
    return st.commit()
