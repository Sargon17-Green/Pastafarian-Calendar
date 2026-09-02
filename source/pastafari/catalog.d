module pastafari.catalog;

import std.exception : enforce;

struct CatalogEntry
{
    int canonicalIndex;
    string text;
}

enum sourceLanguageCatalogVersion = "1.0.0";

enum CatalogEntry[17] cutletCatalog = [
    CatalogEntry(1,  "բրոնզ"),
    CatalogEntry(2,  "աղվես"),
    CatalogEntry(3,  "երիկամ"),
    CatalogEntry(4,  "Լագաշ"),
    CatalogEntry(5,  "միտք"),
    CatalogEntry(6,  "չորս իններորդ"),
    CatalogEntry(7,  "Փալգուրաշ"),
    CatalogEntry(8,  "կնյուն"),
    CatalogEntry(9,  "ողկույզ"),
    CatalogEntry(10, "կարիճ"),
    CatalogEntry(11, "մոխիր"),
    CatalogEntry(12, "ցորեն"),
    CatalogEntry(13, "գետ"),
    CatalogEntry(14, "ծիծաղ"),
    CatalogEntry(15, "Աքքադ"),
    CatalogEntry(16, "եղջյուր"),
    CatalogEntry(17, "դատարկ սափոր")
];

enum CatalogEntry[47] monthCatalog = [
    CatalogEntry(1,  "կավ"),
    CatalogEntry(2,  "նուռ"),
    CatalogEntry(3,  "արմունկ"),
    CatalogEntry(4,  "նախանձ"),
    CatalogEntry(5,  "Էրիդու"),
    CatalogEntry(6,  "ատամի մածուկ"),
    CatalogEntry(7,  "երեք հինգերորդ"),
    CatalogEntry(8,  "Քարշումաբ"),
    CatalogEntry(9,  "ընձառյուծ"),
    CatalogEntry(10, "անագ"),
    CatalogEntry(11, "մառախուղ"),
    CatalogEntry(12, "խունկ"),
    CatalogEntry(13, "իլիկ"),
    CatalogEntry(14, "կող"),
    CatalogEntry(15, "կարոբ"),
    CatalogEntry(16, "Ուրուկ"),
    CatalogEntry(17, "ամոթ"),
    CatalogEntry(18, "ուղտ"),
    CatalogEntry(19, "պղինձ"),
    CatalogEntry(20, "ջրհոր"),
    CatalogEntry(21, "դեղնուց"),
    CatalogEntry(22, "աստղ"),
    CatalogEntry(23, "մեղր"),
    CatalogEntry(24, "փայծաղ"),
    CatalogEntry(25, "կրաքար"),
    CatalogEntry(26, "ուրախություն"),
    CatalogEntry(27, "թուզ"),
    CatalogEntry(28, "Նինվե"),
    CatalogEntry(29, "գորտ"),
    CatalogEntry(30, "ձյութ"),
    CatalogEntry(31, "մոմ"),
    CatalogEntry(32, "փակ դուռ"),
    CatalogEntry(33, "քունջութ"),
    CatalogEntry(34, "ծոծրակ"),
    CatalogEntry(35, "արծաթ"),
    CatalogEntry(36, "շուշան"),
    CatalogEntry(37, "փոթորիկ"),
    CatalogEntry(38, "էշ"),
    CatalogEntry(39, "ալյուր"),
    CatalogEntry(40, "ափսոսանք"),
    CatalogEntry(41, "Բաբելոն"),
    CatalogEntry(42, "լեզու"),
    CatalogEntry(43, "կտավատ"),
    CatalogEntry(44, "աղ"),
    CatalogEntry(45, "տանձ"),
    CatalogEntry(46, "աղեղ"),
    CatalogEntry(47, "ավազ")
];

string cutletNameByIndex(int canonicalIndex)
{
    enforce(canonicalIndex >= 1 && canonicalIndex <= cutletCatalog.length, "E_CUTLET_INDEX");
    return cutletCatalog[canonicalIndex - 1].text;
}

string monthNameByIndex(int canonicalIndex)
{
    enforce(canonicalIndex >= 1 && canonicalIndex <= monthCatalog.length, "E_MONTH_INDEX");
    return monthCatalog[canonicalIndex - 1].text;
}

bool catalogIndicesAreFrozenAndDense()
{
    foreach (i, entry; cutletCatalog)
        if (entry.canonicalIndex != cast(int)i + 1)
            return false;
    foreach (i, entry; monthCatalog)
        if (entry.canonicalIndex != cast(int)i + 1)
            return false;
    return true;
}
