extends SceneTree
const Cell = preload("res://src/cell_visual.gd")
const Genome = preload("res://src/cell_genome.gd")
var failures: int = 0

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var cell := Cell.new()
    root.add_child(cell)
    var traits: Dictionary = Genome.grant({},"dna_stabilization",1,"test","bacteria")
    traits = Genome.grant(traits,"flagellar_motor",2,"test","bacteria")
    cell.setup(traits,"bacteria",true)
    cell.set_process(false)
    check(cell.membrane.mesh is SphereMesh,"Smooth ellipsoid replaces irregular imported shell")
    check(cell.body_radii.x>cell.body_radii.z and cell.body_radii.x/cell.body_radii.z<2,"Bounded ovoid silhouette")
    var dna: Node3D = cell.find_child("DNA_DoubleStrand",true,false)
    check(dna!=null,"DNA module exists")
    if dna!=null:
        var strand: MeshInstance3D = dna.get_child(0)
        var bounds: AABB = strand.mesh.get_aabb()
        check(bounds.size.x<.6 and bounds.size.y>.4 and bounds.size.z>.4,"DNA is compact and three dimensional")
        var pigment: Color = strand.material_override.get_shader_parameter("pigment")
        check(pigment.b>pigment.r and pigment.r>pigment.g,"DNA pigment is purple, not RNA orange")
    check(not cell.filament_roots.is_empty(),"Bacterial motor renders")
    if not cell.filament_roots.is_empty():
        var rotor: Node3D = cell.filament_roots[0]
        var base: Node3D = rotor.get_parent()
        var insertion: Transform3D = base.transform
        var start: Transform3D = rotor.transform
        cell.call("_process",.2)
        check(base.transform==insertion,"Rotation does not move membrane insertion")
        check(rotor.transform!=start,"Filament rotates about its long axis")
        check(base.has_node("FlexibleHook") and base.has_node("BasalMotor"),"Bacterial hook and basal anchor are separate")
    cell.queue_free()
    await process_frame
    print("CELL REDESIGN ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
