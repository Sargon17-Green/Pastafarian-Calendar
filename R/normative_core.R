M <- bi_from_string('170141183460469231731687303715884105727')
TABLETS_DAY <- bi_from_int(-278522L)
FOUNDATION_DAY <- bi_from_int(-15055671L)
YEAR_MIN_DAYS <- 252L
YEAR_MAX_DAYS <- 5778L

WHEAT <- 1L
BARLEY <- 2L
SALT <- 3L
BITTER <- 4L
RED <- 5L

SEAL_GATE_GAP <- 1L
SEAL_YEAR_5000 <- 10L
SEAL_NEXT_YEAR <- 11L
SEAL_PREVIOUS_YEAR <- 12L
SEAL_CUTLET_COUNT <- 20L
SEAL_CUTLET_PARTITION <- 21L
SEAL_CUTLET_NAMES <- 22L
SEAL_MONTH_COUNT <- 30L
SEAL_MONTH_LENGTHS <- 31L
SEAL_MONTH_WEAVING <- 32L
SEAL_MONTH_NAMES <- 33L

bi_mul_i <- function(a, n) bi_mul(a, bi_from_int(n))
bi_add_i <- function(a, n) bi_add(a, bi_from_int(n))
bi_sub_i <- function(a, n) bi_sub(a, bi_from_int(n))

nr_save <- function(x) bi_add(bi_mod(bi_sub(x, bi_one()), M), bi_one())
nr_wrap1 <- function(position, size) ((position - 1L) %% size) + 1L

nr_day_count <- function(day) {
  day <- as_bi(day)
  if (bi_eq(day, FOUNDATION_DAY)) return(bi_one())
  if (bi_gt(day, FOUNDATION_DAY)) return(bi_add_i(bi_mul_i(bi_sub(day, FOUNDATION_DAY), 2L), 1L))
  bi_mul_i(bi_sub(FOUNDATION_DAY, day), 2L)
}

nr_work_counts <- function(calculationDay, targetDay) {
  cDay <- as_bi(calculationDay)
  tDay <- as_bi(targetDay)
  c <- nr_day_count(cDay)
  t <- nr_day_count(tDay)
  distance <- bi_add_i(bi_abs(bi_sub(tDay, cDay)), 1L)
  connection <- bi_add(c, t)
  direction <- if (bi_lt(tDay, cDay)) 1L else if (bi_eq(tDay, cDay)) 2L else 3L
  list(action = c, target = t, distance = distance, connection = connection, direction = bi_from_int(direction))
}

nr_build_stones <- function() {
  stones <- vector('list', 46L)
  stones[[1L]] <- lapply(c(17L, 29L, 43L, 71L, 101L), bi_from_int)
  for (i in 2:46) {
    old <- stones[[i - 1L]]
    stones[[i]] <- list(
      nr_save(bi_add_i(bi_add(bi_square(old[[WHEAT]]), bi_mul_i(old[[BARLEY]], 3L)), i)),
      nr_save(bi_add(bi_add(bi_square(old[[BARLEY]]), bi_mul_i(old[[SALT]], 5L)), old[[WHEAT]])),
      nr_save(bi_add(bi_add(bi_square(old[[SALT]]), bi_mul_i(old[[BITTER]], 7L)), old[[BARLEY]])),
      nr_save(bi_add(bi_add(bi_square(old[[BITTER]]), bi_mul_i(old[[RED]], 11L)), old[[SALT]])),
      nr_save(bi_add(bi_add(bi_square(old[[RED]]), bi_mul_i(old[[WHEAT]], 13L)), old[[BITTER]]))
    )
  }
  stones
}

STONES <- nr_build_stones()

HIDDEN_COEFF <- list(
  c(3L,4L,6L,8L), c(5L,7L,10L,12L), c(7L,10L,14L,16L),
  c(9L,13L,18L,20L), c(11L,16L,22L,24L), c(13L,19L,26L,28L), c(15L,22L,30L,32L)
)
HIDDEN_GRIND_STONE <- c(WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY)

nr_build_hidden_drops <- function(counts, stones = STONES) {
  hidden <- vector('list', 7L)
  for (k in 1:7) {
    co <- HIDDEN_COEFF[[k]]
    x <- counts$action
    x <- bi_add(x, bi_mul_i(counts$target, co[[1L]]))
    x <- bi_add(x, bi_mul_i(counts$distance, co[[2L]]))
    x <- bi_add(x, bi_mul_i(counts$connection, co[[3L]]))
    x <- bi_add(x, bi_mul_i(counts$direction, co[[4L]]))
    for (kind in 1:5) x <- bi_add(x, stones[[k]][[kind]])
    x <- nr_save(x)
    for (grind in 1:7) {
      oldX <- x
      x <- nr_save(bi_add_i(bi_add(bi_add(bi_square(oldX), bi_mul_i(oldX, 3L)), stones[[k]][[HIDDEN_GRIND_STONE[[grind]]]]), grind))
    }
    hidden[[k]] <- x
  }
  hidden
}

VISIBLE_GRINDS <- list(
  c(3L,5L,7L,11L,WHEAT), c(5L,7L,11L,13L,BARLEY), c(7L,11L,13L,17L,SALT),
  c(11L,13L,17L,19L,BITTER), c(13L,17L,19L,23L,RED), c(17L,19L,23L,29L,WHEAT),
  c(19L,23L,29L,31L,BARLEY), c(23L,29L,31L,37L,SALT), c(29L,31L,37L,41L,BITTER),
  c(31L,37L,41L,43L,RED), c(37L,41L,43L,47L,WHEAT)
)

nr_timeline_get <- function(visible, hidden, slot) {
  if (slot >= 1L) return(visible[[slot]])
  hidden[[1L - slot]]
}

nr_build_visible_drops <- function(counts, stones = STONES, hidden) {
  visible <- vector('list', 46L)
  for (i in 1:46) {
    p1 <- nr_timeline_get(visible, hidden, i - 1L)
    p3 <- nr_timeline_get(visible, hidden, i - 3L)
    p7 <- nr_timeline_get(visible, hidden, i - 7L)
    x <- bi_mul(stones[[i]][[WHEAT]], counts$action)
    x <- bi_add(x, bi_mul(stones[[i]][[BARLEY]], counts$target))
    x <- bi_add(x, bi_mul(stones[[i]][[SALT]], counts$distance))
    x <- bi_add(x, bi_mul(stones[[i]][[BITTER]], counts$connection))
    x <- bi_add(x, bi_mul(stones[[i]][[RED]], counts$direction))
    x <- bi_add(x, p1)
    x <- bi_add(x, bi_mul_i(p3, 3L))
    x <- bi_add(x, bi_mul_i(p7, 5L))
    x <- nr_save(bi_add_i(x, i))
    for (grind in 1:11) {
      row <- VISIBLE_GRINDS[[grind]]
      oldX <- x
      x <- bi_square(oldX)
      x <- bi_add(x, bi_mul_i(oldX, row[[1L]]))
      x <- bi_add(x, bi_mul_i(p1, row[[2L]]))
      x <- bi_add(x, bi_mul_i(p3, row[[3L]]))
      x <- bi_add(x, bi_mul_i(p7, row[[4L]]))
      x <- bi_add(x, stones[[i]][[row[[5L]]]])
      x <- nr_save(x)
    }
    visible[[i]] <- x
  }
  visible
}

nr_permutation_unrank1 <- function(rank1, itemsAscending) {
  rank0 <- as.integer(rank1 - 1L)
  remaining <- itemsAscending
  result <- integer()
  while (length(remaining) > 0L) {
    slotsLeft <- length(remaining)
    block <- c(1L, 1L, 2L, 6L, 24L, 120L, 720L)[[slotsLeft]]
    q <- rank0 %/% block
    rank0 <- rank0 %% block
    result <- c(result, remaining[[q + 1L]])
    remaining <- remaining[-(q + 1L)]
  }
  result
}

nr_bowl_order_from_number <- function(orderNumber) {
  if (orderNumber < 1L || orderNumber > 720L) stop('El número d\'ordre de bols és fora de rang.')
  nr_permutation_unrank1(orderNumber, 1:6)
}

nr_bowl_order_from_drop <- function(dropValue) {
  r <- bi_to_small_integer(bi_add(bi_mod(bi_sub(dropValue, bi_one()), bi_from_int(720L)), bi_one()))
  nr_bowl_order_from_number(as.integer(r))
}

BOWL_PRIME <- c(17L,19L,23L,29L,31L,37L)
BOWL_STIR_STONE_BY_POSITION <- c(WHEAT,BARLEY,SALT,BITTER,RED,WHEAT)

nr_initial_bowls <- function(counts) {
  bowls <- vector('list', 6L)
  for (id in 1:6) {
    s <- counts$action
    s <- bi_add(s, bi_mul_i(counts$target, id))
    s <- bi_add(s, counts$distance)
    s <- bi_add(s, counts$connection)
    s <- bi_add(s, counts$direction)
    s <- bi_add_i(s, BOWL_PRIME[[id]] * BOWL_PRIME[[id]])
    bowls[[id]] <- nr_save(bi_add_i(bi_square(s), id))
  }
  bowls
}

nr_apply_visible_drops_to_bowls <- function(bowls, visible, stones = STONES) {
  orderAt46 <- NULL
  for (i in 1:46) {
    drop <- visible[[i]]
    order <- nr_bowl_order_from_drop(drop)
    old <- bowls
    pour <- lapply(1:6, function(x) bi_zero())
    pour[[1L]] <- nr_save(bi_add_i(bi_add(bi_square(drop), bi_mul(stones[[i]][[WHEAT]], old[[order[[1L]]]])), 3L * i))
    pour[[2L]] <- nr_save(bi_add_i(bi_add(bi_square(drop), bi_mul(stones[[i]][[BARLEY]], old[[order[[2L]]]])), 5L * i))
    pour[[3L]] <- nr_save(bi_add_i(bi_add(bi_square(drop), bi_mul(stones[[i]][[SALT]], old[[order[[3L]]]])), 7L * i))
    nextBowls <- vector('list', 6L)
    for (position in 1:6) {
      id <- order[[position]]
      prev <- order[[nr_wrap1(position - 1L, 6L)]]
      nextId <- order[[nr_wrap1(position + 1L, 6L)]]
      kind <- BOWL_STIR_STONE_BY_POSITION[[position]]
      s <- old[[id]]
      s <- bi_add(s, bi_mul_i(old[[prev]], 2L))
      s <- bi_add(s, bi_mul_i(old[[nextId]], 3L))
      s <- bi_add(s, pour[[position]])
      s <- bi_add(s, drop)
      s <- bi_add(s, stones[[i]][[kind]])
      z <- bi_square(s)
      z <- bi_add(z, bi_mul_i(bi_mul(old[[prev]], old[[nextId]]), 5L))
      z <- bi_add_i(z, i * position)
      nextBowls[[id]] <- nr_save(z)
    }
    bowls <- nextBowls
    if (i == 46L) orderAt46 <- order
  }
  list(bowls = bowls, orderAtDrop46 = orderAt46)
}

nr_post_stir12 <- function(bowls) {
  for (stir in 1:12) {
    old <- bowls
    savedBowlSum <- nr_save(bi_add_i(bi_sum(old), 149L * stir))
    orderNumber <- bi_to_small_integer(bi_add(bi_mod(bi_sub(savedBowlSum, bi_one()), bi_from_int(720L)), bi_one()))
    order <- nr_bowl_order_from_number(as.integer(orderNumber))
    nextBowls <- vector('list', 6L)
    for (position in 1:6) {
      id <- order[[position]]
      prev <- order[[nr_wrap1(position - 1L, 6L)]]
      nextId <- order[[nr_wrap1(position + 1L, 6L)]]
      s <- old[[id]]
      s <- bi_add(s, bi_mul_i(old[[prev]], 3L))
      s <- bi_add(s, bi_mul_i(old[[nextId]], 5L))
      s <- bi_add(s, savedBowlSum)
      s <- bi_add_i(s, stir + position * position)
      z <- bi_square(s)
      z <- bi_add(z, bi_mul_i(bi_mul(old[[prev]], old[[nextId]]), 7L))
      nextBowls[[id]] <- nr_save(z)
    }
    bowls <- nextBowls
  }
  bowls
}

nr_sauce <- function(calculationDay, targetDay) {
  counts <- nr_work_counts(calculationDay, targetDay)
  hidden <- nr_build_hidden_drops(counts, STONES)
  visible <- nr_build_visible_drops(counts, STONES, hidden)
  bowls <- nr_initial_bowls(counts)
  after <- nr_apply_visible_drops_to_bowls(bowls, visible, STONES)
  list(bowls = nr_post_stir12(after$bowls), orderAtDrop46 = after$orderAtDrop46)
}

nr_next_bowl_in_drop46_order <- function(sauceResult, queriedBowlId) {
  order <- sauceResult$orderAtDrop46
  p <- match(queriedBowlId, order)
  order[[if (p == 6L) 1L else p + 1L]]
}

nr_ask_bowl <- function(sauceResult, queriedBowlId, seal) {
  nextId <- nr_next_bowl_in_drop46_order(sauceResult, queriedBowlId)
  t <- bi_add_i(sauceResult$bowls[[queriedBowlId]], seal + 181L)
  first <- nr_save(bi_add_i(bi_add(bi_square(t), bi_mul_i(sauceResult$bowls[[nextId]], 179L)), seal))
  dbase <- bi_add_i(first, seal + 194L)
  directionNumber <- nr_save(bi_add(bi_add(bi_square(dbase), bi_mul_i(first, 193L)), bi_mul_i(sauceResult$bowls[[6L]], 197L)))
  step <- if (bi_to_small_integer(bi_mod(directionNumber, bi_from_int(2L))) == 1) 1L else -1L
  list(first = first, directionStep = step)
}

nr_answer_at <- function(stream, k) {
  kb <- as_bi(k)
  delta <- if (stream$directionStep == 1L) kb else bi_neg(kb)
  bi_add(bi_mod(bi_add(bi_sub(stream$first, bi_one()), delta), M), bi_one())
}

nr_choose_rank_short <- function(stream, N) {
  N <- as_bi(N)
  if (bi_lt(N, bi_one()) || bi_gt(N, M)) stop('La selecció curta exigeix 1 <= N <= M.')
  acceptanceLimit <- bi_mul(bi_floor_div(M, N), N)
  k <- bi_zero()
  repeat {
    x <- nr_answer_at(stream, k)
    if (bi_le(x, acceptanceLimit)) return(bi_add(bi_mod(bi_sub(x, bi_one()), N), bi_one()))
    k <- bi_add_i(k, 1L)
  }
}

nr_smallest_power_count <- function(base, N) {
  k <- 1L
  space <- as_bi(base)
  while (bi_lt(space, N)) {
    k <- k + 1L
    space <- bi_mul(space, base)
  }
  list(k = k, space = space)
}

nr_choose_rank_wide <- function(stream, N) {
  N <- as_bi(N)
  if (!bi_gt(N, M)) stop('La selecció ampla exigeix N > M.')
  power <- nr_smallest_power_count(M, N)
  wide <- bi_one()
  weight <- bi_one()
  for (j in 0L:(power$k - 1L)) {
    digit <- bi_sub(nr_answer_at(stream, bi_from_int(j)), bi_one())
    wide <- bi_add(wide, bi_mul(digit, weight))
    weight <- bi_mul(weight, M)
  }
  limit <- bi_mul(bi_floor_div(power$space, N), N)
  while (bi_gt(wide, limit)) {
    delta <- bi_from_int(stream$directionStep)
    wide <- bi_add(bi_mod(bi_add(bi_sub(wide, bi_one()), delta), power$space), bi_one())
  }
  bi_add(bi_mod(bi_sub(wide, bi_one()), N), bi_one())
}

nr_choose_rank <- function(stream, N) {
  N <- as_bi(N)
  if (bi_lt(N, bi_one())) stop('La família ordenada ha de tenir almenys un element.')
  if (bi_le(N, M)) nr_choose_rank_short(stream, N) else nr_choose_rank_wide(stream, N)
}
