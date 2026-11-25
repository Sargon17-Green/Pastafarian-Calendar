#[path = "stage10_support/mod.rs"]
mod stage10_support;

use num_bigint::BigInt;

use pastafarian_calendar_rust_az::discovery05_hidden_probe::observe_legacy_hidden_drop;
use stage10_support::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
fn stage10_bigint_independent_five_pairs_and_patch04_rows() {
    let foundation = BigInt::from(FOUNDATION);
    let pairs = [
        (0i64, 0i64),
        (-10, 11),
        (34, -19),
        (-90_001, -90_001),
        (123_456_789, -987_654_321),
    ];
    let stones = independent_stones();
    let mut hidden_checked = 0usize;
    let mut stone_checked = 0usize;

    for (case, (calculation_offset, target_offset)) in pairs.into_iter().enumerate() {
        let calculation = &foundation + BigInt::from(calculation_offset);
        let target = &foundation + BigInt::from(target_offset);
        let expected = independent_hidden_values(&calculation, &target, &stones);
        let observed = observe_legacy_hidden_drop(calculation, target, 1).unwrap();
        for k in 1..=7 {
            assert_eq!(observed.backward_storage[8 - k], expected[k]);
            hidden_checked += 1;
        }
        let rows = observed.context.discovery05_stone_rows.as_ref().unwrap();
        for row in 0..7 {
            for kind in 0..5 {
                assert_eq!(rows[row][kind], stones[row][kind]);
                stone_checked += 1;
            }
        }
        println!("STAGE10_BIGINT_CASE={} HIDDEN=7 STONES=35", case);
    }

    assert_eq!(hidden_checked, 35);
    assert_eq!(stone_checked, 175);
    println!("STAGE10_BIGINT_INDEPENDENT_PASS_35");
    println!("STAGE10_BIGINT_PATCH04_STONES_GREEN_175");
}
