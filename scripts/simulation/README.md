# Mars Outpost Simulation scripts

This folder is designed to be copied into the existing Godot repository without
moving or renaming the current scenes, assets, materials, or world scripts.

## Folder layout

- `core/`: simulation coordinator, runtime state, tunable configuration
- `systems/`: resource, agriculture, life support, power, health, radiation
- `models/`: crop definitions and individual crop instances
- `integration/`: small adapters for the teammate-owned clock and event modules

## Add to the existing repository

Copy the `scripts/simulation/` folder into the project root. Godot 4 will import
the scripts and generate `.uid` files when the project is opened.

Attach `simulation_manager.gd` to a Node in `Main.tscn` (or instantiate it from
your existing main controller). Assign a `SimulationConfig` `.tres` resource in
the Inspector when ready. If none is assigned, default placeholder values are used.

## Connecting the clock

Once the clock module's real signal is known, connect it to
`ClockAdapter.on_time_advanced(elapsed_hours)`, or call
`SimulationManager.advance_simulation(elapsed_hours)` directly.

## Event dictionary contract

Dust storm:

```gdscript
{
    "type": "dust_storm",
    "intensity": 0.0, # normalized 0..1
    "duration_hours": 12.0
}
```

Radiation exposure:

```gdscript
{
    "type": "radiation",
    "dose_rate": 0.0,
    "duration_hours": 1.0,
    "shielding_factor": 1.0
}
```

The radiation rate and accumulated dose must use the same documented unit
convention. Do not feed a DONKI event probability or CME speed directly into
`dose_rate`; a scientific conversion/model is needed first.

## Crop setup

Create one `CropData` resource (`.tres`) per crop type. Set its `crop_id`,
growth duration, water/energy requirements, yield, and oxygen output in the
Inspector. These values are gameplay parameters until validated against
appropriate research.

Plant a crop from gameplay code:

```gdscript
var crop_data: CropData = preload("res://data/crops/lettuce.tres")
simulation_manager.agriculture.plant_crop(crop_data)
```

Harvest it by its index in `state.crops`:

```gdscript
simulation_manager.agriculture.harvest_crop(0)
```

## Important prototype limitations

- Numeric defaults are placeholders, not NASA measurements, medical advice,
  or validated Mars habitat engineering values.
- This is an initial code foundation, not a complete life-support simulator.
- Resource shortage consequences/game-over rules are intentionally left to the
  game design. Current life-support consumption stops at zero and emits resource
  warnings through the manager.
- Crop growth currently pauses when a full timestep's water or battery energy
  cost cannot be paid.
- The current crop model treats oxygen output as a configured gameplay rate.
  A more scientifically grounded model should account for lighting, plant
  respiration, growth stage, and environmental conditions.
- Health and nutrition are hooks for the next iteration. The current food effect
  is deliberately simple and should be replaced with cumulative nutrition logic.
- Shielding uses a simplified transmission factor, not a validated shielding
  transport calculation.
- The simulation update order and allocation priorities should be playtested.
  If multiple systems compete for scarce resources, introduce an explicit
  priority/allocation phase before final balancing.
