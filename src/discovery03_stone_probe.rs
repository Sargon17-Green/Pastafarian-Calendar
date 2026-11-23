//! Mərhələ 6 / DISCOVERY03: 46×5 sabit daş ardıcıllığı üçün ayrıca zond.
//! Yalnız əvvəlki qəbul edilmiş PATCH01 SAVE istehsal funksiyasına əsaslanır.
//! Beş-sahəli yekun təqvim marşrutu bu zonda qoşulmayıb; tarixi RED iddiası yoxdur.

use num_bigint::BigInt;

use crate::patch01_save::normative_save;

pub type Stone = [BigInt; 5];

const COEFFICIENTS: [u8; 5] = [3, 5, 7, 11, 13];

/// İlk daş daxil olmaqla 46 sətir; hər sətirdə beş müsbət BigInt.
/// Hər yeni sətir yalnız əvvəlki sətirin dəyərlərindən hesablanır.
pub fn candidate_stones() -> Vec<Stone> {
    let mut stones: Vec<Stone> = Vec::with_capacity(46);
    stones.push([17, 29, 43, 71, 101].map(BigInt::from));

    for step in 2usize..=46 {
        let previous = stones.last().expect("ilk daş sətiri mövcuddur");
        let next: Stone = std::array::from_fn(|index| {
            let trailing_term = if index == 0 {
                BigInt::from(step)
            } else {
                previous[index - 1].clone()
            };
            let raw = &previous[index] * &previous[index]
                + BigInt::from(COEFFICIENTS[index]) * &previous[(index + 1) % 5]
                + trailing_term;
            normative_save(&raw)
        });
        stones.push(next);
    }

    stones
}
