//! Stage03-dən ayrılan 2026-cı il Rust gün etiketi yenidənqurmasının düzəlişi.
//! Orijinal Stage03 mənbəyinin tarixi dəyişdirilməyib; səhv RED SHA-da saxlanılıb.
//! Köhnə API adı müqayisə və geriyə uyğunluq üçün qalır, hesab isə düzəldilib.
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};
use num_bigint::BigInt;
use num_traits::{One, Signed};

pub struct LegacyDayTagHandler;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LegacyDayTagObservation {
    pub input: BigInt,
    pub legacy_tag: BigInt,
    pub context: MonsterContext,
}

/// Düzəliş: gün F-dən əvvəldirsə 2*(F-gün), əks halda 2*(gün-F)+1.
/// Məhdudiyyətsiz işarəli BigInt ilə işləyir; köhnə ad RED tarixi ilə bağlıdır.
pub fn legacy_day_tag(day: &BigInt) -> BigInt {
    let delta = day - BigInt::from(-15_055_671i64);
    let doubled_distance = delta.abs() << 1usize;
    if delta.is_negative() {
        doubled_distance
    } else {
        doubled_distance + BigInt::one()
    }
}

impl PhaseHandler for LegacyDayTagHandler {
    fn name(&self) -> &'static str {
        "DISCOVERY02:LEGACY-DAY-TAG"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.legacy_day_tag_observation = Some(legacy_day_tag(&context.calculation_day));
        context.metrics.bump("discovery02.legacy_day_tag.calls");
        context.logs.push("DISCOVERY02: düzəldilmiş gün etiketi müşahidə edildi.");
        Ok(())
    }
}

/// Hər çağırış üçün müstəqil MonsterContext və həqiqi dispetçer.
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
