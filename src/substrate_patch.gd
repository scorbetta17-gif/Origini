extends MeshInstance3D
## Molecular resource packets; not modern organelles or generic organic boulders.
const KINDS = ["rna","peptide","lipid"]
const LABELS = {"rna":"FRAMMENTI RNA", "peptide":"OLIGOPEPTIDI", "lipid":"AGGREGATO LIPIDICO"}
const REWARDS = {
    "rna":{"nucleic":10.75,"biomass":4.0,"atp":8.0},
    "peptide":{"amino":10.75,"carbon":2.0,"biomass":4.0,"atp":8.0},
    "lipid":{"lipid":10.75,"biomass":4.0,"atp":8.0}}
var kind: String = "rna"
var portions: int = 3
var caption: Label3D
var fragments: Array[Node3D] = []
var pulse: float = 0.0

func setup(seed_value: int, remaining: int = 3, resource_kind: String = "") -> void:
    kind = resource_kind if resource_kind in KINDS else KINDS[posmod(seed_value,3)]
    portions = clampi(remaining,1,3)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var tint: Color = Color(1,.48,.17) if kind=="rna" else (Color(.46,.85,1) if kind=="peptide" else Color(.96,.79,.28))
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.emission_enabled = true
    mat.emission = tint*.22
    for packet in range(3):
        var group := Node3D.new()
        group.position = Vector3((packet-1)*.42,.35, sin(packet*2.0)*.26)
        add_child(group)
        fragments.append(group)
        var previous := Vector3.ZERO
        for i in range(9):
            var angle: float = i*TAU/8.0
            var pos := Vector3(cos(angle)*.19,sin(angle*1.7)*.07,sin(angle)*.19) if kind=="lipid" else Vector3((i-4)*.047,sin(i*.8)*.09,cos(i*.7)*.07)
            var bead := MeshInstance3D.new()
            var sphere := SphereMesh.new()
            sphere.radius = .035 if kind=="rna" else .055
            sphere.height = sphere.radius*2
            sphere.radial_segments=8
            sphere.rings=4
            bead.mesh=sphere
            bead.position=pos
            bead.material_override=mat
            group.add_child(bead)
            if i>0 and kind!="lipid":
                var bond := MeshInstance3D.new()
                var cylinder := CylinderMesh.new()
                cylinder.top_radius=.012
                cylinder.bottom_radius=.012
                cylinder.height=pos.distance_to(previous)
                cylinder.radial_segments=6
                bond.mesh=cylinder
                bond.position=(pos+previous)*.5
                bond.quaternion=Quaternion(Vector3.UP,(pos-previous).normalized())
                bond.material_override=mat
                group.add_child(bond)
            previous=pos
    caption=Label3D.new()
    caption.position.y=.85
    caption.font_size=24
    caption.pixel_size=.006
    caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    add_child(caption)
    set_portions(portions)

func reward() -> Dictionary:
    return REWARDS[kind].duplicate()

func set_portions(value: int) -> void:
    portions=maxi(0,value)
    pulse=1.0
    for i in range(fragments.size()): fragments[i].visible=i<portions
    if is_instance_valid(caption): caption.text="%s · %d" % [LABELS[kind],portions]

func _process(delta: float) -> void:
    pulse=maxf(0,pulse-delta*2)
    for i in range(fragments.size()):
        fragments[i].rotation.y+=delta*(.12+i*.035)
        fragments[i].scale=Vector3.ONE*(1.0+pulse*.12)
