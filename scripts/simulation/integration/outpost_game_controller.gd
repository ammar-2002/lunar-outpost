extends Node
class_name OutpostGameController

## UI-facing facade. Add this node to Main.tscn, assign config if desired,
## then connect UI to these signals and public methods.

signal ui_state_changed(snapshot: Dictionary)
signal clock_ui_changed(clock_state: Dictionary)
signal mission_ui_changed(mission_board: Dictionary)
signal disaster_ui_changed(disaster: Dictionary)
signal warning_ui_raised(code: String, message: String)
signal action_result(action: String, result: Dictionary)
signal campaign_finished(report: Dictionary)

@export var simulation_config: OutpostSimulationConfig
@export var auto_start: bool = false

var clock := OutpostSimulationClock.new()
var simulation := OutpostSimulationManager.new()

func _ready() -> void:
    add_child(clock)
    add_child(simulation)
    simulation.initialize(simulation_config)
    clock.configure(simulation.config.campaign_days, simulation.config.real_seconds_per_game_day)
    clock.time_advanced.connect(_on_time_advanced)
    clock.day_started.connect(_on_day_started)
    clock.clock_changed.connect(func(data: Dictionary): clock_ui_changed.emit(data))
    clock.campaign_time_finished.connect(_on_clock_finished)
    simulation.state_updated.connect(func(data: Dictionary): ui_state_changed.emit(data))
    simulation.warning_raised.connect(func(code: String, message: String): warning_ui_raised.emit(code, message))
    simulation.disasters.disaster_started.connect(func(event: Dictionary): disaster_ui_changed.emit(event))
    simulation.missions.mission_activated.connect(func(_m: Dictionary): mission_ui_changed.emit(simulation.missions.get_mission_board()))
    simulation.missions.mission_progress.connect(func(_m: Dictionary): mission_ui_changed.emit(simulation.missions.get_mission_board()))
    simulation.missions.mission_completed.connect(func(_m: Dictionary): mission_ui_changed.emit(simulation.missions.get_mission_board()))
    simulation.missions.mission_failed.connect(func(_m: Dictionary): mission_ui_changed.emit(simulation.missions.get_mission_board()))
    simulation.simulation_finished.connect(func(report: Dictionary): campaign_finished.emit(report))
    ui_state_changed.emit(simulation.state.snapshot())
    clock_ui_changed.emit(_clock_snapshot())
    mission_ui_changed.emit(simulation.missions.get_mission_board())
    if auto_start:
        start_game()

func start_game() -> void:
    clock.start()

func pause_game() -> void:
    clock.pause()

func resume_game() -> void:
    clock.start()

func set_game_speed(multiplier: float) -> bool:
    return clock.set_speed(multiplier)

func reset_game() -> void:
    clock.reset()
    simulation.initialize(simulation_config)
    mission_ui_changed.emit(simulation.missions.get_mission_board())
    ui_state_changed.emit(simulation.state.snapshot())

func get_ui_snapshot() -> Dictionary:
    return {
        "clock": _clock_snapshot(),
        "simulation": simulation.state.snapshot(),
        "missions": simulation.missions.get_mission_board(),
        "disasters": simulation.disasters.get_active_disasters(),
        "crop_catalog": simulation.agriculture.get_catalog()
    }

func get_clock() -> OutpostSimulationClock:
    return clock

func get_simulation() -> OutpostSimulationManager:
    return simulation

func plant_crop(crop_id: String) -> Dictionary:
    var result := simulation.agriculture.plant_crop(crop_id)
    if bool(result.get("ok", false)):
        simulation.missions.record_action("plant_crop")
        _publish_action("plant_crop", result)
    return result

func harvest_crop(crop_instance_id: int) -> Dictionary:
    var crop_id := ""
    for crop in simulation.state.crops:
        if int(crop.id) == crop_instance_id:
            crop_id = str(crop.crop_id)
            break
    var result := simulation.agriculture.harvest_crop(crop_instance_id)
    if bool(result.get("ok", false)):
        simulation.missions.record_action("harvest_crop", 1, {"crop_id": crop_id})
        simulation.missions.record_action("leafy_harvest", 1, {"crop_id": crop_id})
        simulation.missions.record_action("tomato_harvest", 1, {"crop_id": crop_id})
        _publish_action("harvest_crop", result)
    return result

func harvest_all_ready() -> float:
    var harvested := 0.0
    var ids: Array[int] = []
    for crop in simulation.state.crops:
        if bool(crop.ready):
            ids.append(int(crop.id))
    for crop_id in ids:
        var result := harvest_crop(crop_id)
        if bool(result.get("ok", false)):
            harvested += float(result.food_kg)
    return harvested

func water_crop(crop_instance_id: int) -> Dictionary:
    for crop in simulation.state.crops:
        if int(crop.id) == crop_instance_id:
            if not simulation.resources.consume("water_l", 0.5):
                return {"ok": false, "reason": "Not enough water"}
            crop.health = minf(100.0, float(crop.health) + 5.0)
            simulation.missions.record_action("water_crop")
            var result := {"ok": true, "crop": crop.duplicate(true)}
            _publish_action("water_crop", result)
            return result
    return {"ok": false, "reason": "Crop not found"}

func exercise_crew() -> Dictionary:
    var result := simulation.health.exercise_crew()
    if bool(result.get("ok", false)):
        simulation.missions.record_action("exercise")
        _publish_action("exercise", result)
    return result

func clean_solar_panels() -> Dictionary:
    var result := simulation.power.clean_solar_panels()
    if bool(result.get("ok", false)):
        simulation.missions.record_action("power_maintenance")
        _publish_action("clean_solar_panels", result)
    return result

func repair_power_system() -> Dictionary:
    var result := simulation.power.repair_power_system()
    if bool(result.get("ok", false)):
        simulation.missions.record_action("power_maintenance")
        _publish_action("repair_power_system", result)
    return result

func refill_suit_oxygen(amount_kg: float = 3.0) -> Dictionary:
    var result := simulation.life_support.refill_suit_oxygen(amount_kg)
    _publish_action("refill_suit_oxygen", result)
    return result

func perform_eva(fitness_cost: float = 4.0, suit_oxygen_cost: float = 2.0) -> Dictionary:
    if not simulation.resources.consume("suit_oxygen_kg", suit_oxygen_cost):
        return {"ok": false, "reason": "Not enough suit oxygen"}
    var result := simulation.health.perform_demanding_activity(fitness_cost)
    if not bool(result.get("ok", false)):
        simulation.resources.produce("suit_oxygen_kg", suit_oxygen_cost)
        return result
    _publish_action("perform_eva", result)
    return result

func complete_systems_check() -> Dictionary:
    simulation.missions.record_action("systems_check")
    var result := {"ok": true, "message": "Systems check recorded"}
    _publish_action("systems_check", result)
    return result

func complete_radiation_drill() -> Dictionary:
    simulation.missions.record_action("radiation_drill")
    var result := {"ok": true, "message": "Radiation shelter drill recorded"}
    _publish_action("radiation_drill", result)
    return result

func _on_time_advanced(hours: float, _day: int, _hour: float) -> void:
    simulation.advance_hours(hours)

func _on_day_started(day: int) -> void:
    simulation.missions.on_day_started(day)
    if day == 1:
        simulation.missions.record_action("systems_check")

func _on_clock_finished() -> void:
    if simulation.state.status != "completed":
        simulation.advance_hours(0.001)

func _publish_action(action: String, result: Dictionary) -> void:
    action_result.emit(action, result)
    ui_state_changed.emit(simulation.state.snapshot())
    mission_ui_changed.emit(simulation.missions.get_mission_board())

func _clock_snapshot() -> Dictionary:
    return {
        "day": clock.get_day(),
        "hour": clock.get_hour_of_day(),
        "elapsed_hours": clock.elapsed_game_hours,
        "progress": clock.get_progress_ratio(),
        "speed": clock.speed,
        "running": clock.is_running,
        "campaign_days": clock.campaign_days
    }
