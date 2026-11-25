use num_bigint::BigInt;
use crate::discovery03_stone_probe::Stone;
use crate::patch01_save::normative_save;
use crate::patch02_work_counts::{LegacyTagDistanceDiscovery03, WorkCountsPatch02};
use crate::patch03_distance::Patch03DistanceCorrection;
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};

const LAST_ROW: usize = 46;

fn initial_stone() -> Stone {
    [17, 29, 43, 71, 101].map(BigInt::from)
}

/// Historical in-place mutator: later fields read fields already updated.
pub fn mutate_stones_wrong(row_index: usize, stones: &mut Stone) -> Result<(), MonsterError> {
    if !(2..=LAST_ROW).contains(&row_index) {
        return Err(MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY04: row index must be in 2..=46".to_owned(),
        });
    }
    let w = stones[0].clone();
    let b = stones[1].clone();
    stones[0] = normative_save(&(&w * &w + BigInt::from(3u8) * &b + BigInt::from(row_index)));
    let b = stones[1].clone();
    let s = stones[2].clone();
    let w = stones[0].clone();
    stones[1] = normative_save(&(&b * &b + BigInt::from(5u8) * &s + w));
    let s = stones[2].clone();
    let m = stones[3].clone();
    let b = stones[1].clone();
    stones[2] = normative_save(&(&s * &s + BigInt::from(7u8) * &m + b));
    let m = stones[3].clone();
    let r = stones[4].clone();
    let s = stones[2].clone();
    stones[3] = normative_save(&(&m * &m + BigInt::from(11u8) * &r + s));
    let r = stones[4].clone();
    let w = stones[0].clone();
    let m = stones[3].clone();
    stones[4] = normative_save(&(&r * &r + BigInt::from(13u8) * &w + m));
    Ok(())
}

fn legacy_stone_table() -> Vec<Stone> {
    let mut rows = Vec::with_capacity(LAST_ROW);
    rows.push(initial_stone());
    for row_index in 2..=LAST_ROW {
        let mut next = rows.last().expect("seed row exists").clone();
        mutate_stones_wrong(row_index, &mut next).expect("internal row index is valid");
        rows.push(next);
    }
    rows
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Discovery04StoneObservation {
    pub rows: Vec<Stone>,
    pub row_count: usize,
    pub component_count: usize,
}

pub struct LegacyStoneDiscovery04;

impl PhaseHandler for LegacyStoneDiscovery04 {
    fn name(&self) -> &'static str {
        "DISCOVERY04:LEGACY-SEQUENTIAL-STONES"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        if context.discovery04_stone_observation.is_some()
            || context.metrics.get("discovery04.stones.calls") != 0
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY04 duplicate invocation".to_owned(),
            });
        }
        if context.metrics.get("patch02.work_counts.calls") != 1
            || context.metrics.get("discovery03.distance.calls") != 1
            || context.metrics.get("patch03.distance.calls") != 1
            || context.patch03_distance_observation.is_none()
        {
            return Err(MonsterError {
                code: MonsterErrorCode::InvalidState,
                message: "DISCOVERY04 requires completed PATCH02/DISCOVERY03/PATCH03 observations"
                    .to_owned(),
            });
        }
        let rows = legacy_stone_table();
        let observation = Discovery04StoneObservation {
            row_count: rows.len(),
            component_count: rows.len() * 5,
            rows,
        };
        context.logs.push(format!(
            "DISCOVERY04: sequential legacy stone table rows={} cells={}",
            observation.row_count, observation.component_count
        ));
        context.discovery04_stone_observation = Some(observation);
        context.metrics.bump("discovery04.stones.calls");
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Discovery04Observation {
    pub rows: Vec<Stone>,
    pub context: MonsterContext,
}

pub fn calendar_stones_spaghetti(
    calculation_day: BigInt,
    target_day: BigInt,
) -> Result<Discovery04Observation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(WorkCountsPatch02);
    manager.dispatcher_mut().register(LegacyTagDistanceDiscovery03);
    manager.dispatcher_mut().register(Patch03DistanceCorrection);
    manager.dispatcher_mut().register(LegacyStoneDiscovery04);
    let context = manager.execute_bootstrap_shell(calculation_day, target_day)?;
    let rows = context.discovery04_stone_observation.as_ref()
        .map(|observation| observation.rows.clone())
        .ok_or_else(|| MonsterError {
            code: MonsterErrorCode::InvalidState,
            message: "DISCOVERY04 result is missing".to_owned(),
        })?;
    Ok(Discovery04Observation { rows, context })
}
