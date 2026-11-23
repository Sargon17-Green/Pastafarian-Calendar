//! Stage06/DISCOVERY03 — ayrıca daş ardıcıllığı; oracle yalnız test qatındadır.
#[rustfmt::skip]
mod support;

use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery03_stone_probe::candidate_stones;
use pastafarian_calendar_rust_az::patch01_save::normative_save;
use pastafarian_calendar_rust_az::{
    calendar_date_spaghetti, MonsterErrorCode,
};
use support::normative_oracle as oracle;

#[test]
fn every_stone_matches_independent_test_only_oracle() {
    let observed = candidate_stones();
    let expected = oracle::build_stones();
    assert_eq!(observed.len(), 46);
    assert_eq!(observed, expected);
    println!("STAGE06_DISCOVERY03_ROWS=46 CELLS=230");
}

#[test]
fn seed_second_row_range_and_determinism_are_exact() {
    let rows = candidate_stones();
    assert_eq!(rows[0], [17, 29, 43, 71, 101].map(BigInt::from));
    // Bu beş ədədi ilkin ədədlərdən birbaşa müstəqil hesablamışıq.
    assert_eq!(rows[1], [378, 1073, 2375, 6195, 10493].map(BigInt::from));
    let m = (BigInt::one() << 127usize) - BigInt::one();
    for row in &rows {
        for value in row {
            assert!(value >= &BigInt::one() && value <= &m);
        }
    }
    assert_eq!(rows, candidate_stones());
    println!("STAGE06_DISCOVERY03_BOUNDS=230 DETERMINISM=PASS");
}

#[test]
fn earlier_patch_and_calendar_boundary_remain_unmodified() {
    let m = (BigInt::one() << 127usize) - BigInt::one();
    assert_eq!(normative_save(&m), m);
    assert_eq!(normative_save(&(BigInt::one() - &m)), BigInt::one());
    let err = calendar_date_spaghetti(BigInt::from(-15_055_671), BigInt::from(0))
        .expect_err("DISCOVERY03 does not activate the five-field output");
    assert_eq!(err.code, MonsterErrorCode::BootstrapOnly);
    println!("STAGE06_DISCOVERY03_BOOTSTRAP_ONLY=PASS");
}
