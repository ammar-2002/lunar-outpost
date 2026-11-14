extends RefCounted
class_name OutpostAgricultureSystem

signal crop_changed(crop: Dictionary)
signal crop_harvested(crop_id: String, food_kg: float)
signal crop_lost(crop_id: String, reason: String)

var state: OutpostSimulationState
var resources: OutpostResourceManager
var catalog := OutpostCropCatalog.new()
var next_crop_id: int = 1

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager) -> void:
    state = sim_state
    resources = resource_manager

func plant_crop(crop_id: String) -> Dictionary:
    var definition := catalog.get_crop(crop_id)
    if definition.is_empty():
        return {"ok": false, "reason": "Unknown crop"}
    if state.crops.size() >= 12:
        return {"ok": false, "reason": "Greenhouse is full (12 growing trays)"}
    if not resources.consume_many({"seeds": 1.0, "fertilizer_kg": float(definition.fertilizer_kg)}):
        return {"ok": false, "reason": "Not enough seeds or fertilizer"}
    var crop := {
        "id": next_crop_id,
        "crop_id": crop_id,
        "name": definition.display_name,
        "age_days": 0.0,
        "days_to_harvest": float(definition.days_to_harvest),
        "health": 100.0,
        "stage": "seedling",
        "ready": false,
        "water_stress_days": 0.0
    }
    next_crop_id += 1
    state.crops.append(crop)
    crop_changed.emit(crop.duplicate(true))
    return {"ok": true, "crop": crop.duplicate(true)}

func advance_day(power_fraction: float = 1.0) -> void:
    for index in range(state.crops.size() - 1, -1, -1):
        var crop: Dictionary = state.crops[index]
        var definition := catalog.get_crop(str(crop.crop_id))
        var water_cost := float(definition.water_l_per_day)
        var energy_cost := float(definition.energy_kwh_per_day)
        var water_ok := resources.consume("water_l", water_cost)
        var energy_ok := power_fraction >= 0.45 and resources.consume("battery_kwh", energy_cost)
        if not water_ok:
            crop.water_stress_days = float(crop.water_stress_days) + 1.0
            crop.health = maxf(0.0, float(crop.health) - 12.0)
        elif not energy_ok:
            crop.health = maxf(0.0, float(crop.health) - 7.0)
        else:
            crop.age_days = float(crop.age_days) + 1.0
            crop.health = minf(100.0, float(crop.health) + 1.0)
            # Net oxygen contribution is a simplified game abstraction.
            resources.produce("oxygen_kg", float(definition.oxygen_kg_per_day) * (float(crop.health) / 100.0))
        if float(crop.health) <= 0.0:
            crop_lost.emit(str(crop.crop_id), "Crop health reached zero")
            state.crops.remove_at(index)
            continue
        var progress := float(crop.age_days) / maxf(1.0, float(crop.days_to_harvest))
        if progress >= 1.0:
            crop.stage = "mature"
            crop.ready = true
        elif progress >= 0.7:
            crop.stage = "fruiting"
        elif progress >= 0.25:
            crop.stage = "growing"
        else:
            crop.stage = "seedling"
        state.crops[index] = crop
        crop_changed.emit(crop.duplicate(true))

func harvest_crop(instance_id: int) -> Dictionary:
    for i in range(state.crops.size()):
        var crop: Dictionary = state.crops[i]
        if int(crop.id) == instance_id:
            if not bool(crop.ready):
                return {"ok": false, "reason": "Crop is not mature yet"}
            var definition := catalog.get_crop(str(crop.crop_id))
            var yield_kg := float(definition.food_kg) * (float(crop.health) / 100.0)
            resources.produce("food_kg", yield_kg)
            resources.produce("seeds", 0.35)
            state.crops.remove_at(i)
            crop_harvested.emit(str(crop.crop_id), yield_kg)
            return {"ok": true, "food_kg": yield_kg}
    return {"ok": false, "reason": "Crop not found"}

func harvest_all_ready() -> float:
    var ids: Array[int] = []
    for crop in state.crops:
        if bool(crop.ready):
            ids.append(int(crop.id))
    var total := 0.0
    for crop_id in ids:
        var result := harvest_crop(crop_id)
        if bool(result.get("ok", false)):
            total += float(result.food_kg)
    return total

func get_catalog() -> Dictionary:
    return OutpostCropCatalog.CROPS.duplicate(true)
