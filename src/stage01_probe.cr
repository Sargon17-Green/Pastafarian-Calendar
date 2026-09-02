require "./pastafarian_calendar"

ctx = PastafarianCalendar.bootstrap_context(BigInt.new(1), BigInt.new(1))
puts ctx.status
puts PastafarianCalendar::SourceLanguageCatalog::CUTLETS.size
puts PastafarianCalendar::SourceLanguageCatalog::MONTHS.size
