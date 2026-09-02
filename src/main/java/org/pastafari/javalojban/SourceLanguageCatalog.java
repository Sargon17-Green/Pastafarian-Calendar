package org.pastafari.javalojban;

import java.util.List;

public final class SourceLanguageCatalog {
    public static final String VERSION = "1.0.0-stage01";

    public record Entry(int canonicalIndex, String sourceText) {}

    private static final List<Entry> CUTLETS = List.of(
        new Entry(1, "ransu"),
        new Entry(2, "lorxu"),
        new Entry(3, "lo rango poi se pilno lo nu vimcu lo festi lo xadni"),
        new Entry(4, "lo ckunu be la .lariks."),
        new Entry(5, "lo se pensi"),
        new Entry(6, "li vo fi'u so"),
        new Entry(7, ".palgurac."),
        new Entry(8, "lo clani srasu"),
        new Entry(9, "lo gunma"),
        new Entry(10, "lo jukni be la .skorpiones."),
        new Entry(11, "lo festi be lo fagri"),
        new Entry(12, "maxri"),
        new Entry(13, "rirxe"),
        new Entry(14, "lo nu cmila"),
        new Entry(15, ".akad."),
        new Entry(16, "jirna"),
        new Entry(17, "lo kunti kabri")
    );

    private static final List<Entry> MONTHS = List.of(
        new Entry(1, "kliti"),
        new Entry(2, "lo grute be lo spati be la .punikas.granatum."),
        new Entry(3, "lo jorne be lo birka"),
        new Entry(4, "lo nu jilra"),
        new Entry(5, ".eridus."),
        new Entry(6, "lo pesxu poi se pilno lo nu lumci lo denci"),
        new Entry(7, "li ci fi'u mu"),
        new Entry(8, ".karcumab."),
        new Entry(9, "tirxu"),
        new Entry(10, "tinci"),
        new Entry(11, "bumru"),
        new Entry(12, "lo panci marji be lo tricu be la .boswelias."),
        new Entry(13, "jendu"),
        new Entry(14, "lo greku pagbu"),
        new Entry(15, "lo grute be lo tricu be la .keratonias.silikuas."),
        new Entry(16, ".uruk."),
        new Entry(17, "lo nu ckeji"),
        new Entry(18, "kumte"),
        new Entry(19, "tunka"),
        new Entry(20, "jinto"),
        new Entry(21, "lo pelxu pagbu be lo sovda"),
        new Entry(22, "tarci"),
        new Entry(23, "lo titla se zbasu be lo bifce"),
        new Entry(24, "lo rango poi se zvati lo zunle be lo betfu"),
        new Entry(25, "lo rokci be la .kalsium.karbonat."),
        new Entry(26, "lo nu gleki"),
        new Entry(27, "figre"),
        new Entry(28, ".ninives."),
        new Entry(29, "lo banfi be la .anuras."),
        new Entry(30, "tarla"),
        new Entry(31, "lo fagri tergu'i"),
        new Entry(32, "lo ganlo vorme"),
        new Entry(33, "lo tsiju be lo spati be la .sesamum.indikum."),
        new Entry(34, "lo trixe be lo galxe"),
        new Entry(35, "rijno"),
        new Entry(36, "lelxe"),
        new Entry(37, "lo vlile tcima"),
        new Entry(38, "xasli"),
        new Entry(39, "lo purmo be lo maxri"),
        new Entry(40, "lo nu xenru"),
        new Entry(41, ".babilon."),
        new Entry(42, "tance"),
        new Entry(43, "matli"),
        new Entry(44, "silna"),
        new Entry(45, "perli"),
        new Entry(46, "bagyce'a"),
        new Entry(47, "canre")
    );

    private SourceLanguageCatalog() {}

    public static List<Entry> cutlets() {
        return CUTLETS;
    }

    public static List<Entry> months() {
        return MONTHS;
    }

    public static String cutletName(int canonicalIndex) {
        if (canonicalIndex < 1 || canonicalIndex > CUTLETS.size()) {
            throw new IllegalArgumentException("E_CUTLET_INDEX");
        }
        return CUTLETS.get(canonicalIndex - 1).sourceText();
    }

    public static String monthName(int canonicalIndex) {
        if (canonicalIndex < 1 || canonicalIndex > MONTHS.size()) {
            throw new IllegalArgumentException("E_MONTH_INDEX");
        }
        return MONTHS.get(canonicalIndex - 1).sourceText();
    }
}
