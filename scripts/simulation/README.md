# Mars Outpost Simulation — Godot 4 starter integration

## Campaign pacing

- Campaign: 90 simulated days.
- At 1x: 400 real seconds per simulated day (6 minutes 40 seconds).
- Total: 36,000 real seconds = 10 hours.
- 2x speed: 5 hours; 4x speed: 2.5 hours.
- One simulated day is 24 simulated hours.
- The clock is independent of rendering frame rate and emits elapsed game hours.

The 90-day span allows several crop cycles to mature. The crop harvest targets are game-design values informed by Earth/ISS analogue references, not guaranteed Mars production:
- Radish: 27 days (NASA APH radish maturity reference)
- Red romaine lettuce: 33 days (NASA Veggie flight grow-outs)
- Mizuna mustard: 35 days (NASA VEG-04 harvest reference)
- Red Russian kale: 42 days (gameplay target; NASA sustained Veggie work tested repeated leafy harvests)
- Dwarf tomato: 60 days (gameplay target within CSA's approximate 50–90 day tomato range)

## Install

1. Extract the `scripts/` folder into the root of the Godot project. Merge with the existing `scripts/` folder; do not replace your teammate's world/building scripts.
2. In `scenes/main/Main.tscn`, add a Node named `OutpostGameController`.
3. Attach `scripts/simulation/integration/outpost_game_controller.gd`.
4. Optional: create a Resource using `scripts/simulation/core/simulation_config.gd` and assign it to `simulation_config`. Defaults are already supplied in code.
5. Connect your UI to the controller signals listed below. The UI should not manipulate resource dictionaries directly.
6. Call `start_game()` after the player presses Start.

## UI-facing API

Signals:
- `ui_state_changed(snapshot: Dictionary)`
- `clock_ui_changed(clock_state: Dictionary)`
- `mission_ui_changed(mission_board: Dictionary)`
- `disaster_ui_changed(disaster: Dictionary)`
- `warning_ui_raised(code: String, message: String)`
- `action_result(action: String, result: Dictionary)`
- `campaign_finished(report: Dictionary)`

Methods:
- `start_game()`, `pause_game()`, `resume_game()`, `set_game_speed(1.0|2.0|4.0)`, `reset_game()`
- `get_ui_snapshot()`
- `plant_crop(crop_id: String)`
- `harvest_crop(crop_instance_id: int)`, `harvest_all_ready()`
- `water_crop(crop_instance_id: int)`
- `exercise_crew()`
- `clean_solar_panels()`, `repair_power_system()`
- `refill_suit_oxygen(amount_kg = 3.0)`
- `perform_eva(fitness_cost = 4.0, suit_oxygen_cost = 2.0)`
- `complete_systems_check()`, `complete_radiation_drill()`

Snapshot shape:
- `snapshot.day`, `snapshot.hour_of_day`, `snapshot.elapsed_hours`, `snapshot.campaign_days`
- `snapshot.resources`: `water_l`, `oxygen_kg`, `suit_oxygen_kg`, `battery_kwh`, `food_kg`, `seeds`, `fertilizer_kg`, `spare_parts`, `mission_credits`
- `snapshot.crops`: array of dictionaries with `id`, `crop_id`, `name`, `age_days`, `days_to_harvest`, `health`, `stage`, `ready`
- `snapshot.crew`: `fitness`, `happiness`, `health`, `radiation_dose_msv`, `crew_count`
- `snapshot.power`: solar condition, dust level, storm duration, daily generation/usage
- `snapshot.status`: operational or completed

## Mission plan

Ten story missions activate on days 1, 5, 19, 28, 37, 46, 55, 64, 73, and 82. Each has a nine-day chapter window and can be completed earlier. Daily survival simulation and random events continue between mission milestones. Objectives cover systems checks, planting (day 5 leaves enough time for the first 27-day radish crop), crop care, first harvest, power maintenance, leafy harvest, crew exercise, tomato harvest, radiation drill, and end-of-campaign sustainability.

## Disasters

A configurable daily roll can trigger:
- Dust storm: reduces solar generation for multiple days.
- Power regulator fault: reduces solar array condition until repaired.
- Greenhouse contamination: damages a random crop tray.
- Solar particle event: produces a radiation shelter-drill event.

Set `random_seed` to a non-zero integer for repeatable test runs. Set it to zero for random runs.

## Important balancing notes

All resource starting quantities, consumption rates, crop yields, event probabilities, radiation rates, and health effects are educational gameplay estimates. They are intentionally exposed in `OutpostSimulationConfig` so the team can tune them after playtesting. The resource accounting order is fixed per simulated day: disaster roll, power generation/consumption, agriculture, crew life support, health, radiation, warnings.

This package has not been executed in the Godot editor or validated against your project's exact Godot version/scenes. Import it, run a parser check, then test the integration steps below before treating it as production-ready.

## Suggested smoke test

1. Add controller node and run project.
2. Connect a temporary debug label to `clock_ui_changed` and verify day/hour progression.
3. Start at 1x; one day should pass in 6m40s. At 4x, one day should pass in 1m40s.
4. Plant radish on day 1 and verify it becomes ready after 27 simulated days.
5. Trigger/observe a dust storm; verify solar generation is reduced.
6. Harvest a mature crop and verify food stock rises.
7. Pause and confirm the clock and simulation stop.
8. Let the campaign finish and verify `campaign_finished`.

## Research references

- NASA, *Astronauts Harvest Radish Crop on International Space Station*: radishes mature in 27 days. https://www.nasa.gov/missions/station/astronauts-harvest-radish-crop-on-international-space-station/
- NASA, *Veggie Fact Sheet*: lettuce flight crops were grown for 33 days. https://science.nasa.gov/wp-content/uploads/2023/04/veggie_fact_sheet_508.pdf
- NASA NTRS, *Pick-and-eat space crop production flight testing*: mizuna harvest at 35 days in one trial. https://ntrs.nasa.gov/api/citations/20240000823/downloads/2024%20Buncheck%20VEG-04.pdf
- Canadian Space Agency, *Interplanetary Farming*: approximate crop growth times and crop-selection factors, including tomato 50–90 days. https://www.asc-csa.gc.ca/eng/youth-educators/activities/fitness-and-nutrition/interplanetary-farming.asp
- NASA, *Growing Plants in Space*: documented Veggie crops and future crop research. https://www.nasa.gov/exploration-research-and-technology/growing-plants-in-space/

## Known prototype limitations to resolve in playtesting

- Mission objectives are story milestones, not a full branching narrative.
- Radiation shelter drill currently records completion; it does not yet simulate a timed shelter state.
- Crop watering is a manual health boost while normal crop water use is accounted daily.
- Harvest outputs and nutrition are simplified; crop nutrition is exposed in the catalog for a later diet model.
- Dust storms reduce solar generation, but dust accumulation/cleaning is represented as a simple condition scalar.
- The daily resource model is discrete; it does not model minute-by-minute life support. The oxygen regeneration unit and crop oxygen contribution are simplified gameplay models; they are not detailed engineering simulations.
- UI actions should be disabled/greyed when returned `{"ok": false}`.
