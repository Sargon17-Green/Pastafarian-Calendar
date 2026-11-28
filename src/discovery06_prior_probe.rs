//! Stage12 / DISCOVERY06: preserve the visible-only predecessor assumption.
use num_bigint::BigInt;

use crate::discovery04_stone_probe::LegacyStoneDiscovery04;
use crate::discovery05_hidden_probe::LegacyHiddenDropDiscovery05;
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::patch04_stone_probe::StonePatch04;
use crate::patch05_hidden_probe::HiddenDropPatch05;
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PriorOutcome {
    Visible(BigInt),
    MissingVisibleSlot,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PriorObservation {
    pub i: usize,
    pub back: usize,
    pub slot: i32,
    pub outcome: PriorOutcome,
}

fn invalid(message: &str) -> MonsterError {
    MonsterError {
        code: MonsterErrorCode::InvalidState,
        message: format!("DISCOVERY06: {message}"),
    }
}

/// The supplied prefix represents previously completed visible drops only.
pub fn legacy_prior(
    visible_prefix: &[BigInt],
    i: usize,
    back: usize,
) -> Result<PriorObservation, MonsterError> {
    if !(1..=46).contains(&i) || ![1, 3, 7].contains(&back) {
        return Err(invalid("invalid drop number or lookback"));
    }
    if visible_prefix.len() != i - 1 {
        return Err(invalid("inconsistent visible prefix length"));
    }
    let zero = BigInt::from(0u8);
    let modulus = (BigInt::from(1u8) << 127usize) - BigInt::from(1u8);
    if visible_prefix
        .iter()
        .any(|value| value <= &zero || value > &modulus)
    {
        return Err(invalid("visible prefix value outside SAVE range"));
    }
    let slot = i as i32 - back as i32;
    let outcome = if slot <= 0 {
        PriorOutcome::MissingVisibleSlot
    } else {
        PriorOutcome::Visible(visible_prefix[(slot - 1) as usize].clone())
    };
    Ok(PriorObservation {
        i,
        back,
        slot,
        outcome,
    })
}

pub struct LegacyPriorDiscovery06 {
    pub visible_prefix: Vec<BigInt>,
    pub i: usize,
    pub back: usize,
}

impl PhaseHandler for LegacyPriorDiscovery06 {
    fn name(&self) -> &'static str {
        "DISCOVERY06:VISIBLE-ONLY-PRIOR"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.discovery06_prior_observation.is_some()
            || context.metrics.get("discovery06.prior.calls") != 0
        {
            return Err(invalid("duplicate application"));
        }
        if context.patch05_hidden_observation.is_none()
            || context.metrics.get("patch05.applied") != 1
        {
            return Err(invalid("missing PATCH05 prerequisite"));
        }
        let observed = legacy_prior(&self.visible_prefix, self.i, self.back)?;
        context.logs.push(format!(
            "DISCOVERY06: i={} back={} slot={}",
            observed.i, observed.back, observed.slot
        ));
        context.discovery06_prior_observation = Some(observed);
        context.metrics.bump("discovery06.prior.calls");
        Ok(())
    }
}

/// Discovery subroute, not the full calendar or visible-drop generator.
pub fn observe_legacy_prior(
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
        visible_prefix,
        i,
        back,
    });
    manager.execute_bootstrap_shell(calculation_day, target_day)
}
