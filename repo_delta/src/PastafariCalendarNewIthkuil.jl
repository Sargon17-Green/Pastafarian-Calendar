module PastafariCalendarNewIthkuil

include("catalog/SourceLanguageCatalog.jl")
include("bootstrap/MonsterBase.jl")

export SourceNameEntry,
       SourceLanguageCatalogIncompleteError,
       SOURCE_LANGUAGE_CATALOG_VERSION,
       SOURCE_LANGUAGE_CODE,
       SOURCE_LANGUAGE_CATALOG_STATE,
       CUTLET_SOURCE_CATALOG,
       MONTH_SOURCE_CATALOG,
       cutletSourceName,
       monthSourceName,
       MonsterContext,
       MonsterManager,
       StageIncompleteError,
       calendarDateSpaghetti

end
