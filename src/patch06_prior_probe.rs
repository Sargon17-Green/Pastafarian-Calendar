//! Stage13 / PATCH06: resolve nonpositive predecessor slots through hidden storage.
use num_bigint::BigInt;

use crate::discovery04_stone_probe::LegacyStoneDiscovery04;
use crate::discovery05_hidden_probe::LegacyHiddenDropDiscovery05;
use crate::discovery06_prior_probe::{
    legacy_prior, LegacyPriorDiscovery06, PriorObservation, PriorOutcome,
};
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::patch04_stone_probe::StonePatch04;
use crate::patch05_hidden_probe::{corrected_hidden_by_nearness, HiddenDropPatch05};
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

fn invalid(message: &str) -> MonsterError {
    MonsterError {
        code: MonsterErrorCode::InvalidState,
        message: format!("PATCH06: {message}"),
    }
}

pub fn corrected_prior(
    visible_prefix: &[BigInt],
    backward: &[BigInt],
    i: usize,
    back: usize,
) -> Result<PriorObservation, MonsterError> {
    let mut observed = legacy_prior(visible_prefix, i, back)?;
    let zero = BigInt::from(0u8);
    let modulus = (BigInt::from(1u8) << 127usize) - BigInt::from(1u8);
    if backward.len() != 8
        || backward[0] != zero
        || backward[1..]
            .iter()
            .any(|value| value <= &zero || value > &modulus)
    {
        return Err(invalid("invalid hidden storage"));
    }
    if observed.slot <= 0 {
        let k = (1 - observed.slot) as usize;
        observed.outcome = PriorOutcome::Visible(corrected_hidden_by_nearness(backward, k)?.actual);
    }
    Ok(observed)
}

pub struct PriorPatch06 {
    pub visible_prefix: Vec<BigInt>,
    pub i: usize,
    pub back: usize,
}

impl PhaseHandler for PriorPatch06 {
    fn name(&self) -> &'static str {
        "PATCH06:HIDDEN-OR-VISIBLE-PRIOR"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.patch06_prior_observation.is_some() || context.metrics.get("patch06.applied") != 0
        {
            return Err(invalid("duplicate application"));
        }
        if context.metrics.get("discovery06.prior.calls") != 1
            || context.metrics.get("patch05.applied") != 1
            || context.metrics.get("patch05.corrected.read") != 1
        {
            return Err(invalid("missing predecessor"));
        }
        let legacy = legacy_prior(&self.visible_prefix, self.i, self.back)?;
        if context.discovery06_prior_observation.as_ref() != Some(&legacy) {
            return Err(invalid("inconsistent legacy observation"));
        }
        let storage = context
            .discovery05_backward_storage
            .as_ref()
            .ok_or_else(|| invalid("missing hidden storage"))?;
        let patch05 = corrected_hidden_by_nearness(storage, 1)?;
        if context.patch05_hidden_observation.as_ref() != Some(&patch05) {
            return Err(invalid("inconsistent PATCH05 observation"));
        }
        let corrected = corrected_prior(&self.visible_prefix, storage, self.i, self.back)?;
        context.logs.push(format!(
            "PATCH06: i={} back={} slot={}",
            corrected.i, corrected.back, corrected.slot
        ));
        context.patch06_prior_observation = Some(corrected);
        context.metrics.bump("patch06.applied");
        Ok(())
    }
}

/// Bounded successor subroute; not the full visible-drop generator.
pub fn observe_corrected_prior(
    calculation_day: BigInt,
    target_day: BigInt,
    visible_prefix: Vec<BigInt>,
    i: usize,
    back: usize,
) -> Result<MonsterContext, MonsterError> {
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
        .register(LegacyHiddenDropDiscovery05 { requested_k: 1 });
    manager
        .dispatcher_mut()
        .register(HiddenDropPatch05 { requested_k: 1 });
    manager.dispatcher_mut().register(LegacyPriorDiscovery06 {
        visible_prefix: visible_prefix.clone(),
        i,
        back,
    });
    manager.dispatcher_mut().register(PriorPatch06 {
        visible_prefix,
        i,
        back,
    });
    manager.execute_bootstrap_shell(calculation_day, target_day)
}
