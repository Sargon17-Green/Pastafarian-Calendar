use num_bigint::BigInt;

use crate::discovery03_stone_probe::Stone;
use crate::discovery04_stone_probe::{mutate_stones_wrong, LegacyStoneDiscovery04};
use crate::patch01_save::normative_save;
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

const FIRST_ROW: usize = 1;
const LAST_ROW: usize = 46;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StonePatchResult {
    pub corrected: Stone,
    pub legacy_garbage: Stone,
}

/// Calls the historical mutator on a clone, captures its output, then writes
/// every corrected field from the same immutable snapshot.
pub fn stone_patch(previous: &Stone, row_index: usize) -> Result<StonePatchResult, MonsterError> {
    if !(2..=LAST_ROW).contains(&row_index) {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "PATCH04: row index must be in 2..=46".to_owned(),
        });
    }
    let old = previous.clone();
    let mut legacy_garbage = old.clone();
    mutate_stones_wrong(row_index, &mut legacy_garbage)?;

    let corrected = [
        normative_save(
            &(&old[0] * &old[0] + BigInt::from(3u8) * &old[1] + BigInt::from(row_index)),
        ),
        normative_save(&(&old[1] * &old[1] + BigInt::from(5u8) * &old[2] + &old[0])),
        normative_save(&(&old[2] * &old[2] + BigInt::from(7u8) * &old[3] + &old[1])),
        normative_save(&(&old[3] * &old[3] + BigInt::from(11u8) * &old[4] + &old[2])),
        normative_save(&(&old[4] * &old[4] + BigInt::from(13u8) * &old[0] + &old[3])),
    ];
    Ok(StonePatchResult {
        corrected,
        legacy_garbage,
    })
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch04StoneObservation {
    pub corrected_rows: Vec<Stone>,
    pub legacy_garbage_rows: Vec<Stone>,
    pub row_count: usize,
    pub component_count: usize,
    pub legacy_calls: usize,
}

pub struct StonePatch04;

impl PhaseHandler for StonePatch04 {
    fn name(&self) -> &'static str {
        "PATCH04:SNAPSHOT-STONE-CORRECTION"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.patch04_stone_observation.is_some()
            || context.metrics.get("patch04.applied") != 0
            || context.metrics.get("patch04.legacy.calls") != 0
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH04 duplicate invocation".to_owned(),
            });
        }
        let discovery = context.discovery04_stone_observation.as_ref();
        if context.metrics.get("patch02.work_counts.calls") != 1
            || context.metrics.get("discovery03.distance.calls") != 1
            || context.metrics.get("patch03.distance.calls") != 1
            || context.metrics.get("discovery04.stones.calls") != 1
            || discovery.is_none()
            || discovery.is_some_and(|x| {
                x.row_count != 46 || x.component_count != 230 || x.rows.len() != 46
            })
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH04 requires the completed Stage08 legacy stone observation"
                    .to_owned(),
            });
        }

        let seed: Stone = [17, 29, 43, 71, 101].map(BigInt::from);
        let mut corrected_rows = Vec::with_capacity(LAST_ROW);
        let mut legacy_garbage_rows = Vec::with_capacity(LAST_ROW);
        corrected_rows.push(seed.clone());
        legacy_garbage_rows.push(seed);

        for row_index in 2..=LAST_ROW {
            let previous = corrected_rows.last().expect("seed row exists").clone();
            let result = stone_patch(&previous, row_index)?;
            corrected_rows.push(result.corrected);
            legacy_garbage_rows.push(result.legacy_garbage);
        }

        let observation = Patch04StoneObservation {
            row_count: corrected_rows.len(),
            component_count: corrected_rows.len() * 5,
            legacy_calls: LAST_ROW - FIRST_ROW,
            corrected_rows,
            legacy_garbage_rows,
        };
        if observation.row_count != 46
            || observation.component_count != 230
            || observation.legacy_calls != 45
            || observation.legacy_garbage_rows.len() != 46
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "PATCH04 local table shape mismatch".to_owned(),
            });
        }

        context.patch04_stone_observation = Some(observation);
        for _ in 0..45 {
            context.metrics.bump("patch04.legacy.calls");
        }
        context.metrics.bump("patch04.applied");
        context.logs.push(
            "PATCH04: 46 snapshot rows committed; 45 historical mutator calls captured.".to_owned(),
        );
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Patch04Observation {
    pub corrected_rows: Vec<Stone>,
    pub legacy_garbage_rows: Vec<Stone>,
    pub legacy_rows: Vec<Stone>,
    pub context: MonsterContext,
}

pub fn calendar_stones_patched_spaghetti(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Patch04Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager
        .dispatcher_mut()
        .register(LegacyTagDistanceDiscovery03);
    manager.dispatcher_mut().register(Patch03DistanceCorrection);
    manager.dispatcher_mut().register(LegacyStoneDiscovery04);
    manager.dispatcher_mut().register(StonePatch04);
    let context = manager.execute_bootstrap_shell(calculation_day, target_day)?;

    let patch = context
        .patch04_stone_observation
        .as_ref()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "PATCH04 observation is missing".to_owned(),
        })?;
    let legacy_rows = context
        .discovery04_stone_observation
        .as_ref()
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY04 legacy rows are missing".to_owned(),
        })?
        .rows
        .clone();

    Ok(Patch04Observation {
        corrected_rows: patch.corrected_rows.clone(),
        legacy_garbage_rows: patch.legacy_garbage_rows.clone(),
        legacy_rows,
        context,
    })
}
