//! Mərhələ 4 — DISCOVERY02 yalnız müsbət baza yoxlamasıdır.
//! Həqiqi tarixi uyğunsuzluq müşahidə olunana qədər EXPECTED_RED yoxdur.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_integer::Integer;
use num_traits::{One, Zero};
use pastafarian_calendar_rust_az::discovery01_legacy_save::observe_legacy_save;
use pastafarian_calendar_rust_az::discovery02_day_tag_probe::candidate_day_tag;
use pastafarian_calendar_rust_az::patch01_save::calculate_save;
use pastafarian_calendar_rust_az::MonsterErrorCode;
use support::normative_oracle as oracle;

#[test]
fn seven_foundation_neighborhood_cases_match_independent_oracle() {
    let f = oracle::foundation_day();
    let cases = [
        (-3i64, 6u64),
        (-2, 4),
        (-1, 2),
        (0, 1),
        (1, 3),
        (2, 5),
        (3, 7),
    ];
    for (offset, expected) in cases {
        let day = &f + BigInt::from(offset);
        let original = day.clone();
        let actual = candidate_day_tag(&day);
        assert_eq!(actual, BigInt::from(expected));
        assert_eq!(actual, oracle::day_count(&day));
        assert_eq!(day, original, "input must not change");
    }
    println!("STAGE04_DISCOVERY02_BASELINE_CASES=7");
}

#[test]
fn huge_signed_bigint_inputs_preserve_parity_and_inverse() {
    let f = oracle::foundation_day();
    let huge = BigInt::one() << 1025usize;
    let offsets = [
        huge.clone(),
        -huge.clone(),
        &huge + BigInt::one(),
        -(&huge + BigInt::one()),
    ];
    for offset in offsets {
        let day = &f + &offset;
        let tag = candidate_day_tag(&day);
        assert_eq!(tag, oracle::day_count(&day));
        assert!(tag > BigInt::zero());
        let recovered = if &tag % BigInt::from(2u8) == BigInt::one() {
            &f + ((&tag - BigInt::one()) / BigInt::from(2u8))
        } else {
            &f - (&tag / BigInt::from(2u8))
        };
        assert_eq!(recovered, day, "exact reverse map for >1024-bit input");
    }
    println!("STAGE04_DISCOVERY02_HUGE_CASES=4");
}

#[test]
fn discovery_probe_does_not_modify_save_or_claim_full_calendar() {
    let m = oracle::m_bigint();
    let inputs = [BigInt::zero(), m.clone(), &m + BigInt::one(), -m];
    for input in inputs {
        let before = calculate_save(input.clone()).expect("production SAVE");
        let legacy = observe_legacy_save(input.clone()).expect("historical SAVE");
        let _probe = candidate_day_tag(&input);
        let after = calculate_save(input.clone()).expect("production SAVE again");
        assert_eq!(before, after);
        assert_eq!(before.save_value, oracle::save(input.clone()));
        assert_eq!(legacy.legacy_value, input.mod_floor(&oracle::m_bigint()));
    }
    let err = pastafarian_calendar_rust_az::calendar_date_spaghetti(
        oracle::foundation_day(),
        oracle::foundation_day(),
    )
    .expect_err("five date fields are not yet implemented");
    assert_eq!(err.code, MonsterErrorCode::BootstrapOnly);
}
