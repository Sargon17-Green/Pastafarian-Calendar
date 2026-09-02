BIG_BASE <- 10000L

bi_normalize <- function(x) {
  d <- x$d
  while (length(d) > 1L && d[[length(d)]] == 0) {
    d <- d[-length(d)]
  }
  s <- x$sign
  if (length(d) == 1L && d[[1L]] == 0) s <- 0L
  list(sign = as.integer(s), d = as.integer(d))
}

bi_zero <- function() list(sign = 0L, d = 0L)
bi_one <- function() list(sign = 1L, d = 1L)

bi_from_string <- function(s) {
  if (!is.character(s) || length(s) != 1L || !nzchar(s)) stop('S\'esperava un enter decimal no buit.')
  sign <- 1L
  if (substr(s, 1L, 1L) == '-') {
    sign <- -1L
    s <- substring(s, 2L)
  } else if (substr(s, 1L, 1L) == '+') {
    s <- substring(s, 2L)
  }
  if (!grepl('^[0-9]+$', s)) stop('L\'enter decimal conté caràcters no vàlids.')
  s <- sub('^0+', '', s)
  if (!nzchar(s)) return(bi_zero())
  parts <- character()
  end <- nchar(s)
  while (end > 0L) {
    start <- max(1L, end - 3L)
    parts <- c(parts, substr(s, start, end))
    end <- start - 1L
  }
  bi_normalize(list(sign = sign, d = as.integer(parts)))
}

bi_from_int <- function(n) {
  if (is.character(n)) return(bi_from_string(n))
  if (length(n) != 1L || typeof(n) != "integer" || is.na(n)) stop("S'esperava un enter de R o una cadena decimal.")
  bi_from_string(as.character(n))
}

as_bi <- function(x) {
  if (is.list(x) && !is.null(x$sign) && !is.null(x$d)) return(bi_normalize(x))
  bi_from_int(x)
}

bi_is_zero <- function(a) as_bi(a)$sign == 0L
bi_neg <- function(a) { a <- as_bi(a); a$sign <- -a$sign; a }
bi_abs <- function(a) { a <- as_bi(a); a$sign <- abs(a$sign); a }

bi_cmp_abs <- function(a, b) {
  a <- bi_abs(a); b <- bi_abs(b)
  if (length(a$d) < length(b$d)) return(-1L)
  if (length(a$d) > length(b$d)) return(1L)
  for (i in rev(seq_along(a$d))) {
    if (a$d[[i]] < b$d[[i]]) return(-1L)
    if (a$d[[i]] > b$d[[i]]) return(1L)
  }
  0L
}

bi_cmp <- function(a, b) {
  a <- as_bi(a); b <- as_bi(b)
  if (a$sign < b$sign) return(-1L)
  if (a$sign > b$sign) return(1L)
  if (a$sign == 0L) return(0L)
  c <- bi_cmp_abs(a, b)
  if (a$sign < 0L) -c else c
}

bi_eq <- function(a, b) bi_cmp(a, b) == 0L
bi_lt <- function(a, b) bi_cmp(a, b) < 0L
bi_le <- function(a, b) bi_cmp(a, b) <= 0L
bi_gt <- function(a, b) bi_cmp(a, b) > 0L
bi_ge <- function(a, b) bi_cmp(a, b) >= 0L

bi_add_abs <- function(a, b) {
  a <- bi_abs(a); b <- bi_abs(b)
  n <- max(length(a$d), length(b$d))
  out <- integer(n + 1L)
  carry <- 0L
  for (i in seq_len(n)) {
    av <- if (i <= length(a$d)) a$d[[i]] else 0L
    bv <- if (i <= length(b$d)) b$d[[i]] else 0L
    z <- av + bv + carry
    out[[i]] <- z %% BIG_BASE
    carry <- z %/% BIG_BASE
  }
  out[[n + 1L]] <- carry
  bi_normalize(list(sign = 1L, d = out))
}

bi_sub_abs <- function(a, b) {
  if (bi_cmp_abs(a, b) < 0L) stop('La resta absoluta exigeix a >= b.')
  a <- bi_abs(a); b <- bi_abs(b)
  out <- integer(length(a$d))
  borrow <- 0L
  for (i in seq_along(a$d)) {
    bv <- if (i <= length(b$d)) b$d[[i]] else 0L
    z <- a$d[[i]] - bv - borrow
    if (z < 0) {
      z <- z + BIG_BASE
      borrow <- 1L
    } else borrow <- 0L
    out[[i]] <- z
  }
  bi_normalize(list(sign = 1L, d = out))
}

bi_add <- function(a, b) {
  a <- as_bi(a); b <- as_bi(b)
  if (a$sign == 0L) return(b)
  if (b$sign == 0L) return(a)
  if (a$sign == b$sign) {
    z <- bi_add_abs(a, b); z$sign <- a$sign; return(z)
  }
  c <- bi_cmp_abs(a, b)
  if (c == 0L) return(bi_zero())
  if (c > 0L) {
    z <- bi_sub_abs(a, b); z$sign <- a$sign; return(z)
  }
  z <- bi_sub_abs(b, a); z$sign <- b$sign; z
}

bi_sub <- function(a, b) bi_add(a, bi_neg(b))

bi_mul_small_abs <- function(a, m) {
  a <- bi_abs(a)
  if (length(m) != 1L || typeof(m) != "integer" || is.na(m) || m < 0L || m >= BIG_BASE) stop('El multiplicador petit és fora de rang.')
  if (m == 0 || bi_is_zero(a)) return(bi_zero())
  out <- integer(length(a$d) + 1L)
  carry <- 0L
  for (i in seq_along(a$d)) {
    z <- a$d[[i]] * m + carry
    out[[i]] <- z %% BIG_BASE
    carry <- z %/% BIG_BASE
  }
  out[[length(out)]] <- carry
  bi_normalize(list(sign = 1L, d = out))
}

bi_mul <- function(a, b) {
  a <- as_bi(a); b <- as_bi(b)
  if (bi_is_zero(a) || bi_is_zero(b)) return(bi_zero())
  out <- integer(length(a$d) + length(b$d) + 1L)
  for (i in seq_along(a$d)) {
    carry <- 0L
    for (j in seq_along(b$d)) {
      k <- i + j - 1L
      z <- out[[k]] + a$d[[i]] * b$d[[j]] + carry
      out[[k]] <- z %% BIG_BASE
      carry <- z %/% BIG_BASE
    }
    k <- i + length(b$d)
    while (carry > 0) {
      z <- out[[k]] + carry
      out[[k]] <- z %% BIG_BASE
      carry <- z %/% BIG_BASE
      k <- k + 1L
    }
  }
  z <- bi_normalize(list(sign = a$sign * b$sign, d = out))
  z
}

bi_square <- function(a) bi_mul(a, a)

bi_shift_digits <- function(a, places) {
  a <- as_bi(a)
  if (bi_is_zero(a)) return(a)
  if (places < 0L) stop('El desplaçament de dígits no pot ser negatiu.')
  list(sign = a$sign, d = c(rep(0L, places), a$d))
}

bi_divmod_abs <- function(a, b) {
  a <- bi_abs(a); b <- bi_abs(b)
  if (bi_is_zero(b)) stop('Divisió per zero.')
  if (bi_cmp_abs(a, b) < 0L) return(list(q = bi_zero(), r = a))
  qd <- integer(length(a$d))
  r <- bi_zero()
  for (pos in rev(seq_along(a$d))) {
    r <- bi_shift_digits(r, 1L)
    r$d[[1L]] <- a$d[[pos]]
    r <- bi_normalize(r)
    lo <- 0L; hi <- BIG_BASE - 1L; best <- 0L
    while (lo <= hi) {
      mid <- (lo + hi) %/% 2L
      prod <- bi_mul_small_abs(b, mid)
      c <- bi_cmp_abs(prod, r)
      if (c <= 0L) {
        best <- mid
        lo <- mid + 1L
      } else hi <- mid - 1L
    }
    qd[[pos]] <- best
    if (best != 0L) r <- bi_sub_abs(r, bi_mul_small_abs(b, best))
  }
  list(q = bi_normalize(list(sign = 1L, d = qd)), r = bi_normalize(r))
}

bi_floor_divmod <- function(a, b) {
  a <- as_bi(a); b <- as_bi(b)
  if (b$sign <= 0L) stop('El divisor ha de ser estrictament positiu.')
  if (a$sign == 0L) return(list(q = bi_zero(), r = bi_zero()))
  dm <- bi_divmod_abs(a, b)
  if (a$sign > 0L) return(dm)
  if (bi_is_zero(dm$r)) {
    dm$q$sign <- -dm$q$sign
    return(dm)
  }
  list(q = bi_neg(bi_add(dm$q, bi_one())), r = bi_sub(b, dm$r))
}

bi_floor_div <- function(a, b) bi_floor_divmod(a, b)$q
bi_mod <- function(a, b) bi_floor_divmod(a, b)$r

bi_pow_small <- function(a, n) {
  if (length(n) != 1L || typeof(n) != "integer" || is.na(n) || n < 0L) stop('L\'exponent ha de ser un enter no negatiu.')
  base <- as_bi(a); out <- bi_one(); e <- n
  while (e > 0L) {
    if ((e %% 2L) == 1L) out <- bi_mul(out, base)
    e <- e %/% 2L
    if (e > 0L) base <- bi_square(base)
  }
  out
}

bi_to_string <- function(a) {
  a <- as_bi(a)
  if (a$sign == 0L) return('0')
  d <- rev(a$d)
  s <- as.character(as.integer(d[[1L]]))
  if (length(d) > 1L) {
    for (x in d[-1L]) s <- paste0(s, sprintf('%04d', as.integer(x)))
  }
  if (a$sign < 0L) paste0('-', s) else s
}

bi_to_small_integer <- function(a) {
  a <- as_bi(a)
  if (length(a$d) > 3L) stop("El valor no cap en un enter de R.")
  acc <- 0L
  for (pos in rev(seq_along(a$d))) {
    digit <- a$d[[pos]]
    if (acc > (2147483647L - digit) %/% BIG_BASE) stop("El valor no cap en un enter de R.")
    acc <- acc * BIG_BASE + digit
  }
  if (a$sign < 0L) -acc else acc
}

bi_sum <- function(xs) {
  out <- bi_zero()
  for (x in xs) out <- bi_add(out, x)
  out
}

bi_min <- function(a, b) if (bi_le(a, b)) as_bi(a) else as_bi(b)
bi_max <- function(a, b) if (bi_ge(a, b)) as_bi(a) else as_bi(b)
