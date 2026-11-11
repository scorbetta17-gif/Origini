extends Node3D
## Fondale minerale essenziale: nessuna vita macroscopica, nessuna geometria neon.
## I pesi di questo sistema sono separati dal gameplay e adattabili per Android.
const SEABED = preload("res://shaders/seafloor.gdshader")
var mineral_mats: Array[StandardMaterial3D] = []
var dust_root: MultiMeshInstance3D

func setup(rng: RandomNumberGenerator) -> void:
    for tint in [
        Color(.20,.245,.25), Color(.25,.278,.275), Color(.145,.20,.215),
        Color(.225,.25,.23), Color(.175,.205,.19)
    ]:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = tint
        mat.roughness = .96
        mat.metallic = 0.0
        mineral_mats.append(mat)
    _sediment()
    # Meno oggetti, silhouette naturali. Rimane spazio per osservare la cellula.
    for i in range(105):
        var x: float = rng.randf_range(-32.0,32.0)
        var z: float = rng.randf_range(-32.0,32.0)
        if Vector2(x,z).length() < 4.5:
            continue
        var r: float = rng.randf_range(.13,.72)
        if i % 17 == 0:
            r *= 2.15
        _stone(Vector3(x,-.22,z),r,rng)
    # Piccoli affioramenti lontani dal soggetto: profondita' visiva senza sovraffollare.
    for where in [
        Vector3(-3.9,-.22,-1.6),Vector3(4.1,-.22,2.1),
        Vector3(-2.9,-.22,3.7),Vector3(3.8,-.22,-3.1),
        Vector3(-4.7,-.22,3.5)
    ]:
        _stone(where,rng.randf_range(.31,.63),rng)
    for i in range(22):
        var x: float = rng.randf_range(-26.0,26.0)
        var z: float = rng.randf_range(-26.0,26.0)
        if Vector2(x,z).length() < 3.0:
            continue
        _stone(Vector3(x,-.22,z),rng.randf_range(.035,.11),rng)
    _vent(Vector3(-11.0,-.23,3.0),1.52,rng)
    _vent(Vector3(16.0,-.23,-14.0),1.08,rng)
    _dust(rng)

func _sediment() -> void:
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(120,120)
    plane.subdivide_width = 96
    plane.subdivide_depth = 96
    ground.mesh = plane
    var shader_mat := ShaderMaterial.new()
    shader_mat.shader = SEABED
    ground.material_override = shader_mat
    ground.position.y = -.265
    ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ground)

func _stone(at: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sides: int = 9
    var phase: float = rng.randf()*TAU
    var heights: Array[float] = [0.04,.36,.71,1.0]
    var profiles: Array[float] = [.85,1.00,.78,.32]
    var rings: Array = []
    for level in range(heights.size()):
        var ring: Array[Vector3] = []
        for j in range(sides):
            var angle: float = phase+TAU*float(j)/float(sides)
            var variation: float = rng.randf_range(.81,1.16)
            var r: float = radius*profiles[level]*variation
            var y: float = radius*heights[level]*rng.randf_range(.88,1.08)
            ring.append(Vector3(cos(angle)*r,y,sin(angle)*r))
        rings.append(ring)
    for level in range(heights.size()-1):
        for j in range(sides):
            var next: int = (j+1)%sides
            _triangle(mesh,rings[level][j],rings[level][next],rings[level+1][j])
            _triangle(mesh,rings[level][next],rings[level+1][next],rings[level+1][j])
    for j in range(sides):
        _triangle(mesh,rings[3][j],rings[3][(j+1)%sides],Vector3(0,radius*.95,0))
    mesh.generate_normals()
    var result := MeshInstance3D.new()
    result.mesh = mesh.commit()
    result.material_override = mineral_mats[rng.randi_range(0,mineral_mats.size()-1)]
    result.position = at
    result.rotation.y = rng.randf_range(-PI,PI)
    result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(result)

func _triangle(mesh: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    mesh.add_vertex(a)
    mesh.add_vertex(b)
    mesh.add_vertex(c)

func _vent(at: Vector3, height: float, rng: RandomNumberGenerator) -> void:
    # Piccolo condotto irregolare mineralizzato, non una torre luminosa.
    for i in range(8):
        var angle: float = TAU*float(i)/8.0
        _stone(at+Vector3(cos(angle)*.55,0,sin(angle)*.55),rng.randf_range(.25,.54),rng)
    var chimney := CylinderMesh.new()
    chimney.height = height
    chimney.top_radius = .18
    chimney.bottom_radius = .36
    chimney.radial_segments = 11
    var shaft := MeshInstance3D.new()
    shaft.mesh = chimney
    shaft.position = at+Vector3(0,height*.5,0)
    shaft.material_override = mineral_mats[2]
    shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shaft)
    # Croste minerali sovrapposte attorno al condotto.
    for i in range(5):
        var crust := CylinderMesh.new()
        crust.height = rng.randf_range(.12,.24)
        crust.top_radius = .21+rng.randf_range(-.055,.095)
        crust.bottom_radius = crust.top_radius+rng.randf_range(.02,.07)
        crust.radial_segments = 8
        var ledge := MeshInstance3D.new()
        ledge.mesh = crust
        ledge.position = at+Vector3(rng.randf_range(-.045,.045),height*(.12+float(i)*.185),rng.randf_range(-.045,.045))
        ledge.rotation.y = rng.randf_range(0,TAU)
        ledge.material_override = mineral_mats[(i+1)%mineral_mats.size()]
        ledge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(ledge)
    # Fumarola diffusa: colonne di acqua torbida neutra anziche' lava.
    for i in range(20):
        var speck := MeshInstance3D.new()
        var m := SphereMesh.new()
        m.radius = .016
        m.height = .032
        m.radial_segments = 6
        m.rings = 4
        speck.mesh = m
        speck.position = at+Vector3(rng.randf_range(-.35,.35),height+rng.randf_range(.06,2.2),rng.randf_range(-.35,.35))
        speck.material_override = mineral_mats[3]
        speck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(speck)

func _dust(rng: RandomNumberGenerator) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = .010
    mesh.height = .020
    mesh.radial_segments = 5
    mesh.rings = 3
    var count: int = 240
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.instance_count = count
    mm.mesh = mesh
    for i in range(count):
        var x: float = rng.randf_range(-30,30)
        var y: float = rng.randf_range(.1,3.8)
        var z: float = rng.randf_range(-30,30)
        var xf := Transform3D(Basis.IDENTITY,Vector3(x,y,z))
        xf.basis = xf.basis.scaled(Vector3.ONE*rng.randf_range(.6,1.7))
        mm.set_instance_transform(i,xf)
    dust_root = MultiMeshInstance3D.new()
    dust_root.multimesh = mm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(.34,.42,.41)
    m.roughness = 1.0
    dust_root.material_override = m
    dust_root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(dust_root)
