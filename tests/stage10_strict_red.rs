mod support;

use num_bigint::BigInt;

use pastafarian_calendar_rust_az::discovery05_hidden_probe::calendar_hidden_spaghetti;
use support::stage10_oracle::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
#[ignore = "intentional strict GREEN assertion; Stage10 workflow runs it separately to confirm expected RED"]
fn stage10_strict_red_k1_must_not_match() {
    let foundation = BigInt::from(FOUNDATION);
    let observed = calendar_hidden_spaghetti(foundation.clone(), foundation.clone()).unwrap();
    let expected = independent_hidden_values(
        &foundation,
        &foundation,
        &independent_stones(),
    )[1]
        .clone();

    // Deliberately wrong GREEN assertion: this test must fail because the
    // historical direct read returns hidden7 in logical slot 1.
    assert_eq!(observed.actual, expected, "strict RED witness must remain RED");
}
