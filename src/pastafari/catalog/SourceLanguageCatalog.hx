package pastafari.catalog;

class CatalogEntry {
    public final canonicalIndex:Int;
    public final text:String;

    public function new(canonicalIndex:Int, text:String) {
        this.canonicalIndex = canonicalIndex;
        this.text = text;
    }
}

class SourceLanguageCatalog {
    public static final VERSION:String = "1.0.0";
    public static final NATURAL_LANGUAGE:String = "svenska";

    private static final CUTLETS:Array<String> = [
        "brons",
        "räv",
        "njure",
        "Lagash",
        "tanke",
        "fyra delar av nio",
        "Palgurash",
        "säv",
        "klase",
        "skorpion",
        "aska",
        "vete",
        "flod",
        "skratt",
        "Akkad",
        "horn",
        "den tomma krukan"
    ];

    private static final MONTHS:Array<String> = [
        "lera",
        "granatäpple",
        "armbåge",
        "avund",
        "Eridu",
        "tandkräm",
        "tre delar av fem",
        "Karshumav",
        "tiger",
        "tenn",
        "dimma",
        "olibanum",
        "slända",
        "revben",
        "johannesbröd",
        "Uruk",
        "skam",
        "kamel",
        "koppar",
        "brunn",
        "äggula",
        "stjärna",
        "honung",
        "mjälte",
        "kalksten",
        "glädje",
        "fikon",
        "Nineve",
        "groda",
        "tjära",
        "ljus",
        "den stängda dörren",
        "sesam",
        "nacke",
        "silver",
        "lilja",
        "storm",
        "åsna",
        "mjöl",
        "ånger",
        "Babylon",
        "tunga",
        "lin",
        "salt",
        "päron",
        "båge",
        "sand"
    ];

    public static function cutletCount():Int {
        return CUTLETS.length;
    }

    public static function monthCount():Int {
        return MONTHS.length;
    }

    public static function cutlet(index:Int):CatalogEntry {
        if (index < 1 || index > CUTLETS.length) throw "Ogiltigt kanoniskt kotlettindex";
        return new CatalogEntry(index, CUTLETS[index - 1]);
    }

    public static function month(index:Int):CatalogEntry {
        if (index < 1 || index > MONTHS.length) throw "Ogiltigt kanoniskt månadsindex";
        return new CatalogEntry(index, MONTHS[index - 1]);
    }

    public static function allCutlets():Array<CatalogEntry> {
        var out = new Array<CatalogEntry>();
        var i = 1;
        while (i <= CUTLETS.length) {
            out.push(cutlet(i));
            i++;
        }
        return out;
    }

    public static function allMonths():Array<CatalogEntry> {
        var out = new Array<CatalogEntry>();
        var i = 1;
        while (i <= MONTHS.length) {
            out.push(month(i));
            i++;
        }
        return out;
    }
}
