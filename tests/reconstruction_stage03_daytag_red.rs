//! Exact RED->GREEN correction on a distinct descendant of the genuine Stage03 root.
//! Independent test-only piecewise integer oracle; no other branch fixtures or code.
use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery02_legacy_day_tag::{
    legacy_day_tag, observe_legacy_day_tag,
};
use pastafarian_calendar_rust_az::{MonsterPhase, MonsterStatus};

fn independent_oracle(day: &BigInt) -> BigInt {
    let foundation = BigInt::from(-15_055_671i64);
    if day < &foundation {
        (&foundation - day) * BigInt::from(2u8)
    } else {
        (day - &foundation) * BigInt::from(2u8) + BigInt::one()
    }
}

#[test]
fn compiled_production_spaghetti_repairs_all_observed_numeric_red() {
    let foundation = BigInt::from(-15_055_671i64);
    let huge = BigInt::one() << 256usize;
    let cases = [
        (&foundation - BigInt::from(2u8), true),
        (&foundation - BigInt::one(), true),
        (&foundation - &huge, true),
        (foundation.clone(), false),
        (&foundation + BigInt::one(), false),
        (&foundation + &huge, false),
    ];
    let mut prior_red_fixed = 0usize;
    let mut prior_controls_preserved = 0usize;
    for (input, was_red) in cases {
        let observed = observe_legacy_day_tag(input.clone())
            .expect("real MonsterManager dispatcher path");
        let independent = independent_oracle(&input);
        assert_eq!(observed.legacy_tag, independent, "case {}", input);
        assert_eq!(observed.legacy_tag, legacy_day_tag(&input));
        assert_eq!(observed.input, input);
        assert_eq!(
            observed.context.legacy_day_tag_observation,
            Some(observed.legacy_tag.clone())
        );
        assert_eq!(observed.context.legacy_save_observation, None);
        assert_eq!(observed.context.save_observation, None);
        assert_eq!(observed.context.metrics.get("discovery02.legacy_day_tag.calls"), 1);
        assert_eq!(observed.context.metrics.get("dispatcher.handler.completed"), 1);
        assert_eq!(observed.context.phase, MonsterPhase::Complete);
        assert_eq!(observed.context.status, MonsterStatus::Complete);
        assert_eq!(
            observed.context.branch_trace,
            vec!["DISCOVERY02:LEGACY-DAY-TAG"]
        );
        let second = observe_legacy_day_tag(input.clone())
            .expect("independent fresh invocation");
        assert_eq!(second, observed);
        println!(
            "RECONSTRUCTED_RUST_DAYTAG_GREEN_CASE={} ACTUAL={} ORACLE={} WAS_RED={}",
            input, observed.legacy_tag, independent, was_red
        );
        if was_red {
            prior_red_fixed += 1;
        } else {
            prior_controls_preserved += 1;
        }
    }
    assert_eq!((prior_red_fixed, prior_controls_preserved), (3, 3));
    println!("RECONSTRUCTED_RUST_DAYTAG_GREEN=6 PRIOR_RED_FIXED=3 PRIOR_CONTROL_PRESERVED=3 UNEXPECTED=0");
}

#[test]
fn deterministic_signed_bigint_dispatcher_differential_is_green() {
    let foundation = BigInt::from(-15_055_671i64);
    for i in 0usize..128 {
        // Bounded deterministic family; signs alternate and precision exceeds i64.
        let distance = (BigInt::from(i + 1) << (i % 120)) + BigInt::from(37usize * i + 3);
        let day = if i % 2 == 0 {
            &foundation - &distance
        } else {
            &foundation + &distance
        };
        let actual = observe_legacy_day_tag(day.clone())
            .expect("production dispatcher for signed BigInt");
        let independent = independent_oracle(&day);
        println!(
            "RECONSTRUCTED_RUST_DAYTAG_DIFF_CASE_INDEX={} DAY={} ACTUAL={} ORACLE={}",
            i, day, actual.legacy_tag, independent
        );
        assert_eq!(actual.legacy_tag, independent, "index {}", i);
        assert_eq!(actual.context.metrics.get("discovery02.legacy_day_tag.calls"), 1);
    }
    println!("RECONSTRUCTED_RUST_DAYTAG_DIFFERENTIAL=128 GREEN=128 UNEXPECTED=0");
}
