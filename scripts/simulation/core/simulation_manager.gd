extends Node
class_name OutpostSimulationManager

signal state_updated(snapshot: Dictionary)
signal warning_raised(code: String, message: String)
signal simulation_day_completed(day: int, snapshot: Dictionary)
signal simulation_finished(final_report: Dictionary)

var config: OutpostSimulationConfig
var state := OutpostSimulationState.new()
var resources := OutpostResourceManager.new()
var agriculture := OutpostAgricultureSystem.new()
var power := OutpostPowerSystem.new()
var life_support := OutpostLifeSupportSystem.new()
var health := OutpostHealthSystem.new()
var radiation := OutpostRadiationSystem.new()
var disasters := OutpostDisasterManager.new()
var missions := OutpostMissionManager.new()
var initialized := false
var _last_day_processed: int = 0

func initialize(cfg: OutpostSimulationConfig = null) -> void:
    config = cfg if cfg != null else OutpostSimulationConfig.new()
    state = OutpostSimulationState.new()
    state.campaign_days = config.campaign_days
    state.resources = {
        "water_l": config.starting_water_l,
        "oxygen_kg": config.starting_oxygen_kg,
        "suit_oxygen_kg": config.starting_suit_oxygen_kg,
        "battery_kwh": config.starting_battery_kwh,
        "food_kg": config.starting_food_kg,
        "seeds": float(config.starting_seeds),
        "fertilizer_kg": config.starting_fertilizer_kg,
        "spare_parts": 5.0,
        "mission_credits": 0.0
    }
    state.crew.crew_count = config.max_crew
    resources.setup(state)
    agriculture.setup(state, resources)
    power.setup(state, resources, config)
    life_support.setup(state, resources, config)
    health.setup(state, resources, config)
    radiation.setup(state, config)
    disasters.setup(state, resources, config)
    disasters.disaster_started.connect(_on_disaster_started)
    missions.setup(state, resources)
    _last_day_processed = 0
    initialized = true
    _emit_state()

func advance_hours(hours: float) -> void:
    if not initialized or hours <= 0.0 or state.day > config.campaign_days:
        return
    var previous_day := state.day
    state.elapsed_hours = minf(float(config.campaign_days) * 24.0, state.elapsed_hours + hours)
    state.day = mini(config.campaign_days + 1, int(floor(state.elapsed_hours / 24.0)) + 1)
    state.hour_of_day = fmod(state.elapsed_hours, 24.0)
    while _last_day_processed < mini(state.day - 1, config.campaign_days):
        _process_completed_day(_last_day_processed + 1)
        _last_day_processed += 1
    if state.day > config.campaign_days:
        state.status = "completed"
        simulation_finished.emit(build_final_report())
    _emit_state()

func _process_completed_day(completed_day: int) -> void:
    # Fixed daily accounting order avoids frame-rate-dependent resource exploits.
    disasters.roll_daily_events(completed_day)
    if int(state.power.storm_days_remaining) > 0:
        resources.consume("water_l", config.dust_storm_water_leak_l_per_day)
        state.power.solar_condition = maxf(0.20, float(state.power.solar_condition) - config.solar_dust_loss_per_day * 2.0)
    var power_fraction := power.advance_day()
    agriculture.advance_day(power_fraction)
    life_support.advance_day(power_fraction)
    health.advance_day()
    radiation.advance_day()
    _check_warnings()
    state.history.append({
        "day": completed_day,
        "water_l": resources.amount("water_l"),
        "oxygen_kg": resources.amount("oxygen_kg"),
        "food_kg": resources.amount("food_kg"),
        "battery_kwh": resources.amount("battery_kwh"),
        "fitness": state.crew.fitness,
        "happiness": state.crew.happiness
    })
    simulation_day_completed.emit(completed_day, state.snapshot())

func _on_disaster_started(event: Dictionary) -> void:
    if str(event.get("type", "")) == "solar_particle_event":
        radiation.apply_solar_particle_event(3.5)
        warning_raised.emit("radiation_event", "Solar particle event: move crew to the storm shelter.")

func _check_warnings() -> void:
    if resources.amount("water_l") < config.water_emergency_threshold_l:
        warning_raised.emit("low_water", "Water reserves are low.")
    if resources.amount("oxygen_kg") < config.oxygen_emergency_threshold_kg:
        warning_raised.emit("low_oxygen", "Habitat oxygen reserves are low.")
    if resources.amount("food_kg") < config.food_emergency_threshold_kg:
        warning_raised.emit("low_food", "Stored food reserves are low.")
    if resources.amount("battery_kwh") < 15.0:
        warning_raised.emit("low_power", "Battery reserve is critically low.")
    if state.crew.health <= 25.0:
        warning_raised.emit("crew_health", "Crew health is critical.")

func _emit_state() -> void:
    state_updated.emit(state.snapshot())

func build_final_report() -> Dictionary:
    return {
        "days_completed": mini(state.day - 1, config.campaign_days),
        "campaign_days": config.campaign_days,
        "missions_completed": missions.completed_ids.size(),
        "missions_failed": missions.failed_ids.size(),
        "resources": state.resources.duplicate(true),
        "crew": state.crew.duplicate(true),
        "crop_harvests": state.history.size(),
        "status": state.status
    }
