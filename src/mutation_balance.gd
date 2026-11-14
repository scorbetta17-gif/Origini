extends RefCounted
## Gameplay balance, not a claim that molecular point mutations are always small.
const BASE_DIVISION_POINTS: float = 4.0
const DIVISION_NEEDS := {"carbon":21.6,"amino":13.5,"lipid":10.8,"nucleic":7.2,"biomass":58.5}
const RESERVE_BASE := {"carbon":24.0,"amino":15.0,"lipid":12.0,"nucleic":8.0,"biomass":65.0}
const CAPS := {"motility":1.65,"attack":1.90,"defense":1.80,"vitality":1.70,"mutation":.50,"metabolism":1.65,"uptake":1.75}
const FLOORS := {"motility":.55,"attack":.50,"defense":.55,"vitality":.65,"mutation":0.0,"metabolism":.55,"uptake":.50}
const GAINS := {"motility":.75,"attack":1.05,"defense":.90,"vitality":.80,"mutation":.50,"metabolism":.75,"uptake":.85}
const POSITIVE_GAIN_BUDGET: float = 1.20
const LEGACY_CAPS := {"motility":1.60,"attack":1.90,"defense":1.85,"mutation":.35,"metabolism":1.80,"uptake":1.80}
const TRADEOFF := {"motility":"metabolism","attack":"uptake","defense":"motility","vitality":"metabolism","mutation":"defense","metabolism":"attack","uptake":"defense"}
const PENALTIES := {
    "motility":{"metabolism":.30,"defense":.12},
    "attack":{"uptake":.32,"metabolism":.16},
    "defense":{"motility":.32,"uptake":.10},
    "vitality":{"metabolism":.22,"motility":.15},
    "mutation":{"defense":.20,"vitality":.15,"uptake":.15},
    "metabolism":{"attack":.24,"vitality":.12},
    "uptake":{"defense":.28,"attack":.12}}
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
        # Existing legal save values survive tuning changes; purchases cannot
        # increase a grandfathered value above its inherited baseline.
        var upper: float = maxf(float(CAPS[stat]),float(LEGACY_CAPS.get(stat,CAPS[stat])))
        result[stat] = clampf(float(result.get(stat,0.0 if stat=="mutation" else 1.0)),
            -.20 if stat=="mutation" else float(FLOORS[stat]),upper)
    return result

static func shift(traits: Dictionary, stat: String, amount: float) -> Dictionary:
    var result: Dictionary = normalize(traits)
    if not CAPS.has(stat):
        return result
    var current: float = float(result[stat])
    var baseline: float = 0.0 if stat=="mutation" else 1.0
    var gain: float = amount
    if gain>0:
        gain *= clampf((float(CAPS[stat])-current)/(float(CAPS[stat])-baseline),0.0,1.0)
    result[stat] = current+gain
    result = normalize(result)
    if result.has("balance_baseline"):
        result.balance_baseline[stat] = float(result.balance_baseline.get(stat,baseline))+float(result[stat])-current
    return result

static func tree_effect(traits: Dictionary, stat: String, major: bool) -> Dictionary:
    var result: Dictionary = normalize(traits)
    if not CAPS.has(stat):
        return result
    if not result.has("balance_baseline"):
        var inherited: Dictionary = {}
        for key in CAPS:
            inherited[key] = result[key]
        result["balance_baseline"] = inherited
        result["balance_investments"] = {}
        result["balance_version"] = 1
    var investments: Dictionary = result.get("balance_investments",{}).duplicate(true)
    investments[stat] = maxf(0.0,float(investments.get(stat,0.0))) + (5.0 if major else 1.0)
    result["balance_investments"] = investments
    var inherited: Dictionary = result.balance_baseline
    for target in CAPS:
        var baseline: float = float(inherited.get(target,0.0 if target=="mutation" else 1.0))
        var value: float = baseline+float(GAINS[target])*(1.0-exp(-maxf(0.0,float(investments.get(target,0.0)))/20.0))
        for source in PENALTIES:
            value -= float(PENALTIES[source].get(target,0.0))*pow(maxf(0.0,float(investments.get(source,0.0)))/40.0,1.3)
        result[target] = clampf(value,minf(float(FLOORS[target]),baseline),maxf(float(CAPS[target]),baseline))
    # Finite expressed capacity: six ordinary axes share an improvement budget.
    # Legacy inherited values are exempt, preserving existing saves.
    var total_positive: float = 0.0
    for target in CAPS:
        if target != "mutation":
            total_positive += maxf(0.0,float(result[target])-float(inherited.get(target,1.0)))
    if total_positive > POSITIVE_GAIN_BUDGET:
        for target in CAPS:
            if target == "mutation":
                continue
            var baseline: float = float(inherited.get(target,1.0))
            var improvement: float = float(result[target])-baseline
            if improvement>0.0:
                result[target] = baseline+improvement*POSITIVE_GAIN_BUDGET/total_positive
    return result

static func points_multiplier(traits: Dictionary) -> float:
    # Legacy mutation remains an offset (zero is baseline), never baseline 1.
    return clampf(1.0+float(traits.get("mutation",0.0)),1.0,1.5)

static func division_credit(traits: Dictionary, remainder: float = 0.0) -> Dictionary:
    # Fractional carry avoids rounding a small upgrade to either zero or +1.
    var total: float = BASE_DIVISION_POINTS*points_multiplier(traits)+clampf(remainder,0.0,.999999)
    var whole: int = int(floor(total+0.0000001))
    return {"points":whole,"remainder":maxf(0.0,total-float(whole))}
