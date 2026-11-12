extends RefCounted
## Gameplay balance, not a claim that molecular point mutations are always small.
const CAPS := {"motility":1.60,"attack":1.90,"defense":1.85,"mutation":.35,"metabolism":1.80,"uptake":1.80}
const TRADEOFF := {"motility":"metabolism","attack":"uptake","defense":"motility","mutation":"defense","metabolism":"attack","uptake":"defense"}
const MINOR_GAIN: float = .025
const MAJOR_GAIN: float = .08
const POINTS_PER_MAJOR: int = 5
const ENZYME_COST: float = 6.0
const LYSIS_COST: float = 10.0
const KILL_REWARD := {"carbon":10.0,"amino":7.0,"lipid":4.0,"nucleic":3.0,"biomass":12.0,"atp":18.0}
const SUBSTRATE_REWARD := {"carbon":6.0,"amino":3.0,"lipid":2.0,"nucleic":1.0,"biomass":4.0,"atp":8.0}
const NUTRIENT_CYCLE := ["carbon","carbon","amino","lipid","carbon","nucleic","carbon","amino","lipid","carbon","nucleic","carbon","amino","lipid"]

static func normalize(traits: Dictionary) -> Dictionary:
    var result: Dictionary = traits.duplicate(true)
    for stat in CAPS:
        result[stat] = clampf(float(result.get(stat,0.0 if stat=="mutation" else 1.0)),
            -.20 if stat=="mutation" else .65,float(CAPS[stat]))
    return result

static func shift(traits: Dictionary, stat: String, amount: float) -> Dictionary:
    var result: Dictionary = normalize(traits)
    var current: float = float(result[stat])
    var baseline: float = 0.0 if stat=="mutation" else 1.0
    var gain: float = amount
    if gain>0:
        gain *= clampf((float(CAPS[stat])-current)/(float(CAPS[stat])-baseline),0.0,1.0)
    result[stat] = current+gain
    return normalize(result)

static func tree_effect(traits: Dictionary, stat: String, major: bool) -> Dictionary:
    var result: Dictionary = shift(traits,stat,MAJOR_GAIN if major else MINOR_GAIN)
    return shift(result,str(TRADEOFF[stat]),-.012 if major else -.004)
