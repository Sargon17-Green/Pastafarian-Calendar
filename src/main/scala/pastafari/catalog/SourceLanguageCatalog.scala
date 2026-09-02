package pastafari.catalog

final case class CanonicalName(canonicalIndex: Int, italian: String)

object SourceLanguageCatalog {
  val Version: String = "1.0.0-stage01"

  val Cutlets: Vector[CanonicalName] = Vector(
    CanonicalName(1, "bronzo"),
    CanonicalName(2, "volpe"),
    CanonicalName(3, "rene"),
    CanonicalName(4, "larice"),
    CanonicalName(5, "pensiero"),
    CanonicalName(6, "quattro noni"),
    CanonicalName(7, "Palgurash"),
    CanonicalName(8, "papiro"),
    CanonicalName(9, "grappolo"),
    CanonicalName(10, "scorpione"),
    CanonicalName(11, "cenere"),
    CanonicalName(12, "frumento"),
    CanonicalName(13, "fiume"),
    CanonicalName(14, "risata"),
    CanonicalName(15, "Akkad"),
    CanonicalName(16, "corno"),
    CanonicalName(17, "la brocca vuota")
  )

  val Months: Vector[CanonicalName] = Vector(
    CanonicalName(1, "argilla"),
    CanonicalName(2, "melagrana"),
    CanonicalName(3, "gomito"),
    CanonicalName(4, "gelosia"),
    CanonicalName(5, "Eridu"),
    CanonicalName(6, "dentifricio"),
    CanonicalName(7, "tre quinti"),
    CanonicalName(8, "Karshumab"),
    CanonicalName(9, "leopardo"),
    CanonicalName(10, "stagno"),
    CanonicalName(11, "nebbia"),
    CanonicalName(12, "olibano"),
    CanonicalName(13, "fuso"),
    CanonicalName(14, "costola"),
    CanonicalName(15, "carruba"),
    CanonicalName(16, "Uruk"),
    CanonicalName(17, "vergogna"),
    CanonicalName(18, "cammello"),
    CanonicalName(19, "rame"),
    CanonicalName(20, "pozzo"),
    CanonicalName(21, "tuorlo"),
    CanonicalName(22, "stella"),
    CanonicalName(23, "miele"),
    CanonicalName(24, "milza"),
    CanonicalName(25, "calcare"),
    CanonicalName(26, "gioia"),
    CanonicalName(27, "fico"),
    CanonicalName(28, "Ninive"),
    CanonicalName(29, "rana"),
    CanonicalName(30, "bitume"),
    CanonicalName(31, "candela"),
    CanonicalName(32, "la porta chiusa"),
    CanonicalName(33, "sesamo"),
    CanonicalName(34, "nuca"),
    CanonicalName(35, "argento"),
    CanonicalName(36, "giglio"),
    CanonicalName(37, "tempesta"),
    CanonicalName(38, "asino"),
    CanonicalName(39, "farina"),
    CanonicalName(40, "rimorso"),
    CanonicalName(41, "Babilonia"),
    CanonicalName(42, "lingua"),
    CanonicalName(43, "lino"),
    CanonicalName(44, "sale"),
    CanonicalName(45, "pera"),
    CanonicalName(46, "arco"),
    CanonicalName(47, "sabbia")
  )

  private val cutletByIndex: Map[Int, CanonicalName] = Cutlets.map(x => x.canonicalIndex -> x).toMap
  private val monthByIndex: Map[Int, CanonicalName] = Months.map(x => x.canonicalIndex -> x).toMap

  def cutlet(index: Int): CanonicalName =
    cutletByIndex.getOrElse(index, throw new IllegalArgumentException("Indice canonico della cotoletta non valido: " + index))

  def month(index: Int): CanonicalName =
    monthByIndex.getOrElse(index, throw new IllegalArgumentException("Indice canonico del mese non valido: " + index))
}
