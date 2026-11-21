//! Stage03-dən budaqlanan tarixi DAY-TAG səhvinin açıq yenidən qurulması.
//! Bu kod 2026-10-30 tarixindəki orijinal istehsal mənbəyi deyildir.
//! Səhv qəsdən saxlanılır: təməl gündən əvvəl +1 ofseti yanlışdır.
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};
use num_bigint::BigInt;
use num_traits::Signed;

pub struct LegacyDayTagHandler;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LegacyDayTagObservation {
    pub input: BigInt,
    pub legacy_tag: BigInt,
    pub context: MonsterContext,
}

/// Qəsdən səhv: hər iki istiqamət üçün 2*abs(day-foundation)+1.
/// Təməl gündən ƏVVƏL normativ cavabda sondakı +1 olmamalıdır.
pub fn legacy_day_tag(day: &BigInt) -> BigInt {
    let foundation = BigInt::from(-15_055_671i64);
    let distance = (day - foundation).abs();
    distance * BigInt::from(2u8) + BigInt::from(1u8)
}

impl PhaseHandler for LegacyDayTagHandler {
    fn name(&self) -> &'static str {
        "DISCOVERY02:LEGACY-DAY-TAG"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.legacy_day_tag_observation = Some(legacy_day_tag(&context.calculation_day));
        context.metrics.bump("discovery02.legacy_day_tag.calls");
        context.logs.push("DISCOVERY02: səhv tarixi gün etiketi müşahidə edildi.");
        Ok(())
    }
}

/// Yeni çağırış üçün müstəqil MonsterContext və real dispetçer.
pub fn observe_legacy_day_tag(input: BigInt) -> Result<LegacyDayTagObservation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(LegacyDayTagHandler);
    let context = manager.execute_bootstrap_shell(input.clone(), input.clone())?;
    let legacy_tag = context
        .legacy_day_tag_observation
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY02: gün etiketi müşahidəsi yoxdur.".to_owned(),
        })?;
    Ok(LegacyDayTagObservation {
        input,
        legacy_tag,
        context,
    })
}
