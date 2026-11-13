extends RefCounted
class_name OutpostDisasterManager

signal disaster_started(disaster: Dictionary)
signal disaster_ended(disaster_id: String)
signal event_log(message: String)

var state: OutpostSimulationState
var resources: OutpostResourceManager
var config: OutpostSimulationConfig
var rng := RandomNumberGenerator.new()
var active_disasters: Array[Dictionary] = []

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager, cfg: OutpostSimulationConfig) -> void:
    state = sim_state
    resources = resource_manager
    config = cfg
    if config.random_seed == 0:
        rng.randomize()
    else:
        rng.seed = config.random_seed

func roll_daily_events(day: int) -> void:
    _tick_active_disasters()
    if rng.randf() > config.disaster_daily_chance:
        return
    var roll := rng.randf()
    if roll < 0.48:
        _start_dust_storm(day)
    elif roll < 0.70:
        _start_equipment_failure(day)
    elif roll < 0.86:
        _start_crop_pest(day)
    else:
        _start_radiation_event(day)

func _start_dust_storm(day: int) -> void:
    var duration := rng.randi_range(config.dust_storm_duration_min_days, config.dust_storm_duration_max_days)
    state.power.storm_days_remaining = maxi(int(state.power.storm_days_remaining), duration)
    var event := {"id": "dust_storm_%d" % day, "type": "dust_storm", "title": "Regional Dust Storm", "day": day, "duration_days": duration, "description": "Dust is reducing solar generation. Clean panels when conditions allow."}
    active_disasters.append(event)
    disaster_started.emit(event.duplicate(true))
    event_log.emit(event.description)

func _start_equipment_failure(day: int) -> void:
    var event := {"id": "equipment_failure_%d" % day, "type": "equipment_failure", "title": "Power Regulator Fault", "day": day, "duration_days": 1, "description": "A regulator fault has reduced solar panel efficiency. Repair the power system."}
    state.power.solar_condition = maxf(0.25, float(state.power.solar_condition) - 0.25)
    active_disasters.append(event)
    disaster_started.emit(event.duplicate(true))
    event_log.emit(event.description)

func _start_crop_pest(day: int) -> void:
    if state.crops.is_empty():
        return
    var index := rng.randi_range(0, state.crops.size() - 1)
    state.crops[index].health = maxf(0.0, float(state.crops[index].health) - 25.0)
    var event := {"id": "crop_pest_%d" % day, "type": "crop_pest", "title": "Greenhouse Contamination Alert", "day": day, "duration_days": 1, "description": "One crop tray has lost health. Inspect and isolate the affected tray."}
    active_disasters.append(event)
    disaster_started.emit(event.duplicate(true))
    event_log.emit(event.description)

func _start_radiation_event(day: int) -> void:
    var event := {"id": "solar_particle_event_%d" % day, "type": "solar_particle_event", "title": "Solar Particle Event", "day": day, "duration_days": 1, "description": "Crew should shelter in the storm room to reduce exposure."}
    active_disasters.append(event)
    disaster_started.emit(event.duplicate(true))
    event_log.emit(event.description)

func _tick_active_disasters() -> void:
    for i in range(active_disasters.size() - 1, -1, -1):
        var event: Dictionary = active_disasters[i]
        event.duration_days = int(event.duration_days) - 1
        if int(event.duration_days) <= 0:
            disaster_ended.emit(str(event.id))
            active_disasters.remove_at(i)
        else:
            active_disasters[i] = event

func get_active_disasters() -> Array[Dictionary]:
    return active_disasters.duplicate(true)
