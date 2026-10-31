//! Mərhələ 4 / DISCOVERY02: iki günlük iş sayları; yalnız müsbət QA.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery02_work_counts_probe::candidate_work_counts;
use support::normative_oracle as oracle;

#[test]
fn local_cartesian_pairs_match_independent_oracle() {
    let foundation = oracle::foundation_day();
    let offsets = [-3i32, -2, -1, 0, 1, 2, 3];
    let mut cases = 0usize;
    for left in offsets {
        for right in offsets {
            let calculation_day = &foundation + BigInt::from(left);
            let target_day = &foundation + BigInt::from(right);
            let calculation_before = calculation_day.clone();
            let target_before = target_day.clone();
            let actual = candidate_work_counts(&calculation_day, &target_day);
            let expected = oracle::work_counts(&calculation_day, &target_day);
            assert_eq!(actual.action, expected.action);
            assert_eq!(actual.target, expected.target);
            assert_eq!(actual.distance, expected.distance);
            assert_eq!(actual.connection, expected.connection);
            assert_eq!(actual.direction, expected.direction);
            assert_eq!(actual.connection, &actual.action + &actual.target);
            assert_eq!(calculation_day, calculation_before);
            assert_eq!(target_day, target_before);
            if left == right {
                assert_eq!(actual.distance, BigInt::one());
                assert_eq!(actual.direction, 2);
            }
            cases += 1;
        }
    }
    assert_eq!(cases, 49);
    println!("STAGE04_DISCOVERY02_WORK_COUNTS_LOCAL_PAIRS=49");
}

#[test]
fn huge_signed_pairs_cover_exact_distance_and_direction() {
    let foundation = oracle::foundation_day();
    let mut cases = 0usize;
    for bits in [127usize, 1025, 4096, 8192] {
        let delta: BigInt = BigInt::one() << bits;
        let earlier = &foundation - &delta;
        let later = &foundation + &delta;
        for (calculation_day, target_day, direction) in [
            (&earlier, &later, 3u8),
            (&later, &earlier, 1u8),
        ] {
            let actual = candidate_work_counts(calculation_day, target_day);
            let expected = oracle::work_counts(calculation_day, target_day);
            assert_eq!(actual.action, expected.action);
            assert_eq!(actual.target, expected.target);
            assert_eq!(actual.distance, expected.distance);
            assert_eq!(actual.connection, expected.connection);
            assert_eq!(actual.direction, direction);
            assert_eq!(actual.distance, (&delta << 1usize) + BigInt::one());
            cases += 1;
        }
    }
    assert_eq!(cases, 8);
    println!("STAGE04_DISCOVERY02_WORK_COUNTS_HUGE_PAIRS=8");
}

#[test]
fn common_translation_preserves_distance_and_direction() {
    let foundation = oracle::foundation_day();
    let shifts = [
        BigInt::from(0u8),
        BigInt::one() << 127usize,
        -(BigInt::one() << 4096usize),
    ];
    let pairs = [(-7i32, 7i32), (7, -7), (0, 0), (3, 4)];
    let mut cases = 0usize;
    for shift in &shifts {
        for (left, right) in pairs {
            let a = &foundation + BigInt::from(left);
            let b = &foundation + BigInt::from(right);
            let translated_a = &a + shift;
            let translated_b = &b + shift;
            let original = candidate_work_counts(&a, &b);
            let translated = candidate_work_counts(&translated_a, &translated_b);
            let expected = oracle::work_counts(&translated_a, &translated_b);
            assert_eq!(translated.distance, original.distance);
            assert_eq!(translated.direction, original.direction);
            assert_eq!(translated.action, expected.action);
            assert_eq!(translated.target, expected.target);
            assert_eq!(translated.distance, expected.distance);
            assert_eq!(translated.connection, expected.connection);
            assert_eq!(translated.direction, expected.direction);
            assert_eq!(translated.connection, &translated.action + &translated.target);
            cases += 1;
        }
    }
    assert_eq!(cases, 12);
    println!("STAGE04_DISCOVERY02_WORK_COUNTS_TRANSLATION_CASES=12");
}
