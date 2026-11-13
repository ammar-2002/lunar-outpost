extends RefCounted
class_name OutpostMissionManager

signal mission_activated(mission: Dictionary)
signal mission_progress(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal mission_failed(mission: Dictionary)

## Ten story milestones distributed across the 90-day expedition.
## A mission is active for its assigned 9-day chapter; player actions can
## complete it earlier. Daily survival continues between milestones.

const MISSION_DEFS := [
    {"id":"m01","day":1,"title":"Wake the Outpost","brief":"Run a systems check and confirm the habitat is operational.","action":"systems_check","target":1,"reward":8},
    {"id":"m02","day":5,"title":"First Seeds","brief":"Plant your first two greenhouse trays.","action":"plant_crop","target":2,"reward":10},
    {"id":"m03","day":19,"title":"Water Discipline","brief":"Recover and conserve water; complete one greenhouse watering action.","action":"water_crop","target":1,"reward":10},
    {"id":"m04","day":28,"title":"First Harvest","brief":"Harvest at least one mature radish or other ready crop.","action":"harvest_crop","target":1,"reward":15},
    {"id":"m05","day":37,"title":"Power Through the Storm","brief":"Clean the solar array or repair the power regulator.","action":"power_maintenance","target":1,"reward":12},
    {"id":"m06","day":46,"title":"Fresh Greens","brief":"Harvest two mature leafy crop trays.","action":"leafy_harvest","target":2,"reward":15},
    {"id":"m07","day":55,"title":"Crew Fitness","brief":"Complete two exercise sessions.","action":"exercise","target":2,"reward":10},
    {"id":"m08","day":64,"title":"Fruit on Mars","brief":"Plant and maintain a dwarf tomato crop until it reaches maturity.","action":"tomato_harvest","target":1,"reward":20},
    {"id":"m09","day":73,"title":"Radiation Readiness","brief":"Complete a radiation shelter drill and keep cumulative dose below the danger threshold.","action":"radiation_drill","target":1,"reward":15},
    {"id":"m10","day":82,"title":"A Sustainable Outpost","brief":"Finish with adequate water, oxygen, food, and a functioning power reserve.","action":"sustainability_check","target":1,"reward":25}
]

var current_index: int = -1
var active: Dictionary = {}
var progress_count: int = 0
var completed_ids: Array[String] = []
var failed_ids: Array[String] = []
var state: OutpostSimulationState
var resources: OutpostResourceManager

func setup(sim_state: OutpostSimulationState, resource_manager: OutpostResourceManager) -> void:
    state = sim_state
    resources = resource_manager

func on_day_started(day: int) -> void:
    if not active.is_empty() and day > int(active.day) + 8 and progress_count < int(active.target):
        failed_ids.append(str(active.id))
        mission_failed.emit(active.duplicate(true))
        active = {}
    for i in range(MISSION_DEFS.size()):
        if int(MISSION_DEFS[i].day) == day and not completed_ids.has(str(MISSION_DEFS[i].id)):
            current_index = i
            active = MISSION_DEFS[i].duplicate(true)
            progress_count = 0
            mission_activated.emit(get_active_mission())
            break

func record_action(action: String, amount: int = 1, metadata: Dictionary = {}) -> void:
    if active.is_empty() or str(active.action) != action:
        return
    if action == "leafy_harvest" and not ["lettuce", "mizuna", "kale"].has(str(metadata.get("crop_id", ""))):
        return
    if action == "tomato_harvest" and str(metadata.get("crop_id", "")) != "tomato":
        return
    progress_count = mini(int(active.target), progress_count + maxi(1, amount))
    mission_progress.emit(get_active_mission())
    if progress_count >= int(active.target):
        var finished := active.duplicate(true)
        completed_ids.append(str(active.id))
        active = {}
        resources.produce("mission_credits", float(finished.reward))
        mission_completed.emit(finished)

func check_sustainability() -> bool:
    return resources.amount("water_l") >= 100.0 and resources.amount("oxygen_kg") >= 20.0 and resources.amount("food_kg") >= 10.0 and resources.amount("battery_kwh") >= 10.0

func get_active_mission() -> Dictionary:
    if active.is_empty():
        return {}
    var result := active.duplicate(true)
    result["progress"] = progress_count
    result["target"] = int(active.target)
    result["progress_ratio"] = float(progress_count) / maxf(1.0, float(active.target))
    return result

func get_mission_board() -> Dictionary:
    return {
        "active": get_active_mission(),
        "completed_ids": completed_ids.duplicate(),
        "failed_ids": failed_ids.duplicate(),
        "total": MISSION_DEFS.size(),
        "missions": MISSION_DEFS.duplicate(true)
    }
