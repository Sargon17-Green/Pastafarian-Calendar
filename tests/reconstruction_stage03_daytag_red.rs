//! Original Stage03 ancestry plus intentionally defective native Rust production route.
use num_bigint::BigInt;
use num_traits::One;
use pastafarian_calendar_rust_az::discovery02_legacy_day_tag::{
    legacy_day_tag, observe_legacy_day_tag,
};
use pastafarian_calendar_rust_az::{MonsterPhase, MonsterStatus};

fn independent_oracle(day: &BigInt) -> BigInt {
    // Case-defined integer oracle; never calls or adapts production code.
    let foundation = BigInt::from(-15_055_671i64);
    if day < &foundation {
        (&foundation - day) * BigInt::from(2u8)
    } else {
        (day - &foundation) * BigInt::from(2u8) + BigInt::one()
    }
}

#[test]
fn compiled_production_spaghetti_reconstructs_real_numeric_red() {
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
    let mut red = 0usize;
    let mut control = 0usize;
    for (input, should_be_red) in cases {
        let observed = observe_legacy_day_tag(input.clone())
            .expect("real MonsterManager dispatcher path");
        let independent = independent_oracle(&input);
        let different = observed.legacy_tag != independent;
        assert_eq!(different, should_be_red, "case {} must have exact polarity", input);
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
        let second = observe_legacy_day_tag(input.clone()).expect("isolated fresh invocation");
        assert_eq!(second, observed);
        println!(
            "RECONSTRUCTED_RUST_DAYTAG_CASE={} ACTUAL={} ORACLE={} RED={}",
            input, observed.legacy_tag, independent, different
        );
        if different { red += 1; } else { control += 1; }
    }
    assert_eq!((red, control), (3, 3));
    println!("RECONSTRUCTED_RUST_DAYTAG_RED=3 CONTROL=3 UNEXPECTED=0");
}
