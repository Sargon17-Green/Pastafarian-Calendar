SOURCE_LANGUAGE_CATALOG_VERSION <- '1.0.0-stage01-frozen'

CUTLET_SOURCE_CATALOG <- data.frame(
  canonicalIndex = 1:17,
  text = c(
    'bronze', 'guineu', 'ronyó', 'Lagaix', 'pensament', 'quatre parts de nou',
    'Palguraix', 'jonc', 'ramell', 'escorpí', 'cendra', 'blat', 'riu',
    'riure', 'Accad', 'banya', 'la gerra buida'
  ),
  stringsAsFactors = FALSE
)

MONTH_SOURCE_CATALOG <- data.frame(
  canonicalIndex = 1:47,
  text = c(
    'argila', 'magrana', 'colze', 'enveja', 'Èridu', 'pasta de dents',
    'tres parts de cinc', 'Karxumab', 'tigre', 'estany', 'boira', 'encens',
    'fus', 'costella', 'garrofa', 'Uruk', 'vergonya', 'camell', 'coure',
    'pou', 'rovell', 'estrella', 'mel', 'melsa', 'pedra calcària', 'alegria',
    'figa', 'Nínive', 'granota', 'quitrà', 'espelma', 'la porta tancada',
    'sèsam', 'clatell', 'plata', 'lliri', 'tempesta', 'ase', 'farina',
    'penediment', 'Babilònia', 'llengua', 'lli', 'sal', 'pera', 'arc', 'sorra'
  ),
  stringsAsFactors = FALSE
)

source_catalog_validate <- function() {
  if (!identical(CUTLET_SOURCE_CATALOG$canonicalIndex, 1:17)) stop('Els índexs canònics de les mandonguilles no són exactes.')
  if (!identical(MONTH_SOURCE_CATALOG$canonicalIndex, 1:47)) stop('Els índexs canònics dels mesos no són exactes.')
  if (anyDuplicated(CUTLET_SOURCE_CATALOG$canonicalIndex)) stop('Hi ha un índex canònic de mandonguilla duplicat.')
  if (anyDuplicated(MONTH_SOURCE_CATALOG$canonicalIndex)) stop('Hi ha un índex canònic de mes duplicat.')
  if (any(!nzchar(CUTLET_SOURCE_CATALOG$text))) stop('Hi ha un nom de mandonguilla buit.')
  if (any(!nzchar(MONTH_SOURCE_CATALOG$text))) stop('Hi ha un nom de mes buit.')
  TRUE
}

cutlet_name_by_index <- function(index) {
  if (length(index) != 1L || typeof(index) != "integer" || is.na(index) || index < 1L || index > 17L) stop("Índex canònic de mandonguilla fora de rang.")
  CUTLET_SOURCE_CATALOG$text[[index]]
}

month_name_by_index <- function(index) {
  if (length(index) != 1L || typeof(index) != "integer" || is.na(index) || index < 1L || index > 47L) stop("Índex canònic de mes fora de rang.")
  MONTH_SOURCE_CATALOG$text[[index]]
}

source_catalog_validate()
