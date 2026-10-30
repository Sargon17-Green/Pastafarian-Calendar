//! Mərhələ 3 — PATCH01: bütün işarəli BigInt girişləri üçün normativ SAVE.
//! Tarixi DISCOVERY01 yolu toxunulmaz saxlanılır.
use crate::{MonsterContext, MonsterError, MonsterErrorCode, MonsterManager, PhaseHandler};
use num_bigint::BigInt;
use num_integer::Integer;
use num_traits::One;

pub struct SavePatch01;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SavePatchObservation {
    pub input: BigInt,
    pub save_value: BigInt,
    pub context: MonsterContext,
}

/// SAVE(x) = 1 + mod_floor(x - 1, 2^127 - 1); nəticə həmişə [1, M].
pub fn normative_save(x: &BigInt) -> BigInt {
    let m = (BigInt::one() << 127usize) - BigInt::one();
    let offset = x - &BigInt::one();
    BigInt::one() + offset.mod_floor(&m)
}

impl PhaseHandler for SavePatch01 {
    fn name(&self) -> &'static str {
        "PATCH01:NORMATIVE-SAVE"
    }

    fn handle(&self, context: &mut MonsterContext) -> Result<(), MonsterError> {
        context.save_observation = Some(normative_save(&context.calculation_day));
        context.metrics.bump("patch01.save.calls");
        context.logs.push("PATCH01: normativ SAVE hesablandı.");
        Ok(())
    }
}

/// İstehsal dispetçerindən keçən yeni, müstəqil çağırış.
pub fn calculate_save(input: BigInt) -> Result<SavePatchObservation, MonsterError> {
    let mut manager = MonsterManager::default();
    manager.dispatcher_mut().register(SavePatch01);
    let context = manager.execute_bootstrap_shell(input.clone(), input.clone())?;
    let save_value = context.save_observation.clone().ok_or_else(|| MonsterError {
        code: MonsterErrorCode::InvalidState,
        message: "PATCH01: SAVE müşahidəsi yoxdur.".to_owned(),
    })?;
    Ok(SavePatchObservation {
        input,
        save_value,
        context,
    })
}
