//! Mərhələ 5 — PATCH02: iki gün üçün normativ iş sayları.
//! Təsdiqlənmiş 2026 Rust rekonstruksiyasının izini saxlayır; test oracle-ı yoxdur.
//! Beş sahəli yekun təqvim marşrutu hələ qəsdən bağlıdır.

use std::cmp::Ordering;

use num_bigint::BigInt;
use num_traits::{One, Signed};

use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

/// İki günü ayıran normativ göstəricilər, tam və işarəli BigInt ilə.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WorkCounts {
    pub action: BigInt,
    pub target: BigInt,
    pub distance: BigInt,
    pub connection: BigInt,
    pub direction: u8,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch02Observation {
    pub calculation_day: BigInt,
    pub target_day: BigInt,
    pub counts: WorkCounts,
    pub context: MonsterContext,
}

pub struct WorkCountsPatch02;

/// 2026-cı ildə təsdiqlənmiş Rust rekonstruksiyasının dəyişməz riyazi izi.
/// Bu, orijinal tarixi mənbə deyil; F-dən əvvəl +1 qəsdən yanlışdır.
pub fn reconstructed_legacy_day_tag(day: &BigInt) -> BigInt {
    let foundation = BigInt::from(-15_055_671i64);
    (day - foundation).abs() * BigInt::from(2u8) + BigInt::one()
}

/// Legacy nəticəsini bir dəfə al, yalnız F-dən əvvəl ofseti geri götür.
fn patch02_day_tag_observed(day: &BigInt) -> (BigInt, BigInt) {
    let legacy = reconstructed_legacy_day_tag(day);
    let corrected = if day < &BigInt::from(-15_055_671i64) {
        &legacy - BigInt::one()
    } else {
        legacy.clone()
    };
    (legacy, corrected)
}

pub fn normative_day_tag(day: &BigInt) -> BigInt {
    patch02_day_tag_observed(day).1
}

/// Məsafə bu əvvəlki normativ QA marşrutunda dəyişmir.
pub fn normative_work_counts(calculation_day: &BigInt, target_day: &BigInt) -> WorkCounts {
    observed_work_counts(calculation_day, target_day).0
}

fn observed_work_counts(
    calculation_day: &BigInt,
    target_day: &BigInt,
) -> (WorkCounts, BigInt, BigInt) {
    let (legacy_action, action) = patch02_day_tag_observed(calculation_day);
    let (legacy_target, target) = patch02_day_tag_observed(target_day);
    let distance = (target_day - calculation_day).abs() + BigInt::one();
    let connection = &action + &target;
    let direction = match target_day.cmp(calculation_day) {
        Ordering::Less => 1,
        Ordering::Equal => 2,
        Ordering::Greater => 3,
    };
    (
        WorkCounts {
            action,
            target,
            distance,
            connection,
            direction,
        },
        legacy_action,
        legacy_target,
    )
}

impl PhaseHandler for WorkCountsPatch02 {
    fn name(&self) -> &'static str {
        "PATCH02:NORMATIVE-WORK-COUNTS"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.work_counts_observation.is_some() {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH02: təkrar müşahidə qadağandır.".to_owned(),
            });
        }
        let (counts, legacy_action, legacy_target) =
            observed_work_counts(&context.calculation_day, &context.target_day);
        context.logs.push(format!(
            "PATCH02:legacy-action={} corrected-action={}",
            legacy_action, counts.action
        ));
        context.logs.push(format!(
            "PATCH02:legacy-target={} corrected-target={}",
            legacy_target, counts.target
        ));
        context.metrics.bump("patch02.legacy.action.calls");
        context.metrics.bump("patch02.legacy.target.calls");
        context.work_counts_observation = Some(counts);
        context.metrics.bump("patch02.work_counts.calls");
        context
            .logs
            .push("PATCH02: normativ iki-gün iş sayları hesablandı.");
        Ok(())
    }
}

/// Müstəqil çağırış konteksti ilə istehsal dispetçeri; oracle istifadə olunmur.
pub fn calculate_work_counts(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch02Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    let context = manager.execute_bootstrap_shell(calculation_day.clone(), target_day.clone())?;
    let counts = context
        .work_counts_observation
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "PATCH02: iş sayları müşahidəsi yoxdur.".to_owned(),
        })?;
    Ok(Patch02Observation {
        calculation_day,
        target_day,
        counts,
        context,
    })
}

#[cfg(test)]
mod wrapper_reconciliation_tests {
    use super::*;

    #[test]
    fn reconstructed_wrapper_uses_legacy_and_preserves_call_ownership() {
        let foundation = BigInt::from(-15_055_671i64);
        let mut offsets: Vec<BigInt> = (-31i64..=31).map(BigInt::from).collect();
        for bits in [129usize, 1031, 4097] {
            let wide = BigInt::one() << bits;
            offsets.push(-&wide);
            offsets.push(wide);
        }
        let mut before = 0;
        let mut controls = 0;
        for offset in &offsets {
            let day = &foundation + offset;
            let expected = if offset < &BigInt::from(0u8) {
                -offset - offset
            } else {
                offset + offset + BigInt::one()
            };
            let other = &foundation - offset;
            let obs = calculate_work_counts(day.clone(), other).unwrap();
            let raw = reconstructed_legacy_day_tag(&day);
            if offset < &BigInt::from(0u8) {
                assert_eq!(raw, &expected + BigInt::one());
                before += 1;
            } else {
                assert_eq!(raw, expected);
                controls += 1;
            }
            assert_eq!(obs.counts.action, expected);
            assert_eq!(obs.context.metrics.get("patch02.legacy.action.calls"), 1);
            assert_eq!(obs.context.metrics.get("patch02.legacy.target.calls"), 1);
            assert!(obs.context.logs.entries().contains(&format!(
                "PATCH02:legacy-action={} corrected-action={}",
                raw, expected
            )));
            let mut duplicate = obs.context.clone();
            let snapshot = duplicate.clone();
            let error = WorkCountsPatch02.handle(&mut duplicate).unwrap_err();
            assert_eq!(error.code, MonsterErrorCode::InvalidState);
            assert_eq!(duplicate, snapshot);
            println!("PATCH02_WRAPPER_ROW day={day} raw={raw} corrected={expected}");
        }
        assert_eq!((before, controls), (34, 35));
        println!("STAGE05_WRAPPER_RECONCILIATION=69 RED_SCAR=34 CONTROL=35 GUARDS=69");
    }
}


/// DISCOVERY03: yalnız bu çağırışda PATCH02 etiketlərinin köhnə məsafəsi.
/// Normativ PATCH02 marşrutu ayrıca qalır; PATCH03 burada tətbiq edilmir.
pub struct LegacyTagDistanceDiscovery03;

impl PhaseHandler for LegacyTagDistanceDiscovery03 {
    fn name(&self) -> &'static str {
        "DISCOVERY03:LEGACY-TAG-DISTANCE"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.metrics.get("discovery03.distance.calls") != 0 {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY03: təkrar çağırış qadağandır.".to_owned(),
            });
        }
        let counts = context
            .work_counts_observation
            .as_mut()
            .ok_or_else(|| MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY03: PATCH02 müşahidəsi yoxdur.".to_owned(),
            })?;
        counts.distance = (&counts.action - &counts.target).abs();
        context.logs.push(format!(
            "DISCOVERY03:legacy-tag-distance={}",
            counts.distance
        ));
        context.metrics.bump("discovery03.distance.calls");
        Ok(())
    }
}

/// İki signed BigInt giriş; həqiqi dispatcher PATCH02 və DISCOVERY03 zənciri.
pub fn discover_legacy_tag_distance(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch02Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager.dispatcher_mut().register(LegacyTagDistanceDiscovery03);
    let context = manager.execute_bootstrap_shell(calculation_day.clone(), target_day.clone())?;
    let counts = context
        .work_counts_observation
        .clone()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY03: nəticə yoxdur.".to_owned(),
        })?;
    Ok(Patch02Observation {
        calculation_day,
        target_day,
        counts,
        context,
    })
}

#[cfg(test)]
mod distance_discovery03_tests {
    use super::*;

    #[test]
    fn discovery03_exact_expected_red_and_controls() {
        let f = BigInt::from(-15_055_671i64);
        let mut offsets: Vec<BigInt> = [-8i64, -3, -2, -1, 0, 1, 2, 3, 8]
            .into_iter()
            .map(BigInt::from)
            .collect();
        for bits in [129usize, 1031] {
            let n = BigInt::one() << bits;
            offsets.push(-&n);
            offsets.push(n);
        }
        let mut red = 0;
        let mut control = 0;
        let zero = BigInt::from(0u8);
        let two = BigInt::from(2u8);
        for c in &offsets {
            for t in &offsets {
                // Müstəqil oracle: eyni tərəfdə ikiqat xronoloji fərq;
                // müxtəlif tərəflərdə signed offset cəminin tək kodu.
                let chronological = (t - c).abs();
                let expected = if (c < &zero) == (t < &zero) {
                    &chronological * &two
                } else {
                    ((c + t) * &two + BigInt::one()).abs()
                };
                let normative = &chronological + BigInt::one();
                let observed = discover_legacy_tag_distance(&f + c, &f + t).unwrap();
                assert_eq!(observed.counts.distance, expected);
                assert_eq!(
                    observed.context.metrics.get("patch02.work_counts.calls"),
                    1
                );
                assert_eq!(
                    observed.context.metrics.get("patch02.legacy.action.calls"),
                    1
                );
                assert_eq!(
                    observed.context.metrics.get("patch02.legacy.target.calls"),
                    1
                );
                assert_eq!(observed.context.metrics.get("discovery03.distance.calls"), 1);
                assert_eq!(
                    observed.context.branch_trace,
                    vec![
                        "PATCH02:NORMATIVE-WORK-COUNTS".to_owned(),
                        "DISCOVERY03:LEGACY-TAG-DISTANCE".to_owned(),
                    ]
                );
                let unchanged = calculate_work_counts(&f + c, &f + t).unwrap();
                assert_eq!(unchanged.counts.distance, normative);
                assert_eq!(observed.counts.action, unchanged.counts.action);
                assert_eq!(observed.counts.target, unchanged.counts.target);
                assert_eq!(observed.counts.connection, unchanged.counts.connection);
                assert_eq!(observed.counts.direction, unchanged.counts.direction);
                let mut duplicate = observed.context.clone();
                let snapshot = duplicate.clone();
                let error = LegacyTagDistanceDiscovery03
                    .handle(&mut duplicate)
                    .unwrap_err();
                assert_eq!(error.code, MonsterErrorCode::InvalidState);
                assert_eq!(duplicate, snapshot);
                let expected_red = expected != normative;
                assert_eq!(observed.counts.distance != normative, expected_red);
                if expected_red {
                    red += 1;
                } else {
                    control += 1;
                }
                println!(
                    "DISCOVERY03_DISTANCE_ROW c={c} t={t} legacy={} normative={normative} red={expected_red}",
                    observed.counts.distance
                );
            }
        }
        let mut missing = MonsterContext::new(f.clone(), f);
        let snapshot = missing.clone();
        let error = LegacyTagDistanceDiscovery03.handle(&mut missing).unwrap_err();
        assert_eq!(error.code, MonsterErrorCode::InvalidState);
        assert_eq!(missing, snapshot);
        assert_eq!((red, control), (153, 16));
        println!("STAGE06_DISTANCE_EXPECTED_RED=153 CONTROL=16 UNEXPECTED=0 GUARDS=170");
    }
}
