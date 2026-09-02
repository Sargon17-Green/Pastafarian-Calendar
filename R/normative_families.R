nr_falling_factorial <- function(n, k) {
  if (k < 0L || k > n) return(bi_zero())
  out <- bi_one()
  if (k == 0L) return(out)
  for (j in 0L:(k - 1L)) out <- bi_mul_i(out, n - j)
  out
}

nr_unrank_distinct_indices <- function(masterSize, k, rank1) {
  remaining <- seq_len(masterSize)
  out <- integer()
  r <- as_bi(rank1)
  for (position in seq_len(k)) {
    suffixLength <- k - position
    block <- nr_falling_factorial(length(remaining) - 1L, suffixLength)
    chosen <- NA_integer_
    for (candidatePos in seq_along(remaining)) {
      if (bi_gt(r, block)) {
        r <- bi_sub(r, block)
      } else {
        chosen <- candidatePos
        break
      }
    }
    if (is.na(chosen)) stop('La desclassificació de noms ha excedit la família.')
    out <- c(out, remaining[[chosen]])
    remaining <- remaining[-chosen]
  }
  out
}

nr_make_bounded_composition_family <- function(total, slots, lo, hi) {
  memo <- new.env(parent = emptyenv(), hash = TRUE)
  count_suffix <- function(rem, k) {
    if (k == 0L) return(if (rem == 0L) bi_one() else bi_zero())
    if (rem < k * lo || rem > k * hi) return(bi_zero())
    key <- paste(rem, k, sep = ':')
    if (exists(key, envir = memo, inherits = FALSE)) return(get(key, envir = memo, inherits = FALSE))
    s <- bi_zero()
    for (x in lo:hi) s <- bi_add(s, count_suffix(rem - x, k - 1L))
    assign(key, s, envir = memo)
    s
  }
  count_all <- function() count_suffix(total, slots)
  unrank1 <- function(rank1) {
    r <- as_bi(rank1)
    totalCount <- count_all()
    if (bi_lt(r, bi_one()) || bi_gt(r, totalCount)) stop('Rang de composició fora de la família.')
    rem <- total
    out <- integer()
    for (position in seq_len(slots)) {
      found <- FALSE
      for (x in lo:hi) {
        block <- count_suffix(rem - x, slots - position)
        if (bi_gt(r, block)) {
          r <- bi_sub(r, block)
        } else {
          out <- c(out, x)
          rem <- rem - x
          found <- TRUE
          break
        }
      }
      if (!found) stop('No s\'ha pogut desclassificar la composició acotada.')
    }
    out
  }
  list(count = count_all, unrank1 = unrank1)
}

nr_make_cutlet_partition_family <- function(G, K, requiredBoundary = NULL) {
  memo <- new.env(parent = emptyenv(), hash = TRUE)
  count_state <- function(rem, slots, cumulative, hitBoundary) {
    if (slots == 0L) {
      if (rem != 0L) return(bi_zero())
      if (is.null(requiredBoundary)) return(bi_one())
      return(if (hitBoundary) bi_one() else bi_zero())
    }
    if (rem < slots) return(bi_zero())
    key <- paste(rem, slots, cumulative, as.integer(hitBoundary), sep = ':')
    if (exists(key, envir = memo, inherits = FALSE)) return(get(key, envir = memo, inherits = FALSE))
    total <- bi_zero()
    maxX <- rem - (slots - 1L)
    for (x in seq_len(maxX)) {
      nextCumulative <- cumulative + x
      nextHit <- hitBoundary
      if (!is.null(requiredBoundary) && !hitBoundary) {
        if (nextCumulative == requiredBoundary) nextHit <- TRUE
        else if (nextCumulative > requiredBoundary) next
      }
      total <- bi_add(total, count_state(rem - x, slots - 1L, nextCumulative, nextHit))
    }
    assign(key, total, envir = memo)
    total
  }
  count_all <- function() count_state(G, K, 0L, FALSE)
  unrank1 <- function(rank1) {
    r <- as_bi(rank1)
    total <- count_all()
    if (bi_lt(r, bi_one()) || bi_gt(r, total)) stop('Rang de partició de mandonguilles fora de la família.')
    rem <- G
    slots <- K
    cumulative <- 0L
    hit <- FALSE
    out <- integer()
    while (slots > 0L) {
      maxX <- rem - (slots - 1L)
      found <- FALSE
      for (x in seq_len(maxX)) {
        nextCumulative <- cumulative + x
        nextHit <- hit
        if (!is.null(requiredBoundary) && !hit) {
          if (nextCumulative == requiredBoundary) nextHit <- TRUE
          else if (nextCumulative > requiredBoundary) next
        }
        block <- count_state(rem - x, slots - 1L, nextCumulative, nextHit)
        if (bi_gt(r, block)) {
          r <- bi_sub(r, block)
        } else {
          out <- c(out, x)
          rem <- rem - x
          slots <- slots - 1L
          cumulative <- nextCumulative
          hit <- nextHit
          found <- TRUE
          break
        }
      }
      if (!found) stop('No s\'ha pogut desclassificar la partició de mandonguilles.')
    }
    out
  }
  list(count = count_all, unrank1 = unrank1)
}

nr_make_weaving_family <- function(lengths) {
  m <- length(lengths)
  memo <- new.env(parent = emptyenv(), hash = TRUE)
  state_key <- function(remaining, openedUpTo, closedUpTo) paste(c(remaining, openedUpTo, closedUpTo), collapse = ',')
  legal_move <- function(remaining, openedUpTo, closedUpTo, j) {
    if (remaining[[j]] == 0L) return(FALSE)
    alreadyOpened <- remaining[[j]] < lengths[[j]]
    if (!alreadyOpened && j != openedUpTo + 1L) return(FALSE)
    willClose <- remaining[[j]] == 1L
    if (willClose && j != closedUpTo + 1L) return(FALSE)
    TRUE
  }
  apply_move <- function(remaining, openedUpTo, closedUpTo, j) {
    if (remaining[[j]] == lengths[[j]]) openedUpTo <- j
    remaining[[j]] <- remaining[[j]] - 1L
    if (remaining[[j]] == 0L) closedUpTo <- j
    list(remaining = remaining, openedUpTo = openedUpTo, closedUpTo = closedUpTo)
  }
  count_state <- function(remaining, openedUpTo, closedUpTo) {
    if (all(remaining == 0L)) return(bi_one())
    key <- state_key(remaining, openedUpTo, closedUpTo)
    if (exists(key, envir = memo, inherits = FALSE)) return(get(key, envir = memo, inherits = FALSE))
    total <- bi_zero()
    for (j in seq_len(m)) {
      if (!legal_move(remaining, openedUpTo, closedUpTo, j)) next
      nextState <- apply_move(remaining, openedUpTo, closedUpTo, j)
      total <- bi_add(total, count_state(nextState$remaining, nextState$openedUpTo, nextState$closedUpTo))
    }
    assign(key, total, envir = memo)
    total
  }
  count_all <- function() count_state(lengths, 0L, 0L)
  unrank1 <- function(rank1) {
    r <- as_bi(rank1)
    total <- count_all()
    if (bi_lt(r, bi_one()) || bi_gt(r, total)) stop('Rang de teixit fora de la família.')
    remaining <- lengths
    openedUpTo <- 0L
    closedUpTo <- 0L
    out <- integer()
    while (length(out) < sum(lengths)) {
      found <- FALSE
      for (j in seq_len(m)) {
        if (!legal_move(remaining, openedUpTo, closedUpTo, j)) next
        nextState <- apply_move(remaining, openedUpTo, closedUpTo, j)
        block <- count_state(nextState$remaining, nextState$openedUpTo, nextState$closedUpTo)
        if (bi_gt(r, block)) {
          r <- bi_sub(r, block)
        } else {
          out <- c(out, j)
          remaining <- nextState$remaining
          openedUpTo <- nextState$openedUpTo
          closedUpTo <- nextState$closedUpTo
          found <- TRUE
          break
        }
      }
      if (!found) stop('No s\'ha pogut desclassificar el teixit.')
    }
    out
  }
  list(count = count_all, unrank1 = unrank1)
}
