package pastafari

data class CanonicalName(val canonicalIndex: Int, val text: String)

class FrozenNameTable private constructor(private val entries: Array<out CanonicalName>) : AbstractList<CanonicalName>() {
    override val size: Int get() = entries.size
    override fun get(index: Int): CanonicalName = entries[index]

    companion object {
        fun of(vararg entries: CanonicalName): FrozenNameTable = FrozenNameTable(entries.copyOf())
    }
}

data class SourceLanguageCatalogData(
    val version: String,
    val cutlets: FrozenNameTable,
    val months: FrozenNameTable
)

object SourceLanguageCatalog {
    const val VERSION = "cy-1.0.0"

    val data: SourceLanguageCatalogData = SourceLanguageCatalogData(
        version = VERSION,
        cutlets = FrozenNameTable.of(
            CanonicalName(1, "efydd"),
            CanonicalName(2, "llwynog"),
            CanonicalName(3, "aren"),
            CanonicalName(4, "Lagash"),
            CanonicalName(5, "meddwl"),
            CanonicalName(6, "pedair rhan o naw"),
            CanonicalName(7, "Palgwrash"),
            CanonicalName(8, "hesgen"),
            CanonicalName(9, "clwstwr"),
            CanonicalName(10, "sgorpion"),
            CanonicalName(11, "lludw"),
            CanonicalName(12, "gwenith"),
            CanonicalName(13, "afon"),
            CanonicalName(14, "chwerthin"),
            CanonicalName(15, "Akkad"),
            CanonicalName(16, "corn"),
            CanonicalName(17, "y piser gwag")
        ),
        months = FrozenNameTable.of(
            CanonicalName(1, "mwd"),
            CanonicalName(2, "pomgranad"),
            CanonicalName(3, "penelin"),
            CanonicalName(4, "cenfigen"),
            CanonicalName(5, "Eridu"),
            CanonicalName(6, "past dannedd"),
            CanonicalName(7, "tair rhan o bump"),
            CanonicalName(8, "Carshwmab"),
            CanonicalName(9, "llewpard"),
            CanonicalName(10, "tun"),
            CanonicalName(11, "niwl"),
            CanonicalName(12, "thus"),
            CanonicalName(13, "gwerthyd"),
            CanonicalName(14, "asen"),
            CanonicalName(15, "carob"),
            CanonicalName(16, "Uruk"),
            CanonicalName(17, "cywilydd"),
            CanonicalName(18, "camel"),
            CanonicalName(19, "copr"),
            CanonicalName(20, "ffynnon"),
            CanonicalName(21, "melynwy"),
            CanonicalName(22, "seren"),
            CanonicalName(23, "mêl"),
            CanonicalName(24, "dueg"),
            CanonicalName(25, "calchfaen"),
            CanonicalName(26, "llawenydd"),
            CanonicalName(27, "ffigysen"),
            CanonicalName(28, "Ninefe"),
            CanonicalName(29, "broga"),
            CanonicalName(30, "tar"),
            CanonicalName(31, "cannwyll"),
            CanonicalName(32, "y drws caeedig"),
            CanonicalName(33, "sesame"),
            CanonicalName(34, "gwegil"),
            CanonicalName(35, "arian"),
            CanonicalName(36, "lili"),
            CanonicalName(37, "storm"),
            CanonicalName(38, "asyn"),
            CanonicalName(39, "blawd"),
            CanonicalName(40, "edifeirwch"),
            CanonicalName(41, "Babilon"),
            CanonicalName(42, "tafod"),
            CanonicalName(43, "llin"),
            CanonicalName(44, "halen"),
            CanonicalName(45, "gellygen"),
            CanonicalName(46, "bwa"),
            CanonicalName(47, "tywod")
        )
    )

    fun cutlet(index: Int): String = data.cutlets[index - 1].text
    fun month(index: Int): String = data.months[index - 1].text
}
