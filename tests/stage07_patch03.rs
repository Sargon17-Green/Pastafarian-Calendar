use num_bigint::BigInt;
use num_traits::{One, Signed};

use pastafarian_calendar_rust_az::patch02_work_counts::WorkCounts;
use pastafarian_calendar_rust_az::patch03_distance::{
    calculate_patched_distance, Patch03DistanceCorrection,
};
use pastafarian_calendar_rust_az::{
    calendar_date_spaghetti, MonsterContext, MonsterErrorCode, PhaseHandler,
};

fn independent_tag(offset: &BigInt) -> BigInt {
    if offset.is_negative() {
        offset.abs() * BigInt::from(2u8)
    } else {
        offset * BigInt::from(2u8) + BigInt::one()
    }
}

#[test]
fn stage07_patch03_corrects_distance_and_preserves_stage06_observation() {
    let foundation = BigInt::from(-15_055_671i64);
    let mut offsets: Vec<BigInt> = [-11i64, -5, -2, -1, 0, 1, 2, 5, 11]
        .into_iter()
        .map(BigInt::from)
        .collect();

    for bits in [130usize, 1032] {
        let wide = BigInt::one() << bits;
        offsets.push(-&wide);
        offsets.push(wide);
    }
    let widest = (BigInt::one() << 4097usize) + BigInt::one();
    offsets.push(-&widest);
    offsets.push(widest);

    assert_eq!(offsets.len(), 15);

    let mut mismatch_count = 0usize;
    let mut match_count = 0usize;
    let mut duplicate_guards = 0usize;

    for calculation_offset in &offsets {
        for target_offset in &offsets {
            let expected_legacy =
                (independent_tag(calculation_offset) - independent_tag(target_offset)).abs();
            let chronological_base = (target_offset - calculation_offset).abs();
            let legacy_mismatch = expected_legacy != chronological_base;
            let selected_base = if legacy_mismatch {
                chronological_base.clone()
            } else {
                expected_legacy.clone()
            };
            let expected_distance = &selected_base + BigInt::one();

            let observed = calculate_patched_distance(
                &foundation + calculation_offset,
                &foundation + target_offset,
            )
            .expect("PATCH02 -> DISCOVERY03 -> PATCH03 istehsal zənciri uğurlu olmalıdır");

            assert_eq!(observed.result.legacy_distance, expected_legacy);
            assert_eq!(observed.result.chronological_base, chronological_base);
            assert_eq!(observed.result.legacy_mismatch, legacy_mismatch);
            assert_eq!(observed.result.selected_base, selected_base);
            assert_eq!(observed.result.distance, expected_distance);

            let stage06 = observed
                .context
                .work_counts_observation
                .as_ref()
                .expect("Stage06 müşahidəsi saxlanmalıdır");
            assert_eq!(stage06.distance, expected_legacy);
            assert_eq!(observed.context.metrics.get("patch02.work_counts.calls"), 1);
            assert_eq!(
                observed.context.metrics.get("patch02.legacy.action.calls"),
                1
            );
            assert_eq!(
                observed.context.metrics.get("patch02.legacy.target.calls"),
                1
            );
            assert_eq!(
                observed.context.metrics.get("discovery03.distance.calls"),
                1
            );
            assert_eq!(observed.context.metrics.get("patch03.distance.calls"), 1);
            assert_eq!(
                observed.context.metrics.get("dispatcher.handler.completed"),
                3
            );
            assert_eq!(
                observed.context.branch_trace,
                vec![
                    "PATCH02:NORMATIVE-WORK-COUNTS".to_owned(),
                    "DISCOVERY03:LEGACY-TAG-DISTANCE".to_owned(),
                    "PATCH03:CHRONOLOGICAL-DISTANCE-CORRECTION".to_owned(),
                ]
            );

            let mut duplicate = observed.context.clone();
            let snapshot = duplicate.clone();
            let error = Patch03DistanceCorrection
                .handle(&mut duplicate)
                .unwrap_err();
            assert_eq!(error.code, MonsterErrorCode::InvalidState);
            assert_eq!(duplicate, snapshot);
            duplicate_guards += 1;

            if legacy_mismatch {
                mismatch_count += 1;
            } else {
                match_count += 1;
            }

            println!(
                "PATCH03_DISTANCE_ROW c={calculation_offset} t={target_offset} legacy={} chronological={} mismatch={} selected={} result={}",
                observed.result.legacy_distance,
                observed.result.chronological_base,
                observed.result.legacy_mismatch,
                observed.result.selected_base,
                observed.result.distance
            );
        }
    }

    let mut missing_stage06 = MonsterContext::new(foundation.clone(), foundation.clone());
    missing_stage06.work_counts_observation = Some(WorkCounts {
        action: BigInt::from(1u8),
        target: BigInt::from(1u8),
        distance: BigInt::from(0u8),
        connection: BigInt::from(2u8),
        direction: 2,
    });
    let snapshot = missing_stage06.clone();
    let error = Patch03DistanceCorrection
        .handle(&mut missing_stage06)
        .unwrap_err();
    assert_eq!(error.code, MonsterErrorCode::InvalidState);
    assert_eq!(missing_stage06, snapshot);

    assert_eq!(mismatch_count, 204);
    assert_eq!(match_count, 21);
    assert_eq!(duplicate_guards, 225);

    let bootstrap_error = calendar_date_spaghetti(foundation.clone(), foundation).unwrap_err();
    assert_eq!(bootstrap_error.code, MonsterErrorCode::BootstrapOnly);

    println!("STAGE07_PATCH03_ROWS=225 MISMATCH=204 MATCH=21 GUARDS=226");
    println!("STAGE07_PATCH03_BOOTSTRAP_ONLY=PASS");
}
