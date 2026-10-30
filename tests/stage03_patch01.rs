//! Mərhələ 3 — PATCH01: müstəqil test oracle-ı istehsala daxil edilmir.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery01_legacy_save::observe_legacy_save;
use pastafarian_calendar_rust_az::patch01_save::{calculate_save, normative_save};
use pastafarian_calendar_rust_az::{MonsterErrorCode, MonsterPhase, MonsterStatus};
use support::normative_oracle as oracle;

#[test]
fn exact_save_boundaries_through_production_dispatcher() {
    let m = oracle::m_bigint();
    let cases = [
        (BigInt::from(0u8), m.clone()),
        (m.clone(), m.clone()),
        (&m * BigInt::from(2u8), m.clone()),
        (&m * BigInt::from(3u8), m.clone()),
        (&m + BigInt::one(), BigInt::one()),
        (-m.clone(), m.clone()),
        (BigInt::from(-1i8), &m - BigInt::one()),
        (BigInt::one(), BigInt::one()),
    ];
    for (input, expected) in cases {
        let observed = calculate_save(input.clone()).expect("real production dispatcher");
        assert_eq!(observed.input, input);
        assert_eq!(observed.save_value, expected);
        assert_eq!(observed.save_value, oracle::save(input.clone()));
        assert_eq!(normative_save(&input), expected);
        assert_eq!(observed.context.calculation_day, input);
        assert_eq!(observed.context.target_day, input);
        assert_eq!(observed.context.save_observation, Some(expected));
        assert_eq!(observed.context.legacy_save_observation, None);
        assert_eq!(observed.context.metrics.get("patch01.save.calls"), 1);
        assert_eq!(observed.context.metrics.get("dispatcher.handler.completed"), 1);
        assert_eq!(observed.context.phase, MonsterPhase::Complete);
        assert_eq!(observed.context.status, MonsterStatus::Complete);
        assert_eq!(observed.context.branch_trace, vec!["PATCH01:NORMATIVE-SAVE"]);
    }
    println!("STAGE03_PATCH01_BOUNDARY_OK=8");
}

#[test]
fn huge_positive_and_negative_bigints_preserve_floor_modulo_and_periodicity() {
    let m = oracle::m_bigint();
    let huge = (&m << 320usize) + BigInt::from(81u8);
    let samples = [
        huge.clone(),
        -huge,
        (&m << 640usize) - BigInt::from(17u8),
        -((&m << 640usize) + BigInt::from(17u8)),
    ];
    for input in samples {
        let actual = calculate_save(input.clone()).expect("large signed input");
        let expected = oracle::save(input.clone());
        assert_eq!(actual.save_value, expected);
        assert_eq!(normative_save(&(input.clone() + &m)), expected);
        assert_eq!(normative_save(&(input - &m)), expected);
        assert!(actual.save_value >= BigInt::one());
        assert!(actual.save_value <= m);
    }
}

#[test]
fn legacy_red_signature_remains_untouched_and_invocations_are_isolated() {
    let m = oracle::m_bigint();
    let cases = [
        (m.clone(), true),
        (&m * BigInt::from(2u8), true),
        (&m * BigInt::from(3u8), true),
        (&m + BigInt::one(), false),
    ];
    let mut red = 0usize;
    let mut control = 0usize;
    for (input, historical_red) in cases {
        let legacy = observe_legacy_save(input.clone()).expect("legacy route");
        let patched = calculate_save(input.clone()).expect("patch route");
        let repeated = calculate_save(input.clone()).expect("new independent context");
        assert_eq!(legacy.legacy_value != patched.save_value, historical_red);
        assert_eq!(patched.context, repeated.context);
        assert_eq!(legacy.context.save_observation, None);
        assert_eq!(patched.context.legacy_save_observation, None);
        if historical_red {
            red += 1;
        } else {
            control += 1;
        }
    }
    assert_eq!((red, control), (3, 1));
    println!("STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0");
}

#[test]
fn five_calendar_fields_remain_unimplemented_at_stage_three() {
    let err = pastafarian_calendar_rust_az::calendar_date_spaghetti(
        BigInt::from(-15055671i64),
        BigInt::from(-15055670i64),
    )
    .expect_err("PATCH01 fixes SAVE only; five calendar components are not ready");
    assert_eq!(err.code, MonsterErrorCode::BootstrapOnly);
}
