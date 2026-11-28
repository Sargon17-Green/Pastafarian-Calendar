#[path = "stage10_support/mod.rs"]
mod stage10_support;

use num_bigint::BigInt;
use pastafarian_calendar_rust_az::discovery06_prior_probe::{
    legacy_prior, observe_legacy_prior, LegacyPriorDiscovery06, PriorOutcome,
};
use pastafarian_calendar_rust_az::{MonsterContext, MonsterErrorCode, PhaseHandler};
use stage10_support::{independent_hidden_values, independent_stones, FOUNDATION};

#[test]
fn stage12_prior_domain_matrix() {
    let f = BigInt::from(FOUNDATION);
    let hidden = independent_hidden_values(&f, &f, &independent_stones());
    let mut red = 0;
    let mut control = 0;
    for i in 1..=46 {
        let prefix: Vec<BigInt> = (1..i).map(BigInt::from).collect();
        for back in [1, 3, 7] {
            let context =
                observe_legacy_prior(f.clone(), f.clone(), prefix.clone(), i, back).unwrap();
            let observed = context.discovery06_prior_observation.unwrap();
            assert_eq!(context.metrics.get("discovery06.prior.calls"), 1);
            assert_eq!(context.metrics.get("patch05.applied"), 1);
            assert_eq!(observed.slot, i as i32 - back as i32);
            if back >= i {
                let expected = &hidden[back + 1 - i];
                assert_eq!(observed.outcome, PriorOutcome::MissingVisibleSlot);
                assert!(expected > &BigInt::from(0u8));
                println!(
                    "STAGE12_PRIOR i={i} back={back} slot={} actual=MISSING expected={expected}",
                    observed.slot
                );
                red += 1;
            } else {
                let expected = &prefix[i - back - 1];
                assert_eq!(observed.outcome, PriorOutcome::Visible(expected.clone()));
                println!(
                    "STAGE12_PRIOR i={i} back={back} slot={} actual={expected} expected={expected}",
                    observed.slot
                );
                control += 1;
            }
        }
    }
    assert_eq!((red, control), (11, 127));
    println!("STAGE12_MATRIX RED={red} CONTROL={control}");
}

#[test]
fn stage12_prior_invalid_inputs_are_rejected() {
    for (i, back) in [(0, 1), (47, 1), (usize::MAX, 7), (1, 0), (1, 2), (1, usize::MAX)] {
        assert_eq!(
            legacy_prior(&[], i, back).unwrap_err().code,
            MonsterErrorCode::InvalidState
        );
    }
    assert!(legacy_prior(&[], 2, 1).is_err());
    assert!(legacy_prior(&[BigInt::from(0u8)], 2, 1).is_err());
    let f = BigInt::from(FOUNDATION);
    let mut missing = MonsterContext::new(f.clone(), f.clone());
    let handler = LegacyPriorDiscovery06 {
        visible_prefix: Vec::new(),
        i: 1,
        back: 1,
    };
    let before = missing.clone();
    assert!(handler.handle(&mut missing).is_err());
    assert_eq!(missing, before);
    let mut valid = observe_legacy_prior(f.clone(), f, Vec::new(), 1, 1).unwrap();
    let before = valid.clone();
    assert!(handler.handle(&mut valid).is_err());
    assert_eq!(valid, before);
}

#[test]
#[ignore = "strict historical RED witness; execute separately"]
fn stage12_strict_red_prior_zero() {
    let f = BigInt::from(FOUNDATION);
    let expected = independent_hidden_values(&f, &f, &independent_stones())[1].clone();
    let context = observe_legacy_prior(f.clone(), f, Vec::new(), 1, 1).unwrap();
    assert_eq!(
        context.discovery06_prior_observation.unwrap().outcome,
        PriorOutcome::Visible(expected),
        "STAGE12 strict normative prior assertion"
    );
}
