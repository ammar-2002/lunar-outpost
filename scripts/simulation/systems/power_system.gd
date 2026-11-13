extends RefCounted
class_name OutpostPowerSystem

signal power_status_changed(status: Dictionary)
var state: OutpostSimulationState
var resources: OutpostResourceManager
var config: OutpostSimulationConfig

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager, cfg: OutpostSimulationConfig) -> void:
    state = sim_state
    resources = resource_manager
    config = cfg

func advance_day() -> float:
    var storm_factor := 1.0
    if int(state.power.storm_days_remaining) > 0:
        storm_factor = 1.0 - config.dust_storm_solar_reduction
        state.power.storm_days_remaining = int(state.power.storm_days_remaining) - 1
    var generation := config.solar_generation_kwh_per_day * float(state.power.solar_condition) * storm_factor
    resources.produce("battery_kwh", generation, config.battery_capacity_kwh)
    state.power.power_generated_today_kwh = generation
    var demand := config.base_power_kwh_per_day + config.greenhouse_power_kwh_per_day
    var available := resources.amount("battery_kwh")
    var supplied := minf(available, demand)
    resources.consume("battery_kwh", supplied)
    state.power.power_used_today_kwh = supplied
    var fraction := 1.0 if demand <= 0.0 else supplied / demand
    state.power.dust_level = clampf(1.0 - float(state.power.solar_condition), 0.0, 1.0)
    power_status_changed.emit({
        "generated_kwh": generation,
        "used_kwh": supplied,
        "demand_kwh": demand,
        "supply_fraction": fraction,
        "battery_kwh": resources.amount("battery_kwh"),
        "solar_condition": state.power.solar_condition
    })
    return fraction

func clean_solar_panels() -> Dictionary:
    var cost := {"water_l": 3.0, "battery_kwh": 1.0}
    if not resources.consume_many(cost):
        return {"ok": false, "reason": "Need 3 L water and 1 kWh"}
    state.power.solar_condition = minf(1.0, float(state.power.solar_condition) + config.solar_cleaning_restore)
    return {"ok": true, "solar_condition": state.power.solar_condition}

func repair_power_system() -> Dictionary:
    if not resources.consume_many({"spare_parts": 1.0, "battery_kwh": 2.0}):
        return {"ok": false, "reason": "Need one spare part and 2 kWh"}
    state.power.solar_condition = minf(1.0, float(state.power.solar_condition) + 0.35)
    return {"ok": true}
