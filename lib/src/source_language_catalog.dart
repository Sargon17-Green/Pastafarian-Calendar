final class CanonicalName {
  final int canonicalIndex;
  final String text;

  const CanonicalName(this.canonicalIndex, this.text);
}

final class SourceLanguageCatalog {
  static const String version = '1.0.0';
  static const String naturalLanguage = 'עברית';

  static const List<CanonicalName> cutletNames = <CanonicalName>[
    CanonicalName(1, 'ארד'),
    CanonicalName(2, 'שועל'),
    CanonicalName(3, 'כליה'),
    CanonicalName(4, 'לגש'),
    CanonicalName(5, 'מחשבה'),
    CanonicalName(6, 'ארבעה חלקים מתשעה'),
    CanonicalName(7, 'פַּלְגּוּרַשׁ'),
    CanonicalName(8, 'גומא'),
    CanonicalName(9, 'אשכול'),
    CanonicalName(10, 'עקרב'),
    CanonicalName(11, 'אפר'),
    CanonicalName(12, 'חיטה'),
    CanonicalName(13, 'נהר'),
    CanonicalName(14, 'צחוק'),
    CanonicalName(15, 'אכד'),
    CanonicalName(16, 'קרן'),
    CanonicalName(17, 'הכד הריק'),
  ];

  static const List<CanonicalName> monthNames = <CanonicalName>[
    CanonicalName(1, 'טין'),
    CanonicalName(2, 'רימון'),
    CanonicalName(3, 'מרפק'),
    CanonicalName(4, 'קנאה'),
    CanonicalName(5, 'ארידו'),
    CanonicalName(6, 'משחת־שיניים'),
    CanonicalName(7, 'שלושה חלקים מחמישה'),
    CanonicalName(8, 'כַּרְשׁוּמַב'),
    CanonicalName(9, 'נמר'),
    CanonicalName(10, 'בדיל'),
    CanonicalName(11, 'ערפל'),
    CanonicalName(12, 'לבונה'),
    CanonicalName(13, 'כישור'),
    CanonicalName(14, 'צלע'),
    CanonicalName(15, 'חרוב'),
    CanonicalName(16, 'אורוק'),
    CanonicalName(17, 'בושה'),
    CanonicalName(18, 'גמל'),
    CanonicalName(19, 'נחושת'),
    CanonicalName(20, 'באר'),
    CanonicalName(21, 'חלמון'),
    CanonicalName(22, 'כוכב'),
    CanonicalName(23, 'דבש'),
    CanonicalName(24, 'טחול'),
    CanonicalName(25, 'אבן־גיר'),
    CanonicalName(26, 'שמחה'),
    CanonicalName(27, 'תאנה'),
    CanonicalName(28, 'נינוה'),
    CanonicalName(29, 'צפרדע'),
    CanonicalName(30, 'זפת'),
    CanonicalName(31, 'נר'),
    CanonicalName(32, 'הדלת הסגורה'),
    CanonicalName(33, 'שומשום'),
    CanonicalName(34, 'עורף'),
    CanonicalName(35, 'כסף'),
    CanonicalName(36, 'שושן'),
    CanonicalName(37, 'סערה'),
    CanonicalName(38, 'חמור'),
    CanonicalName(39, 'קמח'),
    CanonicalName(40, 'חרטה'),
    CanonicalName(41, 'בבל'),
    CanonicalName(42, 'לשון'),
    CanonicalName(43, 'פשתן'),
    CanonicalName(44, 'מלח'),
    CanonicalName(45, 'אגס'),
    CanonicalName(46, 'קשת'),
    CanonicalName(47, 'חול'),
  ];

  static String cutletText(int canonicalIndex) {
    if (canonicalIndex < 1 || canonicalIndex > cutletNames.length) {
      throw RangeError.range(canonicalIndex, 1, cutletNames.length, 'canonicalIndex');
    }
    return cutletNames[canonicalIndex - 1].text;
  }

  static String monthText(int canonicalIndex) {
    if (canonicalIndex < 1 || canonicalIndex > monthNames.length) {
      throw RangeError.range(canonicalIndex, 1, monthNames.length, 'canonicalIndex');
    }
    return monthNames[canonicalIndex - 1].text;
  }
}
