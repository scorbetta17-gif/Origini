extends RefCounted
class_name CellPhysiology
## Balance values derived from the installed ORIGINI 0.74 build.
## Motion speed was 3.40*motility*(1|.87|.78) for player,
## and 1.00*motility for NPC. Both get a 10% cut.
const SPEED_FACTOR: float = .90
const PLAYER_BASE_SPEED: float = 3.40 * SPEED_FACTOR
const NPC_BASE_SPEED: float = 1.00 * SPEED_FACTOR
const MAX_GROWTH_FACTOR: float = 1.20
const MAX_RESOURCE_FACTOR: float = 1.12
const ZERO_ATP_DEATH_SECONDS: float = 15.0
const BASE_ATP_UPKEEP: float = .28
const MOVEMENT_ATP_PER_WORLD_UNIT: float = .55
const NPC_ATP_MOVEMENT_COST: float = .37
const NPC_ATP_UPKEEP: float = .11
const NPC_ACCELERATION: float = 4.3

static func reserve_cap(need: float) -> float:
    return need * MAX_RESOURCE_FACTOR

static func growth_scale(biomass: float, birth_biomass: float, fission_biomass: float, initial_scale: float = .72) -> float:
    var progress: float = clampf((biomass-birth_biomass)/maxf(1.0,fission_biomass-birth_biomass),0.0,1.0)
    return initial_scale * (1.0 + (MAX_GROWTH_FACTOR-1.0)*progress)

static func player_speed(traits: Dictionary) -> float:
    var motility: float = clampf(float(traits.get("motility",1.0)),.35,4.0)
    var motorized: bool = int(traits.get("archaella",0)) > 0 or int(traits.get("flagella",0)) > 0
    var pili: bool = int(traits.get("pili",0)) > 0
    return PLAYER_BASE_SPEED * motility * (1.0 if motorized else (.87 if pili else .78))

static func npc_speed(traits: Dictionary) -> float:
    var motorized: bool = int(traits.get("archaella",0)) > 0 or int(traits.get("flagella",0)) > 0
    var pili: bool = int(traits.get("pili",0)) > 0
    # 0.74 NPC baseline was 1.00 world-units/s. Unmotorized cells now
    # move at exactly 0.90; engines/pili provide only earned extra mobility.
    return NPC_BASE_SPEED * clampf(float(traits.get("motility",1.0)),.35,2.6) * (
        1.15 if motorized else (1.03 if pili else 1.0))

static func motion_cost(distance: float, traits: Dictionary) -> float:
    # Evolution can make active movement less costly, never energy-free.
    var efficiency: float = clampf(float(traits.get("metabolism",1.0)),.55,2.5)
    return maxf(0.0,distance) * MOVEMENT_ATP_PER_WORLD_UNIT / sqrt(efficiency)

static func energy_step(atp: float, zero_seconds: float, elapsed: float,
                        distance: float, traits: Dictionary) -> Dictionary:
    var remaining: float = maxf(0.0,atp)
    remaining = maxf(0.0,remaining-BASE_ATP_UPKEEP*maxf(0.0,elapsed)-motion_cost(distance,traits))
    var shortage: float = 0.0 if remaining > .001 else zero_seconds+maxf(0.0,elapsed)
    return {"atp":remaining,"zero_seconds":shortage,"dead":shortage >= ZERO_ATP_DEATH_SECONDS}

static func npc_energy_step(energy: float, elapsed: float, distance: float) -> float:
    return maxf(0.0,energy - NPC_ATP_UPKEEP*maxf(0.0,elapsed) - maxf(0.0,distance)*NPC_ATP_MOVEMENT_COST)

static func strategy(traits: Dictionary) -> String:
    if int(traits.get("protease",0)) > 0 and float(traits.get("attack",1.0)) >= .98:
        return "predatore"
    if int(traits.get("flagella",0))+int(traits.get("archaella",0)) > 0 or (
        int(traits.get("pili",0)) > 0 and float(traits.get("motility",1.0)) >= 1.12):
        return "esploratore"
    if float(traits.get("defense",1.0)) >= 1.21 or bool(traits.get("eps",false)):
        return "difensore"
    return "raccoglitore"

static func strategy_speed(traits: Dictionary) -> float:
    var base: float = npc_speed(traits)
    var role: String = strategy(traits)
    if role == "predatore":
        return base*.76 # specialists in lysis have a costly, slow phenotype
    if role == "esploratore":
        return base*1.12
    if role == "difensore":
        return base*.89
    return base

static func start_population() -> int:
    return 76

static func nutrient_goal() -> int:
    return int(round(85*1.10))

static func initial_nutrients() -> int:
    return int(round(float(start_population())*1.10))
