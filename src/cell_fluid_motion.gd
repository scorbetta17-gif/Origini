extends Node3D
## Bounded visual response inspired by overdamped vesicles, not a CFD solver.
## Shared affine deformation keeps every membrane-bound module attached.
const RESPONSE: float = 9.0
var cell: Node3D
var body: Node3D
var filtered_velocity := Vector3.ZERO
var previous_position := Vector3.ZERO
var strain: float = 0.0
var phase: float = 0.0
var surface_phase: float = 0.0
var flexibility: float = 1.0
var shell_material: ShaderMaterial
var last_volume_ratio: float = 1.0
var anchors: Array[Dictionary] = []

func setup(host: Node3D) -> void:
    cell = host
    previous_position = cell.global_position
    flexibility = .22 if str(cell.traits.get("envelope","none")) != "none" else 1.0
    body = Node3D.new()
    body.name = "BodyDeformation"
    cell.add_child(body)
    for child in cell.get_children():
        if child == self or child == body or child == cell.selection_ring:
            continue
        if child is MeshInstance3D:
            var material: Material = child.material_override
            if material is ShaderMaterial and material.shader.resource_path.ends_with("cell_contact_shadow.gdshader"):
                continue
        if child is Node3D:
            if child.name.begins_with("GeneModule_") or child.name.ends_with("RotaryFilament"):
                anchors.append({"node":child,"rest":child.position})
            child.reparent(body,false)
    if is_instance_valid(cell.membrane):
        shell_material = cell.membrane.material_override as ShaderMaterial
        if shell_material != null:
            shell_material.set_shader_parameter("membrane_motion",.025*flexibility)
    advance_motion(Vector3.ZERO,0.0)

func _process(delta: float) -> void:
    if not is_instance_valid(cell) or not is_instance_valid(body):
        return
    var movement: Vector3 = cell.global_position-previous_position
    previous_position = cell.global_position
    # Lineage switching, loading and spawn are relocations, not hydrodynamic shocks.
    var velocity := Vector3.ZERO
    if delta>0.000001 and movement.length()<4.0:
        velocity = movement/delta
    advance_motion(velocity,delta)

func advance_motion(velocity: Vector3, delta: float) -> void:
    if not velocity.is_finite() or not is_finite(delta) or delta<0:
        return
    var dt: float = minf(delta,.25)
    phase = fmod(phase+dt,10000.0)
    var blend: float = 1.0-exp(-RESPONSE*dt)
    filtered_velocity = filtered_velocity.lerp(velocity.limit_length(8.0),blend)
    var target: float = minf(filtered_velocity.length()/3.0,1.0)*.12*flexibility
    strain = lerpf(strain,target,blend)
    var local: Vector3 = cell.global_basis.orthonormalized().inverse()*filtered_velocity
    var axis: Vector3 = local.normalized() if local.length_squared()>.00001 else Vector3.RIGHT
    var rotation := Basis(Quaternion(Vector3.RIGHT,axis))
    var stretch: float = 1.0+strain+sin(phase*1.35)*.005*flexibility
    var transverse: float = 1.0/sqrt(stretch)
    var deformation: Basis = rotation*Basis.from_scale(Vector3(stretch,transverse,transverse))*rotation.transposed()
    last_volume_ratio = deformation.determinant()
    var center := Vector3(0,.81,0)
    body.transform = Transform3D(deformation,center-deformation*center)
    # Follow the same small radial undulation as the shell, in addition to the
    # common affine strain, so a receptor or motor cannot float off its anchor.
    for anchor in anchors:
        var rest: Vector3 = anchor["rest"]
        var unit: Vector3 = (rest-center)/cell.body_radii
        var azimuth: float = atan2(unit.z,unit.x)
        var wave: float = sin(unit.x*3.1+phase*.72)*sin(unit.z*2.4-phase*.53)
        var lobes: float = sin(azimuth*3.0+phase*.31)*.035+cos(azimuth*2.0-phase*.23)*.025
        var organic: float = sin(azimuth*3.0+.65)*.11+cos(azimuth*5.0-.7)*.045
        var displacement: float = (wave*.025+(lobes+organic)*clampf(Vector2(unit.x,unit.z).length(),0,1))*flexibility
        anchor["node"].position = rest+unit.normalized()*cell.body_radii*displacement
    surface_phase = fmod(surface_phase+dt*(.10+minf(filtered_velocity.length(),3.0)*.19)*3.0,TAU)
    if shell_material != null:
        shell_material.set_shader_parameter("membrane_time",phase)
        shell_material.set_shader_parameter("surface_phase",surface_phase)
        shell_material.set_shader_parameter("flexibility",flexibility)
