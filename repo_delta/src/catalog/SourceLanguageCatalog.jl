const SOURCE_LANGUAGE_CATALOG_VERSION = v"0.1.0"
const SOURCE_LANGUAGE_CODE = :new_ithkuil
const SOURCE_LANGUAGE_CATALOG_STATE = :COMPLETE

struct SourceNameEntry
    canonicalIndex::Int
    sourceKey::Symbol
    text::Union{Nothing, String}
end

const CUTLET_SOURCE_CATALOG = (
    SourceNameEntry(1, :bronze, "aksvala amẓali’i ažprali’i"),
    SourceNameEntry(2, :fox, "ezvwala"),
    SourceNameEntry(3, :kidney, "epflala"),
    SourceNameEntry(4, :lagash, "lagaš"),
    SourceNameEntry(5, :thought, "aslela"),
    SourceNameEntry(6, :four_parts_of_nine, "apšala alẓilui"),
    SourceNameEntry(7, :palgurash, "palguraš"),
    SourceNameEntry(8, :papyrus, "eḑkyala"),
    SourceNameEntry(9, :cluster, "acyäla"),
    SourceNameEntry(10, :scorpion, "aggzaloubva"),
    SourceNameEntry(11, :ash, "ugçila ažxaloi"),
    SourceNameEntry(12, :wheat, "abtaleibva"),
    SourceNameEntry(13, :river, "elzala"),
    SourceNameEntry(14, :laughter, "ajwala"),
    SourceNameEntry(15, :akkad, "akkad"),
    SourceNameEntry(16, :horn, "unzgala"),
    SourceNameEntry(17, :empty_jug, "ašglila ešḑälä’ä"),
)

const MONTH_SOURCE_CATALOG = (
    SourceNameEntry(1, :mud, "andwaleuvsa"),
    SourceNameEntry(2, :pomegranate, "aňňpaleikca"),
    SourceNameEntry(3, :elbow, "hwecmala-aţřala"),
    SourceNameEntry(4, :envy, "ařřnala"),
    SourceNameEntry(5, :eridu, "eridu"),
    SourceNameEntry(6, :toothpaste, "egdräla adřalie"),
    SourceNameEntry(7, :three_parts_of_five, "azala astilui"),
    SourceNameEntry(8, :karshumab, "karšumab"),
    SourceNameEntry(9, :tiger, "arrwala"),
    SourceNameEntry(10, :tin, "ažprala"),
    SourceNameEntry(11, :fog, "hwekthaliá-ufthala"),
    SourceNameEntry(12, :frankincense, "uçplila aňsxwaloi"),
    SourceNameEntry(13, :spindle, "arpļalaičva"),
    SourceNameEntry(14, :rib, "olçflala"),
    SourceNameEntry(15, :carob, "ařtlaleikca"),
    SourceNameEntry(16, :uruk, "uruk"),
    SourceNameEntry(17, :shame, "avxwala"),
    SourceNameEntry(18, :camel, "oňļwala"),
    SourceNameEntry(19, :copper, "amẓala"),
    SourceNameEntry(20, :well, "eţrala"),
    SourceNameEntry(21, :yolk, "exwala aḑnwalei amlalä’ä"),
    SourceNameEntry(22, :star, "alxwala"),
    SourceNameEntry(23, :honey, "amnwala"),
    SourceNameEntry(24, :spleen, "upflala"),
    SourceNameEntry(25, :limestone, "agglala"),
    SourceNameEntry(26, :joy, "antrala"),
    SourceNameEntry(27, :fig, "ařçaleikca"),
    SourceNameEntry(28, :nineveh, "ninua"),
    SourceNameEntry(29, :frog, "anxlala"),
    SourceNameEntry(30, :pitch, "antçala"),
    SourceNameEntry(31, :candle, "ellwila amtçali’i"),
    SourceNameEntry(32, :closed_door, "apřaleigḑuňřa"),
    SourceNameEntry(33, :sesame, "ařžplala"),
    SourceNameEntry(34, :nape, "aňwaloukfa"),
    SourceNameEntry(35, :silver, "ařļala"),
    SourceNameEntry(36, :lily, "alswala"),
    SourceNameEntry(37, :storm, "efkhala"),
    SourceNameEntry(38, :donkey, "excala"),
    SourceNameEntry(39, :flour, "ačkwaliulksa"),
    SourceNameEntry(40, :regret, "azglala"),
    SourceNameEntry(41, :babylon, "babili"),
    SourceNameEntry(42, :tongue, "ankwala"),
    SourceNameEntry(43, :flax, "armçmala"),
    SourceNameEntry(44, :salt, "afdala"),
    SourceNameEntry(45, :pear, "unžaleikca"),
    SourceNameEntry(46, :bow, "ašxwala"),
    SourceNameEntry(47, :sand, "antfala"),
)

struct SourceLanguageCatalogIncompleteError <: Exception
    code::Symbol
    canonicalIndex::Int
end

function Base.showerror(io::IO, error::SourceLanguageCatalogIncompleteError)
    print(io, "SOURCE_LANGUAGE_CATALOG_INCOMPLETE:", error.code, ":", error.canonicalIndex)
end

function cutletSourceName(index::Integer)
    1 <= index <= length(CUTLET_SOURCE_CATALOG) || throw(BoundsError(CUTLET_SOURCE_CATALOG, index))
    entry = CUTLET_SOURCE_CATALOG[Int(index)]
    entry.text === nothing && throw(SourceLanguageCatalogIncompleteError(:CUTLET, Int(index)))
    return entry.text
end

function monthSourceName(index::Integer)
    1 <= index <= length(MONTH_SOURCE_CATALOG) || throw(BoundsError(MONTH_SOURCE_CATALOG, index))
    entry = MONTH_SOURCE_CATALOG[Int(index)]
    entry.text === nothing && throw(SourceLanguageCatalogIncompleteError(:MONTH, Int(index)))
    return entry.text
end
