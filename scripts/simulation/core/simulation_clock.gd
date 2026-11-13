extends Node
class_name OutpostSimulationClock

signal time_advanced(hours: float, day: int, hour_of_day: float)
signal day_started(day: int)
signal clock_changed(clock_state: Dictionary)
signal campaign_time_finished

var campaign_days: int = 90
var real_seconds_per_game_day: float = 400.0
var speed: float = 1.0
var is_running: bool = false
var elapsed_game_hours: float = 0.0
var _last_emitted_day: int = 0

func configure(days: int, real_seconds_per_day: float) -> void:
    campaign_days = maxi(1, days)
    real_seconds_per_game_day = maxf(1.0, real_seconds_per_day)
    reset()

func reset() -> void:
    elapsed_game_hours = 0.0
    _last_emitted_day = 0
    is_running = false
    _emit_clock()

func start() -> void:
    if get_day() <= campaign_days:
        is_running = true
        if _last_emitted_day == 0:
            _last_emitted_day = 1
            day_started.emit(1)
        _emit_clock()

func pause() -> void:
    is_running = false
    _emit_clock()

func set_speed(multiplier: float) -> bool:
    if not [1.0, 2.0, 4.0].has(multiplier):
        return false
    speed = multiplier
    _emit_clock()
    return true

func get_day() -> int:
    return mini(campaign_days + 1, int(floor(elapsed_game_hours / 24.0)) + 1)

func get_hour_of_day() -> float:
    return fmod(elapsed_game_hours, 24.0)

func get_progress_ratio() -> float:
    return clampf(elapsed_game_hours / (campaign_days * 24.0), 0.0, 1.0)

func _process(delta: float) -> void:
    if not is_running:
        return
    if elapsed_game_hours >= campaign_days * 24.0:
        _finish()
        return
    var hours_per_real_second := 24.0 / real_seconds_per_game_day
    var increment := delta * hours_per_real_second * speed
    var old_day := get_day()
    elapsed_game_hours = minf(campaign_days * 24.0, elapsed_game_hours + increment)
    var new_day := get_day()
    time_advanced.emit(increment, new_day, get_hour_of_day())
    if new_day != old_day and new_day <= campaign_days:
        _last_emitted_day = new_day
        day_started.emit(new_day)
    _emit_clock()
    if elapsed_game_hours >= campaign_days * 24.0:
        _finish()

func _finish() -> void:
    is_running = false
    campaign_time_finished.emit()
    _emit_clock()

func _emit_clock() -> void:
    clock_changed.emit({
        "day": get_day(),
        "hour": get_hour_of_day(),
        "elapsed_hours": elapsed_game_hours,
        "progress": get_progress_ratio(),
        "speed": speed,
        "running": is_running,
        "campaign_days": campaign_days
    })
