extends RefCounted
class_name OutpostLifeSupportSystem

signal life_support_status_changed(status: Dictionary)
var state: OutpostSimulationState
var resources: OutpostResourceManager
var config: OutpostSimulationConfig

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager, cfg: OutpostSimulationConfig) -> void:
    state = sim_state
    resources = resource_manager
    config = cfg

func advance_day(power_fraction: float) -> void:
    var crew_count := int(state.crew.crew_count)
    var water_need := config.crew_water_l_per_person_day * crew_count
    var oxygen_need := config.crew_oxygen_kg_per_person_day * crew_count
    var food_need := config.crew_food_kg_per_person_day * crew_count
    # Regenerative oxygen unit: simplified electrolysis/recycling gameplay model.
    if resources.consume_many({"water_l": config.oxygen_generator_water_l_per_day, "battery_kwh": config.oxygen_generator_power_kwh_per_day}):
        resources.produce("oxygen_kg", config.oxygen_regeneration_kg_per_day)
    var water_used := minf(resources.amount("water_l"), water_need)
    resources.consume("water_l", water_used)
    # Greywater recovery returns part of consumed water after processing.
    resources.produce("water_l", water_used * config.water_recovery_fraction)
    var oxygen_used := minf(resources.amount("oxygen_kg"), oxygen_need)
    resources.consume("oxygen_kg", oxygen_used)
    var food_used := minf(resources.amount("food_kg"), food_need)
    resources.consume("food_kg", food_used)
    var water_ratio := 1.0 if water_need <= 0.0 else water_used / water_need
    var oxygen_ratio := 1.0 if oxygen_need <= 0.0 else oxygen_used / oxygen_need
    var food_ratio := 1.0 if food_need <= 0.0 else food_used / food_need
    if water_ratio < 0.999:
        state.crew.health = maxf(0.0, float(state.crew.health) - 8.0)
    if oxygen_ratio < 0.999:
        state.crew.health = maxf(0.0, float(state.crew.health) - 15.0)
    if food_ratio < 0.999:
        state.crew.health = maxf(0.0, float(state.crew.health) - 5.0)
        state.crew.happiness = maxf(0.0, float(state.crew.happiness) - 4.0)
    if power_fraction < 0.75:
        state.crew.happiness = maxf(0.0, float(state.crew.happiness) - 2.0)
    life_support_status_changed.emit({
        "water_need_l": water_need, "water_used_l": water_used,
        "oxygen_need_kg": oxygen_need, "oxygen_used_kg": oxygen_used,
        "food_need_kg": food_need, "food_used_kg": food_used,
        "water_sufficiency": water_ratio, "oxygen_sufficiency": oxygen_ratio,
        "food_sufficiency": food_ratio
    })

func refill_suit_oxygen(amount_kg: float = 3.0) -> Dictionary:
    if amount_kg <= 0.0:
        return {"ok": false, "reason": "Amount must be positive"}
    if not resources.consume("oxygen_kg", amount_kg):
        return {"ok": false, "reason": "Not enough habitat oxygen"}
    resources.produce("suit_oxygen_kg", amount_kg)
    return {"ok": true, "suit_oxygen_kg": resources.amount("suit_oxygen_kg")}
