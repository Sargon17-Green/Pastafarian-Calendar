//! Mərhələ 2 — 3 tarixi EXPECTED_RED, 1 CONTROL; düzəliş Stage3-dədir.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery01_legacy_save::{
    legacy_remainder, observe_legacy_save,
};
use pastafarian_calendar_rust_az::{MonsterPhase, MonsterStatus};
use support::normative_oracle as oracle;

#[test]
fn exact_historical_red_signature_through_real_dispatcher() {
    let m = oracle::m_bigint();
    let cases = [
        (m.clone(), true),
        (&m * BigInt::from(2u8), true),
        (&m * BigInt::from(3u8), true),
        (&m + BigInt::one(), false),
    ];
    let mut red = 0usize;
    let mut match_count = 0usize;
    for (input, expected_red) in cases {
        let first = observe_legacy_save(input.clone()).expect("real dispatcher");
        let second = observe_legacy_save(input.clone()).expect("independent invocation");
        let wanted = oracle::save(input.clone());
        let actual_red = first.legacy_value != wanted;
        assert_eq!(actual_red, expected_red, "exact historical witness");
        assert_eq!(first.input, input);
        assert_eq!(second.legacy_value, first.legacy_value);
        assert_eq!(first.context.calculation_day, input);
        assert_eq!(first.context.target_day, input);
        assert_eq!(
            first.context.metrics.get("discovery01.legacy_save.calls"),
            1
        );
        assert_eq!(first.context.metrics.get("dispatcher.handler.completed"), 1);
        assert_eq!(first.context.phase, MonsterPhase::Complete);
        assert_eq!(first.context.status, MonsterStatus::Complete);
        assert_eq!(first.context.branch_trace, vec!["DISCOVERY01:LEGACY-SAVE"]);
        assert_eq!(
            first.context.legacy_save_observation,
            Some(first.legacy_value.clone())
        );
        assert_eq!(
            first.context, second.context,
            "no state carried between calls"
        );
        if actual_red {
            red += 1;
        } else {
            match_count += 1;
        }
    }
    assert_eq!((red, match_count), (3, 1));
    println!("STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0");
}

#[test]
fn signed_and_large_inputs_preserve_exact_euclidean_legacy_behavior() {
    let m = oracle::m_bigint();
    let values = [
        BigInt::from(0u8),
        -m.clone(),
        BigInt::from(-1i8),
        BigInt::one(),
        &m - BigInt::one(),
        (&m << 160usize) + BigInt::from(81u8),
        -((&m << 160usize) + BigInt::from(81u8)),
    ];
    for x in values {
        let result = observe_legacy_save(x.clone()).expect("large signed input");
        assert_eq!(result.legacy_value, legacy_remainder(&x));
        assert!(result.legacy_value >= BigInt::from(0u8));
        assert!(result.legacy_value < m);
        assert_eq!(result.input, x);
        assert_eq!(result.context.calculation_day, x);
        assert_eq!(result.context.target_day, x);
    }
    // Not every negative input is RED: the only failure condition is x mod M = 0.
    assert_eq!(legacy_remainder(&BigInt::from(-1i8)), &m - BigInt::one());
    assert_eq!(oracle::save(BigInt::from(-1i8)), &m - BigInt::one());
}

#[test]
fn canonical_five_fields_still_refuse_to_claim_full_calendar() {
    let error = pastafarian_calendar_rust_az::calendar_date_spaghetti(
        BigInt::from(-15055671i64),
        BigInt::from(-15055670i64),
    )
    .expect_err("Stage2 does not synthesize five fields");
    assert_eq!(
        error.code,
        pastafarian_calendar_rust_az::MonsterErrorCode::BootstrapOnly
    );
}
