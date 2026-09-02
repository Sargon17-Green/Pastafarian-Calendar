expect_true <- function(value, label) {
  if (!isTRUE(value)) stop(paste('Ha fallat:', label))
}

expect_identical <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    stop(paste('Ha fallat:', label, '| esperat:', paste(expected, collapse = ','), '| obtingut:', paste(actual, collapse = ',')))
  }
}

expect_bi <- function(actual, expected, label) expect_identical(bi_to_string(actual), expected, label)

run_stage01_tests <- function(root) {
  source(file.path(root, 'tests', 'fixtures_stage01.R'), local = FALSE)
  f <- STAGE01_FIXTURES

  expect_identical(bi_to_string(M), f$m, 'M exacte')
  expect_bi(nr_save(bi_one()), f$save$one, 'SAVE(1)')
  expect_bi(bi_sub(bi_pow_small(bi_from_int(2L), 127L), bi_one()), f$m, 'M derivat com 2^127-1')
  expect_bi(nr_save(bi_sub(M, bi_one())), f$save$m_minus_one, 'SAVE(M-1)')
  expect_bi(nr_save(M), f$save$m, 'SAVE(M)')
  expect_bi(nr_save(bi_add(M, bi_one())), f$save$m_plus_one, 'SAVE(M+1)')
  expect_bi(nr_save(bi_mul_i(M, 2L)), f$save$two_m, 'SAVE(2M)')
  expect_bi(bi_mod(bi_from_int(-1L), bi_from_int(7L)), '6', 'mòdul euclidià negatiu')
  expect_bi(bi_floor_div(bi_from_int(-8L), bi_from_int(7L)), '-2', 'divisió entera cap avall')

  expect_bi(nr_day_count(bi_sub_i(FOUNDATION_DAY, 2L)), f$day_count$foundation_minus_two, 'recompte dos dies abans de la Fundació')
  expect_bi(nr_day_count(bi_sub_i(FOUNDATION_DAY, 1L)), f$day_count$foundation_minus_one, 'recompte un dia abans de la Fundació')
  expect_bi(nr_day_count(FOUNDATION_DAY), f$day_count$foundation, 'recompte del dia de la Fundació')
  expect_bi(nr_day_count(bi_add_i(FOUNDATION_DAY, 1L)), f$day_count$foundation_plus_one, 'recompte un dia després de la Fundació')
  expect_bi(nr_day_count(bi_add_i(FOUNDATION_DAY, 2L)), f$day_count$foundation_plus_two, 'recompte dos dies després de la Fundació')

  wc <- nr_work_counts(FOUNDATION_DAY, FOUNDATION_DAY)
  gotCounts <- c(bi_to_string(wc$action), bi_to_string(wc$target), bi_to_string(wc$distance), bi_to_string(wc$connection), bi_to_string(wc$direction))
  expect_identical(gotCounts, f$work_counts_same_foundation, 'comptadors quan els dos dies són la Fundació')

  expect_identical(vapply(STONES[[2L]], bi_to_string, character(1L)), f$stone_row_2, 'segona fila de pedres')
  expect_identical(nr_permutation_unrank1(1L, 1:6), f$permutation_1, 'primera permutació')
  expect_identical(nr_permutation_unrank1(720L, 1:6), f$permutation_720, 'última permutació')

  bounded <- nr_make_bounded_composition_family(10L, 2L, 4L, 6L)
  expect_bi(bounded$count(), f$bounded_10_2_4_6_count, 'nombre de composicions acotades petites')
  expect_identical(bounded$unrank1(bi_from_int(2L)), f$bounded_10_2_4_6_rank_2, 'desclassificació lexicogràfica de composicions')

  weave <- nr_make_weaving_family(c(2L, 2L))
  expect_bi(weave$count(), f$weaving_2_2_count, 'nombre de teixits 2+2')
  expect_identical(weave$unrank1(bi_from_int(1L)), f$weaving_2_2_rank_1, 'primer teixit 2+2')
  expect_identical(weave$unrank1(bi_from_int(2L)), f$weaving_2_2_rank_2, 'segon teixit 2+2')

  expect_true(source_catalog_validate(), 'validació del catàleg de llengua font')
  expect_identical(CUTLET_SOURCE_CATALOG$canonicalIndex, 1:17, 'índexs canònics de mandonguilles')
  expect_identical(MONTH_SOURCE_CATALOG$canonicalIndex, 1:47, 'índexs canònics de mesos')
  expect_identical(cutlet_name_by_index(12L), 'blat', 'traducció semàntica de blat')
  expect_identical(month_name_by_index(41L), 'Babilònia', 'nom propi de Babilònia')

  c1 <- bootstrap_dispatch(new_monster_context('1', '2'))
  c2 <- bootstrap_dispatch(new_monster_context('1', '2'))
  c1$metrics$local_only <- 99L
  expect_true(is.null(c2$metrics$local_only), 'el context no es comparteix entre invocacions')
  expect_identical(c2$status, 'BOOTSTRAP_READY', 'estat del dispatcher de bootstrap')

  productionText <- paste(readLines(file.path(root, 'R', 'bootstrap_monster.R'), warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
  expect_true(!grepl('nr_sauce|normative_calendar_date|nr_calendar_date_indices', productionText), 'producció sense crida a l\'oracle')
  expect_true(!grepl('oldRemainder|oldDayTag|oldDistance|LEGACY_YEAR_MAX|orderAt46Latch', productionText), 'cap codi de pedaç futur al bootstrap')

  TRUE
}
