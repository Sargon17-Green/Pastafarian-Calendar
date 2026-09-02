namespace Pastafari.SourceLanguageCatalog {
    struct SourceName {
        CanonicalIndex : Int,
        Text : String,
    }

    function CatalogVersion() : String {
        return "ja-source-catalog-v1";
    }

    function CutletNames() : SourceName[] {
        return [
            SourceName(1, "青銅"),
            SourceName(2, "狐"),
            SourceName(3, "腎臓"),
            SourceName(4, "カラマツ"),
            SourceName(5, "思考"),
            SourceName(6, "九分の四"),
            SourceName(7, "パルグラシュ"),
            SourceName(8, "パピルス"),
            SourceName(9, "房"),
            SourceName(10, "蠍"),
            SourceName(11, "灰"),
            SourceName(12, "小麦"),
            SourceName(13, "川"),
            SourceName(14, "笑い"),
            SourceName(15, "アッカド"),
            SourceName(16, "角"),
            SourceName(17, "空の壺")
        ];
    }

    function MonthNames() : SourceName[] {
        return [
            SourceName(1, "泥"),
            SourceName(2, "ザクロ"),
            SourceName(3, "肘"),
            SourceName(4, "嫉妬"),
            SourceName(5, "エリドゥ"),
            SourceName(6, "歯磨き粉"),
            SourceName(7, "五分の三"),
            SourceName(8, "カルシュマブ"),
            SourceName(9, "ヒョウ"),
            SourceName(10, "錫"),
            SourceName(11, "霧"),
            SourceName(12, "乳香"),
            SourceName(13, "紡錘"),
            SourceName(14, "肋骨"),
            SourceName(15, "イナゴマメ"),
            SourceName(16, "ウルク"),
            SourceName(17, "恥"),
            SourceName(18, "ラクダ"),
            SourceName(19, "銅"),
            SourceName(20, "井戸"),
            SourceName(21, "卵黄"),
            SourceName(22, "星"),
            SourceName(23, "蜂蜜"),
            SourceName(24, "脾臓"),
            SourceName(25, "石灰岩"),
            SourceName(26, "喜び"),
            SourceName(27, "イチジク"),
            SourceName(28, "ニネヴェ"),
            SourceName(29, "蛙"),
            SourceName(30, "瀝青"),
            SourceName(31, "蝋燭"),
            SourceName(32, "閉ざされた扉"),
            SourceName(33, "胡麻"),
            SourceName(34, "うなじ"),
            SourceName(35, "銀"),
            SourceName(36, "百合"),
            SourceName(37, "嵐"),
            SourceName(38, "驢馬"),
            SourceName(39, "小麦粉"),
            SourceName(40, "後悔"),
            SourceName(41, "バビロン"),
            SourceName(42, "舌"),
            SourceName(43, "亜麻"),
            SourceName(44, "塩"),
            SourceName(45, "梨"),
            SourceName(46, "弓"),
            SourceName(47, "砂")
        ];
    }

    function ResolveCutlet(canonicalIndex : Int) : String {
        if canonicalIndex < 1 or canonicalIndex > 17 {
            fail "カツレツ名の canonicalIndex が範囲外です。";
        }
        return CutletNames()[canonicalIndex - 1].Text;
    }

    function ResolveMonth(canonicalIndex : Int) : String {
        if canonicalIndex < 1 or canonicalIndex > 47 {
            fail "月名の canonicalIndex が範囲外です。";
        }
        return MonthNames()[canonicalIndex - 1].Text;
    }
}
