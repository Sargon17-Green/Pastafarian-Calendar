args <- commandArgs(trailingOnly = FALSE)
fileArg <- args[grepl('^--file=', args)]
scriptPath <- if (length(fileArg)) sub('^--file=', '', fileArg[[1L]]) else 'tests/oracle_smoke.R'
root <- normalizePath(file.path(dirname(scriptPath), '..'), winslash = '/', mustWork = TRUE)
source(file.path(root, 'R', 'bigint.R'), local = FALSE)
source(file.path(root, 'R', 'source_language_catalog.R'), local = FALSE)
source(file.path(root, 'R', 'normative_core.R'), local = FALSE)
source(file.path(root, 'R', 'normative_families.R'), local = FALSE)
source(file.path(root, 'R', 'normative_calendar.R'), local = FALSE)

r1 <- nr_sauce(FOUNDATION_DAY, FOUNDATION_DAY)
r2 <- nr_sauce(FOUNDATION_DAY, FOUNDATION_DAY)
if (!identical(vapply(r1$bowls, bi_to_string, character(1L)), vapply(r2$bowls, bi_to_string, character(1L)))) stop('El fum de l\'oracle ha detectat una salsa no determinista.')
if (!identical(r1$orderAtDrop46, r2$orderAtDrop46)) stop('El fum de l\'oracle ha detectat un ordre no determinista.')
if (length(r1$bowls) != 6L || length(r1$orderAtDrop46) != 6L) stop('La salsa no conté sis bols i un ordre de sis posicions.')
cat('STAGE_01_ORACLE_SMOKE=PASS\n')
