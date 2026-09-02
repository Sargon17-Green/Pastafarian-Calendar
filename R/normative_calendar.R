NR_GATE_DAYS <- new.env(parent = emptyenv(), hash = TRUE)
NR_MIN_KNOWN_GATE_INDEX <- 0L
NR_MAX_KNOWN_GATE_INDEX <- 0L
assign('0', FOUNDATION_DAY, envir = NR_GATE_DAYS)

nr_gate_get <- function(index) {
  key <- as.character(index)
  if (!exists(key, envir = NR_GATE_DAYS, inherits = FALSE)) stop('S\'ha demanat una porta que encara no s\'ha generat.')
  get(key, envir = NR_GATE_DAYS, inherits = FALSE)
}

nr_gate_set <- function(index, day) assign(as.character(index), as_bi(day), envir = NR_GATE_DAYS)

nr_gate_reset <- function() {
  rm(list = ls(envir = NR_GATE_DAYS, all.names = TRUE), envir = NR_GATE_DAYS)
  assign('0', FOUNDATION_DAY, envir = NR_GATE_DAYS)
  NR_MIN_KNOWN_GATE_INDEX <<- 0L
  NR_MAX_KNOWN_GATE_INDEX <<- 0L
  invisible(TRUE)
}

nr_positive_gate_gap <- function(n) {
  r <- nr_sauce(FOUNDATION_DAY, bi_add_i(FOUNDATION_DAY, n))
  stream <- nr_ask_bowl(r, 1L, SEAL_GATE_GAP)
  41L + as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(922L))))
}

nr_negative_gate_gap <- function(n) {
  r <- nr_sauce(FOUNDATION_DAY, bi_sub_i(FOUNDATION_DAY, n))
  stream <- nr_ask_bowl(r, 1L, SEAL_GATE_GAP)
  41L + as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(922L))))
}

nr_ensure_gate_index <- function(k) {
  if (k > NR_MAX_KNOWN_GATE_INDEX) {
    n <- NR_MAX_KNOWN_GATE_INDEX + 1L
    while (n <= k) {
      nr_gate_set(n, bi_add_i(nr_gate_get(n - 1L), nr_positive_gate_gap(n)))
      NR_MAX_KNOWN_GATE_INDEX <<- n
      n <- n + 1L
    }
  }
  if (k < NR_MIN_KNOWN_GATE_INDEX) {
    n <- NR_MIN_KNOWN_GATE_INDEX - 1L
    while (n >= k) {
      nr_gate_set(n, bi_sub_i(nr_gate_get(n + 1L), nr_negative_gate_gap(abs(n))))
      NR_MIN_KNOWN_GATE_INDEX <<- n
      n <- n - 1L
    }
  }
  nr_gate_get(k)
}

nr_ensure_gates_cover <- function(lowDay, highDay) {
  lowDay <- as_bi(lowDay); highDay <- as_bi(highDay)
  if (bi_gt(lowDay, highDay)) stop('L\'interval de cobertura de portes és invers.')
  while (bi_gt(nr_gate_get(NR_MIN_KNOWN_GATE_INDEX), lowDay)) nr_ensure_gate_index(NR_MIN_KNOWN_GATE_INDEX - 1L)
  while (bi_lt(nr_gate_get(NR_MAX_KNOWN_GATE_INDEX), highDay)) nr_ensure_gate_index(NR_MAX_KNOWN_GATE_INDEX + 1L)
  invisible(TRUE)
}

nr_gate_index_at_or_before <- function(day) {
  day <- as_bi(day)
  nr_ensure_gates_cover(day, day)
  lo <- NR_MIN_KNOWN_GATE_INDEX
  hi <- NR_MAX_KNOWN_GATE_INDEX
  while (lo < hi) {
    mid <- lo + (hi - lo + 1L) %/% 2L
    if (bi_le(nr_gate_get(mid), day)) lo <- mid else hi <- mid - 1L
  }
  lo
}

nr_gate_index_at_or_after <- function(day) {
  i <- nr_gate_index_at_or_before(day)
  if (bi_eq(nr_gate_get(i), day)) return(i)
  nr_ensure_gate_index(i + 1L)
  i + 1L
}

nr_exact_gate_index <- function(day) {
  i <- nr_gate_index_at_or_before(day)
  if (bi_eq(nr_gate_get(i), day)) i else NULL
}

nr_year_length <- function(openIndex, closeIndex) bi_sub(nr_gate_get(closeIndex), nr_gate_get(openIndex))

nr_valid_year_pair <- function(openIndex, closeIndex) {
  if (closeIndex - openIndex < 6L) return(FALSE)
  L <- nr_year_length(openIndex, closeIndex)
  bi_ge(L, bi_from_int(YEAR_MIN_DAYS)) && bi_le(L, bi_from_int(YEAR_MAX_DAYS))
}

nr_make_year <- function(number, openIndex, closeIndex) {
  list(
    number = as_bi(number),
    openGateIndex = openIndex,
    closeGateIndex = closeIndex,
    openGateDay = nr_gate_get(openIndex),
    closeGateDay = nr_gate_get(closeIndex)
  )
}

nr_insert_sorted_year5000 <- function(sorted, candidate) {
  if (length(sorted) == 0L) return(list(candidate))
  pos <- length(sorted) + 1L
  for (i in seq_along(sorted)) {
    c1 <- bi_cmp(candidate$length, sorted[[i]]$length)
    if (c1 < 0L || (c1 == 0L && bi_lt(candidate$openDay, sorted[[i]]$openDay))) {
      pos <- i
      break
    }
  }
  append(sorted, list(candidate), after = pos - 1L)
}

nr_year5000 <- function(calculationDay) {
  cDay <- as_bi(calculationDay)
  nr_ensure_gates_cover(bi_sub_i(cDay, YEAR_MAX_DAYS), bi_add_i(cDay, YEAR_MAX_DAYS))
  candidates <- list()
  if (NR_MAX_KNOWN_GATE_INDEX - NR_MIN_KNOWN_GATE_INDEX >= 6L) {
    for (i in NR_MIN_KNOWN_GATE_INDEX:(NR_MAX_KNOWN_GATE_INDEX - 1L)) {
      startJ <- i + 6L
      if (startJ > NR_MAX_KNOWN_GATE_INDEX) next
      for (j in startJ:NR_MAX_KNOWN_GATE_INDEX) {
        if (!nr_valid_year_pair(i, j)) next
        if (!(bi_lt(nr_gate_get(i), cDay) && bi_le(cDay, nr_gate_get(j)))) next
        candidate <- list(open = i, close = j, length = nr_year_length(i, j), openDay = nr_gate_get(i))
        candidates <- nr_insert_sorted_year5000(candidates, candidate)
      }
    }
  }
  if (length(candidates) == 0L) stop('No s\'ha trobat cap candidat per a l\'any 5000.')
  r <- nr_sauce(cDay, cDay)
  stream <- nr_ask_bowl(r, 1L, SEAL_YEAR_5000)
  rank <- as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(length(candidates)))))
  chosen <- candidates[[rank]]
  nr_make_year(bi_from_int(5000L), chosen$open, chosen$close)
}

nr_next_year <- function(calculationDay, knownYear) {
  cDay <- as_bi(calculationDay)
  openIndex <- knownYear$closeGateIndex
  nr_ensure_gates_cover(nr_gate_get(openIndex), bi_add_i(nr_gate_get(openIndex), YEAR_MAX_DAYS))
  candidates <- integer()
  closeIndex <- openIndex + 1L
  repeat {
    nr_ensure_gate_index(closeIndex)
    if (bi_gt(nr_year_length(openIndex, closeIndex), bi_from_int(YEAR_MAX_DAYS))) break
    if (nr_valid_year_pair(openIndex, closeIndex)) candidates <- c(candidates, closeIndex)
    closeIndex <- closeIndex + 1L
  }
  if (length(candidates) == 0L) stop('No hi ha cap candidat per a l\'any següent.')
  r <- nr_sauce(cDay, nr_gate_get(openIndex))
  stream <- nr_ask_bowl(r, 1L, SEAL_NEXT_YEAR)
  rank <- as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(length(candidates)))))
  closeIndex <- candidates[[rank]]
  nr_make_year(bi_add_i(knownYear$number, 1L), openIndex, closeIndex)
}

nr_previous_year <- function(calculationDay, knownYear) {
  cDay <- as_bi(calculationDay)
  closeIndex <- knownYear$openGateIndex
  nr_ensure_gates_cover(bi_sub_i(nr_gate_get(closeIndex), YEAR_MAX_DAYS), nr_gate_get(closeIndex))
  candidates <- integer()
  openIndex <- closeIndex - 1L
  repeat {
    nr_ensure_gate_index(openIndex)
    if (bi_gt(nr_year_length(openIndex, closeIndex), bi_from_int(YEAR_MAX_DAYS))) break
    if (nr_valid_year_pair(openIndex, closeIndex)) candidates <- c(candidates, openIndex)
    openIndex <- openIndex - 1L
  }
  if (length(candidates) == 0L) stop('No hi ha cap candidat per a l\'any anterior.')
  lengths <- lapply(candidates, function(i) nr_year_length(i, closeIndex))
  ordered <- integer()
  for (idx in seq_along(candidates)) {
    candidate <- candidates[[idx]]
    if (length(ordered) == 0L) ordered <- candidate else {
      pos <- length(ordered) + 1L
      for (p in seq_along(ordered)) {
        if (bi_lt(nr_year_length(candidate, closeIndex), nr_year_length(ordered[[p]], closeIndex))) { pos <- p; break }
      }
      ordered <- append(ordered, candidate, after = pos - 1L)
    }
  }
  r <- nr_sauce(cDay, nr_gate_get(closeIndex))
  stream <- nr_ask_bowl(r, 1L, SEAL_PREVIOUS_YEAR)
  rank <- as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(length(ordered)))))
  openIndex <- ordered[[rank]]
  nr_make_year(bi_sub_i(knownYear$number, 1L), openIndex, closeIndex)
}

nr_find_target_year <- function(calculationDay, targetDay) {
  cDay <- as_bi(calculationDay); tDay <- as_bi(targetDay)
  y <- nr_year5000(cDay)
  while (bi_gt(tDay, y$closeGateDay)) y <- nr_next_year(cDay, y)
  while (bi_le(tDay, y$openGateDay)) y <- nr_previous_year(cDay, y)
  if (!(bi_lt(y$openGateDay, tDay) && bi_le(tDay, y$closeGateDay))) stop('La pertinença del dia a l\'any viola l\'interval (obert, tancat].')
  y
}

nr_choose_cutlet_count <- function(structureSauce, year) {
  gaps <- year$closeGateIndex - year$openGateIndex
  candidates <- 6:min(17L, gaps)
  stream <- nr_ask_bowl(structureSauce, 2L, SEAL_CUTLET_COUNT)
  rank <- as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(length(candidates)))))
  candidates[[rank]]
}

nr_choose_cutlet_partition <- function(calculationDay, structureSauce, year, cutletCount) {
  G <- year$closeGateIndex - year$openGateIndex
  g <- nr_exact_gate_index(calculationDay)
  required <- NULL
  if (!is.null(g) && year$openGateIndex < g && g < year$closeGateIndex) required <- g - year$openGateIndex
  family <- nr_make_cutlet_partition_family(G, cutletCount, required)
  stream <- nr_ask_bowl(structureSauce, 2L, SEAL_CUTLET_PARTITION)
  family$unrank1(nr_choose_rank(stream, family$count()))
}

nr_choose_cutlet_names <- function(structureSauce, cutletCount) {
  N <- nr_falling_factorial(17L, cutletCount)
  stream <- nr_ask_bowl(structureSauce, 5L, SEAL_CUTLET_NAMES)
  nr_unrank_distinct_indices(17L, cutletCount, nr_choose_rank(stream, N))
}

nr_materialize_cutlets <- function(year, partition, nameIndices) {
  cursorGate <- year$openGateIndex
  out <- vector('list', length(partition))
  for (k in seq_along(partition)) {
    openGateIndex <- cursorGate
    closeGateIndex <- cursorGate + partition[[k]]
    out[[k]] <- list(
      canonicalNameIndex = nameIndices[[k]],
      openGateIndex = openGateIndex,
      closeGateIndex = closeGateIndex,
      firstDay = bi_add_i(nr_gate_get(openGateIndex), 1L),
      lastDay = nr_gate_get(closeGateIndex)
    )
    cursorGate <- closeGateIndex
  }
  out
}

nr_choose_month_count <- function(structureSauce, year) {
  L <- as.integer(bi_to_small_integer(bi_sub(year$closeGateDay, year$openGateDay)))
  minMonths <- (L + 122L) %/% 123L
  maxMonths <- min(47L, L %/% 4L)
  if (!(3L <= minMonths && minMonths <= maxMonths && maxMonths <= 47L)) stop('Els límits del nombre de mesos són incoherents.')
  candidates <- minMonths:maxMonths
  stream <- nr_ask_bowl(structureSauce, 3L, SEAL_MONTH_COUNT)
  rank <- as.integer(bi_to_small_integer(nr_choose_rank(stream, bi_from_int(length(candidates)))))
  candidates[[rank]]
}

nr_choose_month_lengths <- function(structureSauce, year, monthCount) {
  L <- as.integer(bi_to_small_integer(bi_sub(year$closeGateDay, year$openGateDay)))
  family <- nr_make_bounded_composition_family(L, monthCount, 4L, 123L)
  stream <- nr_ask_bowl(structureSauce, 3L, SEAL_MONTH_LENGTHS)
  family$unrank1(nr_choose_rank(stream, family$count()))
}

nr_choose_month_weaving <- function(structureSauce, monthLengths) {
  family <- nr_make_weaving_family(monthLengths)
  stream <- nr_ask_bowl(structureSauce, 4L, SEAL_MONTH_WEAVING)
  family$unrank1(nr_choose_rank(stream, family$count()))
}

nr_choose_month_names <- function(structureSauce, monthCount) {
  N <- nr_falling_factorial(47L, monthCount)
  stream <- nr_ask_bowl(structureSauce, 5L, SEAL_MONTH_NAMES)
  nr_unrank_distinct_indices(47L, monthCount, nr_choose_rank(stream, N))
}

nr_build_year_structure <- function(calculationDay, year) {
  firstDay <- bi_add_i(year$openGateDay, 1L)
  r <- nr_sauce(calculationDay, firstDay)
  cutletCount <- nr_choose_cutlet_count(r, year)
  cutletPartition <- nr_choose_cutlet_partition(calculationDay, r, year, cutletCount)
  cutletNames <- nr_choose_cutlet_names(r, cutletCount)
  cutlets <- nr_materialize_cutlets(year, cutletPartition, cutletNames)
  monthCount <- nr_choose_month_count(r, year)
  monthLengths <- nr_choose_month_lengths(r, year, monthCount)
  monthWeaving <- nr_choose_month_weaving(r, monthLengths)
  monthNames <- nr_choose_month_names(r, monthCount)
  list(
    cutletCount = cutletCount,
    cutletPartition = cutletPartition,
    cutletNames = cutletNames,
    cutlets = cutlets,
    monthCount = monthCount,
    monthLengths = monthLengths,
    monthWeaving = monthWeaving,
    monthNames = monthNames
  )
}

nr_calendar_date_indices <- function(calculationDay, targetDay) {
  cDay <- as_bi(calculationDay); tDay <- as_bi(targetDay)
  year <- nr_find_target_year(cDay, tDay)
  structure <- nr_build_year_structure(cDay, year)
  chosenCutletId <- NULL
  for (i in seq_along(structure$cutlets)) {
    c <- structure$cutlets[[i]]
    if (bi_le(c$firstDay, tDay) && bi_le(tDay, c$lastDay)) { chosenCutletId <- i; break }
  }
  if (is.null(chosenCutletId)) stop('Cap mandonguilla no conté el dia consultat.')
  chosenCutlet <- structure$cutlets[[chosenCutletId]]
  dayInCutlet <- bi_add_i(bi_sub(tDay, chosenCutlet$firstDay), 1L)
  yearOffset0 <- as.integer(bi_to_small_integer(bi_sub(tDay, bi_add_i(year$openGateDay, 1L))))
  monthId <- structure$monthWeaving[[yearOffset0 + 1L]]
  dayInMonth <- 0L
  for (p in seq_len(yearOffset0 + 1L)) if (structure$monthWeaving[[p]] == monthId) dayInMonth <- dayInMonth + 1L
  list(
    yearNumber = year$number,
    cutletCanonicalIndex = structure$cutletNames[[chosenCutletId]],
    dayInCutlet = dayInCutlet,
    monthCanonicalIndex = structure$monthNames[[monthId]],
    dayInMonth = bi_from_int(dayInMonth)
  )
}

normative_calendar_date <- function(calculationDay, targetDay) {
  x <- nr_calendar_date_indices(calculationDay, targetDay)
  list(
    yearNumber = bi_to_string(x$yearNumber),
    cutletName = cutlet_name_by_index(x$cutletCanonicalIndex),
    dayInCutlet = bi_to_string(x$dayInCutlet),
    monthName = month_name_by_index(x$monthCanonicalIndex),
    dayInMonth = bi_to_string(x$dayInMonth)
  )
}
