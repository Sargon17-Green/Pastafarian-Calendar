//! Stage07 — PATCH03: correct the distance selected from the Stage06 legacy observation.
//! The Stage06 value is preserved in WorkCounts; the corrected result is call-local.

use num_bigint::BigInt;
use num_traits::{One, Signed};

use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch03DistanceObservation {
    pub legacy_distance: BigInt,
    pub chronological_base: BigInt,
    pub legacy_mismatch: bool,
    pub selected_base: BigInt,
    pub distance: BigInt,
}

pub struct Patch03DistanceCorrection;

impl PhaseHandler for Patch03DistanceCorrection {
    fn name(&self) -> &'static str {
        "PATCH03:CHRONOLOGICAL-DISTANCE-CORRECTION"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.patch03_distance_observation.is_some()
            || context.metrics.get("patch03.distance.calls") != 0
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH03: təkrar çağırış qadağandır.".to_owned(),
            });
        }

        if context.metrics.get("patch02.work_counts.calls") != 1
            || context.metrics.get("patch02.legacy.action.calls") != 1
            || context.metrics.get("patch02.legacy.target.calls") != 1
            || context.metrics.get("discovery03.distance.calls") != 1
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH03: PATCH02 və DISCOVERY03 müşahidələri tam deyil.".to_owned(),
            });
        }

        let legacy_distance = context
            .work_counts_observation
            .as_ref()
            .map(|counts| counts.distance.clone())
            .ok_or_else(|| MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH03: Stage06 məsafə müşahidəsi yoxdur.".to_owned(),
            })?;

        let chronological_base = (&context.target_day - &context.calculation_day).abs();
        let legacy_mismatch = legacy_distance != chronological_base;
        let selected_base = if legacy_mismatch {
            chronological_base.clone()
        } else {
            legacy_distance.clone()
        };
        let distance = &selected_base + BigInt::one();

        context.logs.push(format!(
            "PATCH03:legacy={legacy_distance} chronological={chronological_base} mismatch={legacy_mismatch} selected={selected_base} distance={distance}"
        ));
        context.patch03_distance_observation = Some(Patch03DistanceObservation {
            legacy_distance,
            chronological_base,
            legacy_mismatch,
            selected_base,
            distance,
        });
        context.metrics.bump("patch03.distance.calls");
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch03Observation {
    pub calculation_day: BigInt,
    pub target_day: BigInt,
    pub result: Patch03DistanceObservation,
    pub context: MonsterContext,
}

/// Run the complete production chain: PATCH02 -> DISCOVERY03 -> PATCH03.
pub fn calculate_patched_distance(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch03Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager
        .dispatcher_mut()
        .register(LegacyTagDistanceDiscovery03);
    manager
        .dispatcher_mut()
        .register(Patch03DistanceCorrection);

    let context = manager.execute_bootstrap_shell(calculation_day.clone(), target_day.clone())?;
    let result = context
        .patch03_distance_observation
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "PATCH03: nəticə müşahidəsi yoxdur.".to_owned(),
        })?;

    Ok(Patch03Observation {
        calculation_day,
        target_day,
        result,
        context,
    })
}
