//! Mərhələ 2 — DISCOVERY01: sıfır qalıq səhvi qəsdən qorunur.
//! Normativ SAVE burada çağırılmır: yalnız tarixi regularMod(x,M).
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};
use num_bigint::BigInt;
use num_integer::Integer;
use num_traits::One;

pub struct LegacySaveDiscovery01;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LegacySaveObservation {
    pub input: BigInt,
    pub legacy_value: BigInt,
    pub context: MonsterContext,
}

pub fn legacy_remainder(x: &BigInt) -> BigInt {
    let m = (BigInt::one() << 127usize) - BigInt::one();
    x.mod_floor(&m)
}

impl PhaseHandler for LegacySaveDiscovery01 {
    fn name(&self) -> &'static str {
        "DISCOVERY01:LEGACY-SAVE"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        // Caller-owned context: do not mutate either input, catalog, or global state.
        let old = legacy_remainder(&context.calculation_day);
        context.legacy_save_observation = Some(old);
        context.metrics.bump("discovery01.legacy_save.calls");
        context.logs.push("DISCOVERY01: köhnə SAVE qalığı qaytarıldı.");
        Ok(())
    }
}

pub fn observe_legacy_save(input: BigInt) -> Result<LegacySaveObservation, MonsterError> {
    // Real Stage1 manager/dispatcher route: no direct oracle or patched SAVE.
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(LegacySaveDiscovery01);
    let context = manager.execute_bootstrap_shell(input.clone(), input.clone())?;
    let legacy_value = context.legacy_save_observation.clone().ok_or_else(|| MonsterError {
        code: MonsterErrorCode::InvalidState,
        message: "DISCOVERY01: köhnə SAVE müşahidəsi yoxdur.".to_owned(),
    })?;
    Ok(LegacySaveObservation {
        input,
        legacy_value,
        context,
    })
}
