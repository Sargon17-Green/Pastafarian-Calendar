args <- commandArgs(trailingOnly = FALSE)
fileArg <- args[grepl('^--file=', args)]
scriptPath <- if (length(fileArg)) sub('^--file=', '', fileArg[[1L]]) else 'tests/run_tests.R'
root <- normalizePath(file.path(dirname(scriptPath), '..'), winslash = '/', mustWork = TRUE)

source(file.path(root, 'R', 'bigint.R'), local = FALSE)
source(file.path(root, 'R', 'source_language_catalog.R'), local = FALSE)
source(file.path(root, 'R', 'bootstrap_monster.R'), local = FALSE)
source(file.path(root, 'R', 'normative_core.R'), local = FALSE)
source(file.path(root, 'R', 'normative_families.R'), local = FALSE)
source(file.path(root, 'R', 'normative_calendar.R'), local = FALSE)
source(file.path(root, 'tests', 'test_stage01.R'), local = FALSE)

cat('Inici de les proves de Stage 1\n')
ok <- run_stage01_tests(root)
if (!isTRUE(ok)) stop('Les proves de Stage 1 no han acabat correctament.')
cat('STAGE_01_TESTS=PASS\n')
