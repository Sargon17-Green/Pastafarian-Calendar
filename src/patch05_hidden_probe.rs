//! Stage11 / PATCH05: translate the logical index, without rebuilding storage.
use num_bigint::BigInt;

use crate::discovery04_stone_probe::LegacyStoneDiscovery04;
use crate::discovery05_hidden_probe::LegacyHiddenDropDiscovery05;
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::patch04_stone_probe::StonePatch04;
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch05HiddenObservation {
    pub requested_k: usize,
    pub physical_index: usize,
    pub actual: BigInt,
}

fn invalid(message: &str) -> MonsterError {
    MonsterError {
        code: MonsterErrorCode::InvalidState,
        message: format!("PATCH05: {message}"),
    }
}

pub fn corrected_hidden_by_nearness(
    backward: &[BigInt],
    k: usize,
) -> Result<Patch05HiddenObservation, MonsterError> {
    if !(1..=7).contains(&k) {
        return Err(invalid("logical index must be 1..=7"));
    }
    if backward.len() != 8 || backward[0] != BigInt::from(0u8) {
        return Err(invalid("invalid backward storage shape or sentinel"));
    }
    let physical_index = 8 - k;
    Ok(Patch05HiddenObservation {
        requested_k: k,
        physical_index,
        actual: backward[physical_index].clone(),
    })
}

pub struct HiddenDropPatch05 {
    pub requested_k: usize,
}

impl PhaseHandler for HiddenDropPatch05 {
    fn name(&self) -> &'static str {
        "PATCH05:BACKWARD-HIDDEN-LOGICAL-ACCESS"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.patch05_hidden_observation.is_some()
            || context.metrics.get("patch05.applied") != 0
            || context.metrics.get("patch05.corrected.read") != 0
        {
            return Err(invalid("duplicate application"));
        }
        if !(1..=7).contains(&self.requested_k)
            || context.discovery05_requested_k != Some(self.requested_k)
            || context.discovery05_hidden_count != 7
            || context.discovery05_patch04_legacy_calls != 45
            || context.metrics.get("discovery05.builds") != 1
            || context.metrics.get("discovery05.legacy.direct.read") != 1
            || context.metrics.get("patch04.applied") != 1
            || context.metrics.get("patch04.legacy.calls") != 45
            || context.metrics.get("patch03.distance.calls") != 1
            || context.metrics.get("patch02.work_counts.calls") != 1
        {
            return Err(invalid("inconsistent discovery observation or counters"));
        }
        let storage = context
            .discovery05_backward_storage
            .as_ref()
            .ok_or_else(|| invalid("missing backward storage"))?;
        let patch = context
            .patch04_stone_observation
            .as_ref()
            .ok_or_else(|| invalid("missing PATCH04 observation"))?;
        let work = context
            .work_counts_observation
            .as_ref()
            .ok_or_else(|| invalid("missing PATCH02 observation"))?;
        if context.patch03_distance_observation.is_none()
            || context.discovery04_stone_observation.is_none()
            || patch.corrected_rows.len() != 46
            || patch.row_count != 46
            || patch.component_count != 230
            || patch.legacy_calls != 45
            || context.discovery05_stone_rows.as_ref() != Some(&patch.corrected_rows)
            || work.connection != &work.action + &work.target
            || !(1..=3).contains(&work.direction)
        {
            return Err(invalid("inconsistent predecessor observations"));
        }
        let corrected = corrected_hidden_by_nearness(storage, self.requested_k)?;
        if context.discovery05_actual.as_ref() != storage.get(self.requested_k) {
            return Err(invalid("legacy observation does not match physical direct read"));
        }

        // Commit only after every check. The historical observation is untouched.
        context.logs.push(format!(
            "PATCH05: requested_k={} physical_index={} actual={}",
            corrected.requested_k, corrected.physical_index, corrected.actual
        ));
        context
            .diagnostics
            .push("PATCH05_BACKWARD_HIDDEN_LOGICAL_ACCESS".to_owned());
        context.patch05_hidden_observation = Some(corrected);
        context.metrics.bump("patch05.corrected.read");
        context.metrics.bump("patch05.applied");
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch05RouteObservation {
    pub backward_storage: Vec<BigInt>,
    pub corrected: Patch05HiddenObservation,
    pub context: MonsterContext,
}

/// Successor default route; Stage10's explicitly historical module is preserved.
pub fn calendar_hidden_spaghetti(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch05RouteObservation, MonsterError> {
    observe_corrected_hidden_drop(calculation_day, target_day, 1)
}

pub fn observe_corrected_hidden_drop(
    calculation_day: BigInt,
    target_day: BigInt,
    requested_k: usize,
) -> Result<Patch05RouteObservation, MonsterError> {
    if !(1..=7).contains(&requested_k) {
        return Err(invalid("logical index must be 1..=7"));
    }
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager
        .dispatcher_mut()
        .register(LegacyTagDistanceDiscovery03);
    manager.dispatcher_mut().register(Patch03DistanceCorrection);
    manager.dispatcher_mut().register(LegacyStoneDiscovery04);
    manager.dispatcher_mut().register(StonePatch04);
    manager
        .dispatcher_mut()
        .register(LegacyHiddenDropDiscovery05 { requested_k });
    manager
        .dispatcher_mut()
        .register(HiddenDropPatch05 { requested_k });
    let context = manager.execute_bootstrap_shell(calculation_day, target_day)?;
    let backward_storage = context
        .discovery05_backward_storage
        .clone()
        .ok_or_else(|| invalid("missing backward storage"))?;
    let corrected = context
        .patch05_hidden_observation
        .clone()
        .ok_or_else(|| invalid("missing corrected observation"))?;
    Ok(Patch05RouteObservation {
        backward_storage,
        corrected,
        context,
    })
}
