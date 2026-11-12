extends Control
class_name PhenotypePortrait
## The daughter card renders the same genotype and geometry as the ocean.
const Cell = preload("res://src/cell_visual.gd")
var phenotype: Dictionary = {}
var lineage: String = "pre_luca"
var highlighted: bool = false
var viewport: SubViewport
var visual: Node3D
func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    var container := SubViewportContainer.new()
    container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    container.stretch=true
    container.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(container)
    viewport=SubViewport.new()
    viewport.size=Vector2i(320,240)
    viewport.own_world_3d=true
    viewport.transparent_bg=true
    viewport.msaa_3d=Viewport.MSAA_2X
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    container.add_child(viewport)
    var camera := Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.8
    viewport.add_child(camera)
    camera.position=Vector3(0,4.5,3)
    camera.look_at(Vector3(0,.7,0))
    var light := DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-60,-25,0)
    viewport.add_child(light)
    _rebuild()
func set_cell(traits: Dictionary, branch: String) -> void:
    phenotype=traits.duplicate(true)
    lineage=branch
    if is_instance_valid(viewport): _rebuild()
func _rebuild() -> void:
    if is_instance_valid(visual):
        viewport.remove_child(visual)
        visual.queue_free()
    visual=Cell.new()
    viewport.add_child(visual)
    visual.setup(phenotype,lineage,false)
    visual.set_growth(.8)
    if visual.has_node("ContactShadow"):
        visual.get_node("ContactShadow").hide()
