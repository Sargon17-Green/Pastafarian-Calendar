//! Stage05/PATCH02 — test-only normative oracle remains outside production.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery01_legacy_save::observe_legacy_save;
use pastafarian_calendar_rust_az::discovery02_work_counts_probe::candidate_work_counts;
use pastafarian_calendar_rust_az::patch01_save::calculate_save;
use pastafarian_calendar_rust_az::patch02_work_counts::{
    calculate_work_counts, normative_day_tag, normative_work_counts, WorkCounts,
};
use pastafarian_calendar_rust_az::{
    calendar_date_spaghetti, MonsterErrorCode, MonsterPhase, MonsterStatus,
};
use support::normative_oracle as oracle;

fn assert_same(actual: &WorkCounts, expected: &oracle::WorkCounts) {
    assert_eq!(actual.action, expected.action);
    assert_eq!(actual.target, expected.target);
    assert_eq!(actual.distance, expected.distance);
    assert_eq!(actual.connection, expected.connection);
    assert_eq!(actual.direction, expected.direction);
}

#[test]
fn exact_foundation_cases_use_real_production_dispatcher() {
    let f = oracle::foundation_day();
    let expected = [6u8, 4, 2, 1, 3, 5, 7];
    for offset in -3i64..=3 {
        let day = &f + BigInt::from(offset);
        let observed = calculate_work_counts(day.clone(), day.clone()).unwrap();
        assert_eq!(normative_day_tag(&day), BigInt::from(expected[(offset + 3) as usize]));
        assert_same(&observed.counts, &oracle::work_counts(&day, &day));
        assert_eq!(observed.counts.distance, BigInt::one());
        assert_eq!(observed.counts.direction, 2);
        assert_eq!(observed.context.calculation_day, day);
        assert_eq!(observed.context.target_day, day);
        assert_eq!(observed.context.phase, MonsterPhase::Complete);
        assert_eq!(observed.context.status, MonsterStatus::Complete);
        assert_eq!(
            observed.context.work_counts_observation,
            Some(observed.counts.clone())
        );
        assert_eq!(observed.context.metrics.get("patch02.work_counts.calls"), 1);
        assert_eq!(observed.context.metrics.get("dispatcher.handler.completed"), 1);
        assert_eq!(observed.context.save_observation, None);
        assert_eq!(observed.context.legacy_save_observation, None);
        assert_eq!(
            observed.context.branch_trace,
            vec!["PATCH02:NORMATIVE-WORK-COUNTS"]
        );
    }
    println!("STAGE05_PATCH02_FOUNDATION_CASES=7");
}

#[test]
fn every_nearby_pair_matches_independent_oracle_and_swap_invariants() {
    let f = oracle::foundation_day();
    for a in -3i64..=3 {
        for b in -3i64..=3 {
            let calculation = &f + BigInt::from(a);
            let target = &f + BigInt::from(b);
            let observed = calculate_work_counts(calculation.clone(), target.clone()).unwrap();
            let repeated = calculate_work_counts(calculation.clone(), target.clone()).unwrap();
            assert_eq!(observed, repeated, "per-invocation isolation");
            assert_eq!(observed.calculation_day, calculation);
            assert_eq!(observed.target_day, target);
            assert_same(&observed.counts, &oracle::work_counts(&calculation, &target));
            let reversed = normative_work_counts(&target, &calculation);
            assert_eq!(observed.counts.action, reversed.target);
            assert_eq!(observed.counts.target, reversed.action);
            assert_eq!(observed.counts.connection, reversed.connection);
            assert_eq!(observed.counts.distance, reversed.distance);
            assert_eq!(observed.counts.direction + reversed.direction, 4);
            assert_eq!(observed.counts.distance, BigInt::from((b - a).abs() + 1));
        }
    }
    println!("STAGE05_PATCH02_LOCAL_PAIRS=49");
}

#[test]
fn huge_signed_pairs_compare_exactly_without_integer_narrowing() {
    let f = oracle::foundation_day();
    for bits in [1025usize, 2049, 4096, 8192] {
        let power = BigInt::one() << bits;
        for sign in [-1i8, 1i8] {
            let delta = &power * BigInt::from(sign);
            let calculation = &f + &delta;
            let target = &f - &delta;
            let result = calculate_work_counts(calculation.clone(), target.clone()).unwrap();
            assert_same(&result.counts, &oracle::work_counts(&calculation, &target));
            assert_eq!(result.counts.distance, (&delta * BigInt::from(2u8)).abs() + BigInt::one());
            assert_eq!(result.counts.direction, if sign > 0 { 1 } else { 3 });
            assert_eq!(result.counts.action, oracle::day_count(&calculation));
            assert_eq!(result.counts.target, oracle::day_count(&target));
            assert_eq!(result.context.calculation_day, calculation);
            assert_eq!(result.context.target_day, target);
        }
    }
    println!("STAGE05_PATCH02_LARGE_PAIRS=8");
}

#[test]
fn stage03_save_and_stage04_probe_remain_unchanged() {
    let m = oracle::m_bigint();
    let days = [m.clone(), &m * BigInt::from(2u8), -m.clone(), &m + BigInt::one()];
    for day in days {
        let before = calculate_save(day.clone()).unwrap();
        let legacy_before = observe_legacy_save(day.clone()).unwrap();
        let original_probe = candidate_work_counts(&day, &day);
        let candidate = calculate_work_counts(day.clone(), day.clone()).unwrap();
        let after = calculate_save(day.clone()).unwrap();
        let legacy_after = observe_legacy_save(day.clone()).unwrap();
        assert_eq!(before, after);
        assert_eq!(legacy_before, legacy_after);
        assert_eq!(before.save_value, oracle::save(day.clone()));
        assert_eq!(candidate.counts.action, original_probe.action);
        assert_eq!(candidate.counts.target, original_probe.target);
        assert_eq!(candidate.counts.connection, original_probe.connection);
        assert_eq!(candidate.counts.distance, original_probe.distance);
        assert_eq!(candidate.counts.direction, original_probe.direction);
        assert_eq!(candidate.context.save_observation, None);
        assert_eq!(candidate.context.legacy_save_observation, None);
    }
    println!("STAGE05_PATCH02_SAVE_ISOLATION=4");
}

#[test]
fn full_calendar_bootstrap_contract_is_not_prematurely_claimed() {
    let f = oracle::foundation_day();
    let err = calendar_date_spaghetti(f.clone(), f + BigInt::one())
        .expect_err("Stage05 delivers work counts, not five-field calendar date");
    assert_eq!(err.code, MonsterErrorCode::BootstrapOnly);
    println!("STAGE05_PATCH02_BOOTSTRAP_ONLY=PASS");
}
