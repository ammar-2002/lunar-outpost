class_name AgricultureSystem
extends RefCounted

var _resources: ResourceManager
var _state: SimulationState


func setup(resource_manager: ResourceManager, simulation_state: SimulationState) -> void:
    _resources = resource_manager
    _state = simulation_state


func plant_crop(data: CropData) -> bool:
    if data == null:
        return false

    var seed_key := StringName("seed_%s" % String(data.crop_id))
    if not _resources.consume(seed_key, 1.0):
        return false

    var crop := CropInstance.new()
    crop.crop_data = data
    _state.crops.append(crop)
    return true


func advance(hours: float) -> void:
    for crop in _state.crops:
        if crop.is_failed or crop.is_harvested or crop.is_ready():
            continue

        var data := crop.crop_data
        if data == null:
            crop.is_failed = true
            continue

        var water_cost := data.water_per_hour * hours
        var energy_cost := data.energy_per_hour * hours
        var costs := {
            &"water": water_cost,
            &"battery_energy": energy_cost,
        }

        # Crop growth is paused if its full step requirements cannot be met.
        if not _resources.consume_many(costs):
            continue

        crop.growth_hours = minf(
            data.growth_duration_hours,
            crop.growth_hours + hours
        )
        _resources.produce(
            &"oxygen",
            data.oxygen_output_per_hour * hours
        )


func harvest_crop(index: int) -> bool:
    if index < 0 or index >= _state.crops.size():
        return false

    var crop := _state.crops[index]
    if not crop.is_ready():
        return false

    var food_key := StringName("food_%s" % String(crop.crop_data.crop_id))
    _resources.produce(food_key, crop.crop_data.food_yield)
    crop.is_harvested = true
    return true


func get_crop_status(index: int) -> Dictionary:
    if index < 0 or index >= _state.crops.size():
        return {}
    return _state.crops[index].make_snapshot()
