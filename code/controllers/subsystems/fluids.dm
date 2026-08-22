/**
 * Sparse fluid simulation.
 *
 * Fluid tiles only process while their volume or local topology is changing.
 * Transfers are calculated against an immutable snapshot and applied in a
 * second phase, so iteration order cannot create or destroy fluid.
 */

#define FLUID_MINIMUM_VOLUME 0.1
#define FLUID_SETTLE_THRESHOLD 0.5
/// Maximum fraction of a lateral depth difference transferred per solve.
/// Must remain at or below 0.25 for a stable four-neighbor diffusion grid.
#define FLUID_FLOW_FRACTION 0.2
#define FLUID_WET_DEPTH 3
#define FLUID_SHALLOW_DEPTH 200
#define FLUID_MOB_HEAD_DEPTH 300
#define FLUID_DEEP_DEPTH 800
#define FLUID_MAX_DEPTH (FLUID_DEEP_DEPTH * 4)
#define FLUID_PUSH_THRESHOLD 20
#define FLUID_ASPIRATION_PER_BREATH 0.5
#define FLUID_ASPIRATION_IMPAIRMENT_START 2
#define FLUID_ASPIRATION_MAX 10
#define FLUID_ROBOTIC_LUNG_CLEARANCE_MULTIPLIER 1.2
#define FLUID_BREATH_HOLD_DURATION 2 MINUTES
#define FLUID_FALL_CUSHION_DEPTH (FLUID_MAX_DEPTH / 3)
#define FLUID_FALL_MIN_DAMAGE_MULTIPLIER 0.1

#define FLUID_PHASE_CALCULATE 1
#define FLUID_PHASE_APPLY 2

SUBSYSTEM_DEF(fluids)
	name = "Fluids"
	wait = 10
	flags = SS_NO_INIT | SS_BACKGROUND | SS_POST_FIRE_TIMING
	runlevels = RUNLEVELS_PLAYING

	/// Fluids which need another simulation step. Associative for O(1) deduplication.
	var/list/active_fluids = list()
	/// Every extant fluid tile, used for diagnostics rather than processing.
	var/list/all_fluids = list()
	/// Fluids with a pending volume delta in the current solve.
	var/list/apply_queue = list()
	/// Prevents a movable from being pushed more than once in a solve.
	var/list/pushed_atoms = list()

	var/list/currentrun
	var/phase = FLUID_PHASE_CALCULATE

/datum/controller/subsystem/fluids/stat_entry(msg)
	msg = "A:[length(active_fluids)] W:[length(all_fluids)]"
	return ..()

/datum/controller/subsystem/fluids/fire(resumed = FALSE)
	if(!resumed)
		currentrun = active_fluids.Copy()
		active_fluids.Cut()
		apply_queue.Cut()
		pushed_atoms.Cut()
		phase = FLUID_PHASE_CALCULATE

	if(phase == FLUID_PHASE_CALCULATE)
		while(length(currentrun))
			var/obj/effect/liquid/fluid = currentrun[length(currentrun)]
			currentrun.len--
			if(!QDELETED(fluid))
				fluid.calculate_flow()
			if(MC_TICK_CHECK)
				return
		phase = FLUID_PHASE_APPLY
		currentrun = apply_queue.Copy()

	while(length(currentrun))
		var/obj/effect/liquid/fluid = currentrun[length(currentrun)]
		currentrun.len--
		if(!QDELETED(fluid))
			fluid.apply_pending_flow()
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/fluids/proc/activate(obj/effect/liquid/fluid)
	if(fluid && !QDELETED(fluid))
		active_fluids[fluid] = TRUE

/datum/controller/subsystem/fluids/proc/queue_apply(obj/effect/liquid/fluid)
	if(fluid && !QDELETED(fluid))
		apply_queue[fluid] = TRUE

/datum/controller/subsystem/fluids/proc/queue_transfer(obj/effect/liquid/source, obj/effect/liquid/target, amount, direction)
	if(amount <= 0 || QDELETED(source) || QDELETED(target) || target.permanent_source)
		return 0

	// Several neighbors can feed one tile in the same solve. Reserve its capacity
	// here so clamping during the apply phase can never silently destroy fluid.
	amount = min(amount, FLUID_MAX_DEPTH - (target.volume + target.pending_volume))
	if(amount <= FLUID_MINIMUM_VOLUME)
		return 0

	if(!source.permanent_source)
		source.pending_volume -= amount
		source.pending_thermal_energy -= amount * source.temperature
		queue_apply(source)

	target.pending_volume += amount
	target.pending_thermal_energy += amount * source.temperature
	queue_apply(target)

	if(amount > source.flow_amount)
		source.flow_amount = amount
		source.flow_direction = direction
	return amount

/datum/controller/subsystem/fluids/proc/queue_drain(obj/effect/liquid/source, amount, direction)
	if(amount <= 0 || QDELETED(source) || source.permanent_source)
		return 0
	source.pending_volume -= amount
	source.pending_thermal_energy -= amount * source.temperature
	queue_apply(source)
	if(amount > source.flow_amount)
		source.flow_amount = amount
		source.flow_direction = direction
	return amount

#undef FLUID_PHASE_APPLY
#undef FLUID_PHASE_CALCULATE
