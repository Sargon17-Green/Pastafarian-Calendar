use num_bigint::BigInt;
use num_traits::{One, Signed};

use pastafarian_calendar_rust_az::discovery03_stone_probe::Stone;
use pastafarian_calendar_rust_az::patch04_stone_probe::{
    calendar_stones_patched_spaghetti, stone_patch, StonePatch04,
};
use pastafarian_calendar_rust_az::{
    calendar_date_spaghetti, MonsterContext, MonsterErrorCode, PhaseHandler,
};

fn independent_save(raw: &BigInt) -> BigInt {
    let modulus = (BigInt::one() << 127usize) - BigInt::one();
    let mut remainder = (raw - BigInt::one()) % &modulus;
    if remainder.is_negative() {
        remainder += &modulus;
    }
    remainder + BigInt::one()
}

fn snapshot_next(old: &Stone, row: usize) -> Stone {
    let i = BigInt::from(row);
    [
        independent_save(&(&old[0] * &old[0] + BigInt::from(3u8) * &old[1] + &i)),
        independent_save(&(&old[1] * &old[1] + BigInt::from(5u8) * &old[2] + &old[0])),
        independent_save(&(&old[2] * &old[2] + BigInt::from(7u8) * &old[3] + &old[1])),
        independent_save(&(&old[3] * &old[3] + BigInt::from(11u8) * &old[4] + &old[2])),
        independent_save(&(&old[4] * &old[4] + BigInt::from(13u8) * &old[0] + &old[3])),
    ]
}

fn sequential_next(previous: &Stone, row: usize) -> Stone {
    let mut current = previous.clone();
    current[0] = independent_save(&(&current[0] * &current[0]
        + BigInt::from(3u8) * &current[1] + BigInt::from(row)));
    current[1] = independent_save(&(&current[1] * &current[1]
        + BigInt::from(5u8) * &current[2] + &current[0]));
    current[2] = independent_save(&(&current[2] * &current[2]
        + BigInt::from(7u8) * &current[3] + &current[1]));
    current[3] = independent_save(&(&current[3] * &current[3]
        + BigInt::from(11u8) * &current[4] + &current[2]));
    current[4] = independent_save(&(&current[4] * &current[4]
        + BigInt::from(13u8) * &current[0] + &current[3]));
    current
}

fn independent_tables() -> (Vec<Stone>, Vec<Stone>, Vec<Stone>) {
    let seed: Stone = [17, 29, 43, 71, 101].map(BigInt::from);
    let mut corrected = vec![seed.clone()];
    let mut garbage = vec![seed.clone()];
    let mut legacy = vec![seed];
    for row in 2..=46 {
        garbage.push(sequential_next(corrected.last().unwrap(), row));
        corrected.push(snapshot_next(corrected.last().unwrap(), row));
        legacy.push(sequential_next(legacy.last().unwrap(), row));
    }
    (corrected, garbage, legacy)
}

#[test]
fn stage09_patch04_corrects_snapshot_and_preserves_both_legacy_records() {
    let foundation = BigInt::from(-15_055_671i64);
    let calculation_day = &foundation - BigInt::one();
    let target_day = &foundation + BigInt::one();
    let observed = calendar_stones_patched_spaghetti(calculation_day.clone(), target_day.clone())
        .expect("PATCH02 -> DISCOVERY03 -> PATCH03 -> DISCOVERY04 -> PATCH04");
    let (expected, expected_garbage, expected_legacy) = independent_tables();

    assert_eq!(observed.corrected_rows.len(), 46);
    assert_eq!(observed.legacy_garbage_rows.len(), 46);
    assert_eq!(observed.legacy_rows.len(), 46);
    assert_eq!(observed.corrected_rows, expected);
    assert_eq!(observed.legacy_garbage_rows, expected_garbage);
    assert_eq!(observed.legacy_rows, expected_legacy);
    assert_eq!(observed.corrected_rows[1], [378, 1073, 2375, 6195, 10493].map(BigInt::from));
    assert_eq!(observed.legacy_garbage_rows[1], [378, 1434, 3780, 9932, 25047].map(BigInt::from));
    assert_eq!(observed.legacy_garbage_rows[2], [146106, 1309310, 6993300, 45486748, 157489175].map(BigInt::from));

    let maximum = (BigInt::one() << 127usize) - BigInt::one();
    for value in observed.corrected_rows.iter().flatten()
        .chain(observed.legacy_garbage_rows.iter().flatten())
        .chain(observed.legacy_rows.iter().flatten())
    {
        assert!(value >= &BigInt::one() && value <= &maximum);
    }

    let fields = ["w", "b", "s", "m", "r"];
    let mut corrected_green = 0usize;
    for row in 0..46 {
        for col in 0..5 {
            assert_eq!(observed.corrected_rows[row][col], expected[row][col]);
            corrected_green += 1;
            println!(
                "STAGE09_CORRECTED_CELL row={} field={} value={} expected={} class=GREEN",
                row + 1, fields[col], observed.corrected_rows[row][col], expected[row][col]
            );
        }
    }

    let mut garbage_red = 0usize;
    let mut garbage_match = 0usize;
    let mut legacy_red = 0usize;
    let mut legacy_match = 0usize;
    for row in 1..46 {
        for col in 0..5 {
            let g_class = if observed.legacy_garbage_rows[row][col] == expected[row][col] {
                garbage_match += 1;
                "MATCH"
            } else {
                garbage_red += 1;
                "RED"
            };
            println!(
                "STAGE09_GARBAGE_CELL row={} field={} value={} expected={} class={}",
                row + 1, fields[col], observed.legacy_garbage_rows[row][col],
                expected_garbage[row][col], g_class
            );
            let l_class = if observed.legacy_rows[row][col] == expected[row][col] {
                legacy_match += 1;
                "MATCH"
            } else {
                legacy_red += 1;
                "RED"
            };
            println!(
                "STAGE09_LEGACY_CELL row={} field={} value={} expected={} class={}",
                row + 1, fields[col], observed.legacy_rows[row][col],
                expected[row][col], l_class
            );
        }
    }
    assert_eq!(corrected_green, 230);
    assert_eq!((garbage_red, garbage_match), (180, 45));
    assert_eq!((legacy_red, legacy_match), (224, 1));

    assert_eq!(observed.context.metrics.get("patch02.work_counts.calls"), 1);
    assert_eq!(observed.context.metrics.get("discovery03.distance.calls"), 1);
    assert_eq!(observed.context.metrics.get("patch03.distance.calls"), 1);
    assert_eq!(observed.context.metrics.get("discovery04.stones.calls"), 1);
    assert_eq!(observed.context.metrics.get("patch04.legacy.calls"), 45);
    assert_eq!(observed.context.metrics.get("patch04.applied"), 1);
    assert_eq!(observed.context.metrics.get("dispatcher.handler.completed"), 5);
    assert_eq!(
        observed.context.branch_trace,
        vec![
            "PATCH02:NORMATIVE-WORK-COUNTS".to_owned(),
            "DISCOVERY03:LEGACY-TAG-DISTANCE".to_owned(),
            "PATCH03:CHRONOLOGICAL-DISTANCE-CORRECTION".to_owned(),
            "DISCOVERY04:LEGACY-SEQUENTIAL-STONES".to_owned(),
            "PATCH04:SNAPSHOT-STONE-CORRECTION".to_owned(),
        ]
    );
    let stored = observed.context.patch04_stone_observation.as_ref().unwrap();
    assert_eq!(stored.row_count, 46);
    assert_eq!(stored.component_count, 230);
    assert_eq!(stored.legacy_calls, 45);
    assert_eq!(stored.corrected_rows, observed.corrected_rows);
    assert_eq!(stored.legacy_garbage_rows, observed.legacy_garbage_rows);

    let seed: Stone = [17, 29, 43, 71, 101].map(BigInt::from);
    let before = seed.clone();
    let wrapped = stone_patch(&seed, 2).unwrap();
    assert_eq!(seed, before);
    assert_eq!(wrapped.corrected, expected[1]);
    assert_eq!(wrapped.legacy_garbage, expected_garbage[1]);
    assert_ne!(wrapped.corrected, wrapped.legacy_garbage);

    let mut guards = 0usize;
    for invalid in [1usize, 47usize] {
        assert_eq!(stone_patch(&seed, invalid).unwrap_err().code, MonsterErrorCode::InvalidState);
        guards += 1;
    }

    let mut duplicate = observed.context.clone();
    let before_duplicate = duplicate.clone();
    let duplicate_error = StonePatch04.handle(&mut duplicate).unwrap_err();
    assert_eq!(duplicate_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(duplicate, before_duplicate);
    guards += 1;

    let mut missing_stage08 = MonsterContext::new(foundation.clone(), foundation.clone());
    let before_missing = missing_stage08.clone();
    let missing_error = StonePatch04.handle(&mut missing_stage08).unwrap_err();
    assert_eq!(missing_error.code, MonsterErrorCode::InvalidState);
    assert_eq!(missing_stage08, before_missing);
    guards += 1;

    let second = calendar_stones_patched_spaghetti(calculation_day, target_day).unwrap();
    assert_eq!(second.corrected_rows, observed.corrected_rows);
    assert_eq!(second.legacy_garbage_rows, observed.legacy_garbage_rows);
    let mut first_corrected = observed.corrected_rows.clone();
    let second_corrected = second.corrected_rows.clone();
    first_corrected[2][0] += BigInt::one();
    assert_ne!(first_corrected, second_corrected);

    let bootstrap_error = calendar_date_spaghetti(foundation.clone(), foundation).unwrap_err();
    assert_eq!(bootstrap_error.code, MonsterErrorCode::BootstrapOnly);
    guards += 1;
    assert_eq!(guards, 5);

    println!("STAGE09_CORRECTED_ROWS=46 CELLS=230");
    println!("STAGE09_CORRECTED_GREEN=230/230");
    println!("STAGE09_GARBAGE_CAPTURE=PASS ROWS=45 CELLS=225 RED=180 MATCH=45");
    println!("STAGE09_PRESERVED_DISCOVERY04_RED=224 MATCH=1 UNEXPECTED=0");
    println!("STAGE09_CALLS=45 GUARDS=5");
    println!("STAGE09_BOOTSTRAP_ONLY=PASS");
}
